import { Request, Response } from "express";
import { OrderStatus, PaymentStatus } from "@prisma/client";
import { prisma } from "../config/db";
import {
  PaymentProviderName,
  getPaymentCallbackSecret,
  verifyHmacSignature,
} from "../providers/payment/IPaymentProvider";
import { PaymentRoutingService } from "../services/PaymentRoutingService";
import { realtimeEventService } from "../services/RealtimeEventService";
import { notificationService } from "../services/NotificationService";

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function readParam(
  body: Record<string, unknown>,
  query: Record<string, unknown>,
  keys: readonly string[]
): string {
  for (const key of keys) {
    const bVal = body[key];
    if (typeof bVal === "string" && bVal.trim().length > 0) {
      return bVal.trim();
    }
    if (typeof bVal === "number" && Number.isFinite(bVal)) {
      return String(bVal);
    }
    const qVal = query[key];
    if (typeof qVal === "string" && qVal.trim().length > 0) {
      return qVal.trim();
    }
    if (typeof qVal === "number" && Number.isFinite(qVal)) {
      return String(qVal);
    }
  }
  return "";
}

function normalizeCallbackStatus(
  rawStatus: string,
  rawSuccess: string
): "SUCCESS" | "FAILED" | null {
  const statusUpper = rawStatus.trim().toUpperCase();
  if (statusUpper === "SUCCESS" || statusUpper === "APPROVED" || statusUpper === "OK") {
    return "SUCCESS";
  }
  if (
    statusUpper === "FAILED" ||
    statusUpper === "CANCELLED" ||
    statusUpper === "CANCEL" ||
    statusUpper === "ERROR"
  ) {
    return "FAILED";
  }

  const successLower = rawSuccess.trim().toLowerCase();
  if (successLower === "true") {
    return "SUCCESS";
  }
  if (successLower === "false") {
    return "FAILED";
  }

  return null;
}

function isPaymentProviderName(value: string): value is PaymentProviderName {
  return value === "CARDPLUS" || value === "PAYTR" || value === "STRIPE";
}

function wantsJsonResponse(req: Request): boolean {
  const accept = (req.headers.accept || "").toLowerCase();
  return accept.includes("application/json") && !accept.includes("text/html");
}

function toStringRecord(source: Record<string, unknown>): Record<string, string> {
  const result: Record<string, string> = {};
  for (const [key, val] of Object.entries(source)) {
    if (typeof val === "string") {
      result[key] = val;
    } else if (typeof val === "number" || typeof val === "boolean") {
      result[key] = String(val);
    }
  }
  return result;
}

function renderHtmlError(res: Response, statusCode: number, title: string, message: string): void {
  res.status(statusCode).setHeader("Content-Type", "text/html; charset=utf-8").send(`<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${escapeHtml(title)}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f8fafc; color: #0f172a; margin: 0; padding: 24px; display: flex; align-items: center; justify-content: center; min-height: 100vh; box-sizing: border-box; }
    .card { background: #ffffff; border: 1px solid #e2e8f0; border-radius: 16px; padding: 28px; max-width: 420px; width: 100%; text-align: center; box-shadow: 0 10px 25px rgba(15, 23, 42, 0.08); }
    h1 { font-size: 20px; margin: 0 0 12px; color: #dc2626; }
    p { font-size: 14px; color: #475569; margin: 0; line-height: 1.5; }
  </style>
</head>
<body>
  <div class="card">
    <h1>${escapeHtml(title)}</h1>
    <p>${escapeHtml(message)}</p>
  </div>
</body>
</html>`);
}

export class PaymentController {
  /**
   * GET /api/payments/sandbox-3ds
   * Sandbox 3D Secure doğrulama sayfasını XSS-güvenli HTML olarak döner.
   */
  public async renderSandbox3dsPage(req: Request, res: Response): Promise<void> {
    try {
      const query = req.query as Record<string, unknown>;
      const txId = readParam({}, query, ["txId"]);
      const orderId = readParam({}, query, ["orderId"]);
      const provider = readParam({}, query, ["provider"]) || "STRIPE";
      const amountRaw = readParam({}, query, ["amount"]);
      const currency = readParam({}, query, ["currency"]) || "TRY";
      const sig = readParam({}, query, ["sig"]);

      if (!txId || !orderId || !amountRaw || !currency || !sig) {
        renderHtmlError(
          res,
          400,
          "Geçersiz 3D Secure İsteği",
          "Ödeme doğrulama parametreleri eksik. Lütfen ödeme işlemini yeniden başlatın."
        );
        return;
      }

      const parsedAmount = Number(amountRaw);
      if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
        renderHtmlError(
          res,
          400,
          "Geçersiz Tutar",
          "Ödeme tutarı doğrulanamadı."
        );
        return;
      }

      const formattedAmount = parsedAmount.toFixed(2);
      const signingData = `${txId}:${orderId}:${formattedAmount}:${currency}`;
      const isValidSig = verifyHmacSignature(
        getPaymentCallbackSecret(),
        signingData,
        sig
      );

      if (!isValidSig) {
        renderHtmlError(
          res,
          403,
          "Güvenlik Doğrulaması Başarısız",
          "3D Secure oturum imzası doğrulanamadı."
        );
        return;
      }

      const safeProvider = escapeHtml(provider);
      const safeTxId = escapeHtml(txId);
      const safeOrderId = escapeHtml(orderId);
      const safeAmount = escapeHtml(formattedAmount);
      const safeCurrency = escapeHtml(currency);
      const safeSig = escapeHtml(sig);

      res
        .status(200)
        .setHeader("Content-Type", "text/html; charset=utf-8")
        .send(`<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Hoppa 3D Secure Doğrulama</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f1f5f9; color: #0f172a; margin: 0; padding: 20px; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
    .card { background: #ffffff; border: 1px solid #e2e8f0; border-radius: 18px; padding: 24px; max-width: 420px; width: 100%; box-shadow: 0 12px 32px rgba(15, 23, 42, 0.08); }
    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; padding-bottom: 14px; border-bottom: 1px solid #f1f5f9; }
    .brand { font-size: 18px; font-weight: 700; color: #0f172a; }
    .badge { font-size: 11px; font-weight: 700; letter-spacing: 0.04em; background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; padding: 4px 10px; border-radius: 999px; }
    .summary { background: #f8fafc; border-radius: 12px; padding: 14px; margin-bottom: 18px; }
    .row { display: flex; justify-content: space-between; align-items: center; font-size: 13px; margin-bottom: 6px; color: #475569; }
    .row:last-child { margin-bottom: 0; }
    .amount { font-size: 22px; font-weight: 700; color: #0f172a; font-variant-numeric: tabular-nums; }
    .mono { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 12px; color: #334155; word-break: break-all; }
    label { display: block; font-size: 13px; font-weight: 600; color: #334155; margin-bottom: 8px; }
    input[type="text"] { width: 100%; padding: 12px 14px; border: 1.5px solid #cbd5e1; border-radius: 10px; font-size: 18px; text-align: center; letter-spacing: 6px; font-weight: 600; margin-bottom: 18px; outline: none; }
    input[type="text"]:focus { border-color: #00A651; }
    .actions { display: flex; flex-direction: column; gap: 10px; }
    button { width: 100%; border: none; border-radius: 10px; padding: 13px 16px; font-size: 15px; font-weight: 600; cursor: pointer; }
    .btn-approve { background: #00A651; color: #ffffff; }
    .btn-cancel { background: #f1f5f9; color: #dc2626; border: 1px solid #fecaca; }
    .hint { font-size: 12px; color: #64748b; text-align: center; margin-top: 14px; line-height: 1.4; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <span class="brand">3D Secure Doğrulama</span>
      <span class="badge">${safeProvider} SANDBOX</span>
    </div>

    <div class="summary">
      <div class="row">
        <span>Ödenecek Tutar</span>
        <span class="amount">${safeAmount} ${safeCurrency}</span>
      </div>
      <div class="row">
        <span>Sağlayıcı</span>
        <strong>${safeProvider}</strong>
      </div>
      <div class="row">
        <span>İşlem No</span>
        <span class="mono">${safeTxId}</span>
      </div>
      <div class="row">
        <span>Sipariş No</span>
        <span class="mono">${safeOrderId}</span>
      </div>
    </div>

    <form method="POST" action="/api/payments/3d-callback">
      <input type="hidden" name="txId" value="${safeTxId}" />
      <input type="hidden" name="orderId" value="${safeOrderId}" />
      <input type="hidden" name="amount" value="${safeAmount}" />
      <input type="hidden" name="currency" value="${safeCurrency}" />
      <input type="hidden" name="sig" value="${safeSig}" />
      <input type="hidden" name="provider" value="${safeProvider}" />

      <label for="otpCode">Banka SMS Doğrulama Şifresi</label>
      <input id="otpCode" type="text" name="otpCode" value="123456" inputmode="numeric" maxlength="6" autocomplete="one-time-code" />

      <div class="actions">
        <button type="submit" name="status" value="SUCCESS" class="btn-approve">Şifreyi Onayla</button>
        <button type="submit" name="status" value="FAILED" class="btn-cancel">İptal Et</button>
      </div>
    </form>

    <p class="hint">Test ortamı (SANDBOX) 3D Secure simülasyonudur. Onayladığınızda ödeme atomik olarak doğrulanır.</p>
  </div>
</body>
</html>`);
    } catch (error) {
      console.error("[PaymentController.renderSandbox3dsPage] Error:", error);
      renderHtmlError(
        res,
        500,
        "3D Secure Hatası",
        "Doğrulama sayfası yüklenirken beklenmeyen bir hata oluştu."
      );
    }
  }

  /**
   * POST /api/payments/3d-callback & GET /api/payments/3d-callback
   * HMAC imzasını sabit zamanda doğrular, idempotent Prisma $transaction ile
   * PaymentTransaction & Order durumunu günceller, SSE ve push bildirimlerini tetikler.
   */
  public async handleThreeDCallback(req: Request, res: Response): Promise<void> {
    const jsonMode = wantsJsonResponse(req);

    try {
      const body =
        req.body && typeof req.body === "object"
          ? (req.body as Record<string, unknown>)
          : {};
      const query = req.query as Record<string, unknown>;

      const txId = readParam(body, query, ["txId", "txid", "merchant_oid"]);
      const orderId = readParam(body, query, ["orderId", "order_id"]);
      const rawStatus = readParam(body, query, ["status"]);
      const rawSuccess = readParam(body, query, ["success"]);
      const headerSig =
        typeof req.headers["x-payment-signature"] === "string"
          ? req.headers["x-payment-signature"].trim()
          : "";
      const signature =
        readParam(body, query, ["sig", "signature", "hash", "HASH"]) || headerSig;
      const amountRaw = readParam(body, query, ["amount"]);
      const normalizedStatus = normalizeCallbackStatus(rawStatus, rawSuccess);

      if (!txId || !normalizedStatus) {
        if (jsonMode) {
          res.status(400).json({
            error: true,
            message: "Geçersiz 3D callback parametreleri (txId veya status eksik).",
          });
        } else {
          renderHtmlError(
            res,
            400,
            "Geçersiz Callback",
            "Ödeme sonucu doğrulanamadı: işlem numarası veya durum bilgisi eksik."
          );
        }
        return;
      }

      const txRecord = await prisma.paymentTransaction.findFirst({
        where: { providerTxId: txId },
        include: {
          order: {
            include: {
              shop: true,
            },
          },
        },
      });

      if (!txRecord) {
        if (jsonMode) {
          res.status(404).json({
            error: true,
            message: "Ödeme işlemi bulunamadı.",
          });
        } else {
          renderHtmlError(
            res,
            404,
            "İşlem Bulunamadı",
            "Belirtilen işlem numarasına ait ödeme kaydı bulunamadı."
          );
        }
        return;
      }

      if (orderId && orderId !== txRecord.orderId) {
        if (jsonMode) {
          res.status(403).json({
            error: true,
            message: "Sipariş numarası ödeme kaydı ile eşleşmiyor.",
          });
        } else {
          renderHtmlError(
            res,
            403,
            "Doğrulama Hatası",
            "Sipariş numarası ödeme kaydı ile uyuşmuyor."
          );
        }
        return;
      }

      if (amountRaw) {
        const parsedAmount = Number(amountRaw);
        if (
          !Number.isFinite(parsedAmount) ||
          parsedAmount.toFixed(2) !== Number(txRecord.amount).toFixed(2)
        ) {
          if (jsonMode) {
            res.status(403).json({
              error: true,
              message: "Ödeme tutarı uyuşmazlığı tespit edildi.",
            });
          } else {
            renderHtmlError(
              res,
              403,
              "Tutar Uyuşmazlığı",
              "Bildirilen ödeme tutarı işlem kaydıyla eşleşmiyor."
            );
          }
          return;
        }
      }

      const providerNameUpper = txRecord.provider.toUpperCase();
      if (!isPaymentProviderName(providerNameUpper)) {
        if (jsonMode) {
          res.status(400).json({
            error: true,
            message: `Desteklenmeyen ödeme sağlayıcısı: ${txRecord.provider}`,
          });
        } else {
          renderHtmlError(
            res,
            400,
            "Geçersiz Sağlayıcı",
            "Ödeme sağlayıcısı doğrulanamadı."
          );
        }
        return;
      }

      const providerStrategy = PaymentRoutingService.resolveProvider(providerNameUpper);
      const rawPayload = {
        ...toStringRecord(query),
        ...toStringRecord(body),
      };

      const stripeSig = req.headers["stripe-signature"];
      if (typeof stripeSig === "string" && stripeSig.trim().length > 0) {
        rawPayload.stripeSignatureHeader = stripeSig.trim();
      }

      const verification = await providerStrategy.verifyCallback({
        txId,
        orderId: txRecord.orderId,
        status: normalizedStatus,
        signature,
        amount: Number(txRecord.amount),
        currency: txRecord.currency,
        rawPayload,
      });

      if (!verification.valid) {
        console.error(
          `[PaymentController.handleThreeDCallback] Geçersiz imza (${txRecord.provider}, txId=${txId}): ${verification.reason || "Doğrulama başarısız"}`
        );
        if (jsonMode) {
          res.status(403).json({
            error: true,
            message: verification.reason || "Ödeme imzası doğrulanamadı.",
          });
        } else {
          renderHtmlError(
            res,
            403,
            "İmza Doğrulanamadı",
            verification.reason || "Ödeme güvenlik imzası doğrulanamadı."
          );
        }
        return;
      }

      const targetStatus = verification.status;

      const txResult = await prisma.$transaction(async (txClient) => {
        const updateTxResult = await txClient.paymentTransaction.updateMany({
          where: {
            id: txRecord.id,
            status: PaymentStatus.PENDING,
          },
          data: {
            status: targetStatus,
          },
        });

        if (updateTxResult.count === 0) {
          const existingTx = await txClient.paymentTransaction.findUnique({
            where: { id: txRecord.id },
            include: {
              order: {
                include: { shop: true },
              },
            },
          });

          return {
            alreadyProcessed: true,
            finalStatus: existingTx?.status ?? targetStatus,
            order: existingTx?.order ?? txRecord.order,
          };
        }

        const shouldCancelOrder =
          targetStatus === PaymentStatus.FAILED &&
          txRecord.order.status === OrderStatus.PENDING;

        const updatedOrder = await txClient.order.update({
          where: { id: txRecord.orderId },
          data: {
            paymentStatus: targetStatus,
            ...(shouldCancelOrder
              ? {
                  status: OrderStatus.CANCELLED,
                  cancelReason:
                    "3D Secure ödeme doğrulaması başarısız veya iptal edildi.",
                  cancelledAt: new Date(),
                  cancelledBy: "PAYMENT_GATEWAY",
                }
              : {}),
          },
          include: {
            shop: true,
          },
        });

        return {
          alreadyProcessed: false,
          finalStatus: targetStatus,
          order: updatedOrder,
        };
      });

      if (!txResult.alreadyProcessed) {
        try {
          const eventPayload = {
            orderId: txResult.order.id,
            shopId: txResult.order.shopId,
            consumerId: txResult.order.consumerId,
            status: txResult.order.status,
            paymentStatus: txResult.finalStatus,
            providerTxId: txId,
            provider: txRecord.provider,
          };

          const eventType =
            txResult.finalStatus === PaymentStatus.FAILED &&
            txResult.order.status === OrderStatus.CANCELLED
              ? "ORDER_CANCELLED"
              : "ORDER_STATUS_UPDATED";

          realtimeEventService.publishToShop(
            txResult.order.shopId,
            eventType,
            eventPayload
          );
          realtimeEventService.publishToUser(
            txResult.order.consumerId,
            eventType,
            eventPayload
          );
        } catch (sseError) {
          console.error(
            "[PaymentController.handleThreeDCallback] SSE yayın hatası:",
            sseError
          );
        }

        try {
          if (txResult.finalStatus === PaymentStatus.SUCCESS) {
            await notificationService.sendToUser(
              txResult.order.consumerId,
              "Ödemeniz Onaylandı ✅",
              "3D Secure doğrulamanız tamamlandı ve sipariş ödemeniz onaylandı.",
              {
                orderId: txResult.order.id,
                paymentStatus: "SUCCESS",
              }
            );
          } else {
            await notificationService.sendToUser(
              txResult.order.consumerId,
              "Ödeme Başarısız ❌",
              "3D Secure doğrulaması tamamlanamadığı için ödemeniz gerçekleştirilemedi.",
              {
                orderId: txResult.order.id,
                paymentStatus: "FAILED",
              }
            );
          }
        } catch (notifyError) {
          console.error(
            "[PaymentController.handleThreeDCallback] Push bildirim hatası:",
            notifyError
          );
        }
      }

      const resultParam =
        txResult.finalStatus === PaymentStatus.SUCCESS ? "success" : "failed";

      if (jsonMode) {
        res.status(200).json({
          error: false,
          data: {
            orderId: txResult.order.id,
            providerTxId: txId,
            paymentStatus: txResult.finalStatus,
            orderStatus: txResult.order.status,
            result: resultParam,
            alreadyProcessed: txResult.alreadyProcessed,
          },
        });
        return;
      }

      res.redirect(
        303,
        `/api/payments/3d-complete?result=${resultParam}&orderId=${encodeURIComponent(txResult.order.id)}&txId=${encodeURIComponent(txId)}`
      );
    } catch (error) {
      console.error("[PaymentController.handleThreeDCallback] Error:", error);
      const message =
        error instanceof Error
          ? error.message
          : "Ödeme doğrulama işlemi tamamlanamadı.";
      if (jsonMode) {
        res.status(500).json({ error: true, message });
      } else {
        renderHtmlError(res, 500, "Ödeme İşlem Hatası", message);
      }
    }
  }

  /**
   * GET /api/payments/3d-complete
   * 3D Secure sonucu için temiz HTML sonuç sayfası döner.
   */
  public async renderThreeDCompletePage(req: Request, res: Response): Promise<void> {
    const query = req.query as Record<string, unknown>;
    const rawResult = readParam({}, query, ["result"]).toLowerCase();
    const isSuccess = rawResult === "success";
    const orderId = readParam({}, query, ["orderId"]);
    const txId = readParam({}, query, ["txId"]);

    const title = isSuccess ? "Ödeme Başarılı" : "Ödeme Tamamlanamadı";
    const heading = isSuccess
      ? "Ödemeniz Başarıyla Onaylandı"
      : "Ödeme İptal Edildi veya Başarısız";
    const description = isSuccess
      ? "3D Secure doğrulamanız tamamlandı. Uygulamaya yönlendiriliyorsunuz..."
      : "Ödeme doğrulaması tamamlanamadı. Uygulamaya dönüp tekrar deneyebilirsiniz.";
    const accent = isSuccess ? "#00A651" : "#dc2626";
    const badgeBg = isSuccess ? "#ecfdf5" : "#fef2f2";
    const icon = isSuccess ? "✓" : "✕";

    res
      .status(200)
      .setHeader("Content-Type", "text/html; charset=utf-8")
      .send(`<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${escapeHtml(title)}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f8fafc; color: #0f172a; margin: 0; padding: 24px; min-height: 100vh; display: flex; align-items: center; justify-content: center; box-sizing: border-box; }
    .card { background: #ffffff; border: 1px solid #e2e8f0; border-radius: 18px; padding: 28px; max-width: 400px; width: 100%; text-align: center; box-shadow: 0 12px 32px rgba(15, 23, 42, 0.08); }
    .icon { width: 56px; height: 56px; border-radius: 50%; margin: 0 auto 16px; display: flex; align-items: center; justify-content: center; font-size: 26px; font-weight: 700; color: ${accent}; background: ${badgeBg}; }
    h1 { font-size: 20px; margin: 0 0 10px; color: #0f172a; }
    p { font-size: 14px; color: #475569; margin: 0 0 16px; line-height: 1.5; }
    .meta { font-size: 12px; color: #64748b; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; word-break: break-all; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${icon}</div>
    <h1>${escapeHtml(heading)}</h1>
    <p>${escapeHtml(description)}</p>
    ${orderId ? `<div class="meta">Sipariş: ${escapeHtml(orderId)}</div>` : ""}
    ${txId ? `<div class="meta">İşlem: ${escapeHtml(txId)}</div>` : ""}
  </div>
</body>
</html>`);
  }
}

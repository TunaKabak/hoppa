import crypto from "crypto";
import { PaymentStatus } from "@prisma/client";
import {
  IPaymentProvider,
  PaymentCallbackPayload,
  PaymentCallbackVerificationResult,
  PaymentInitiationInput,
  PaymentInitiationResult,
  PaymentMode,
  PaymentProviderName,
  computePaymentHmac,
  requireEnvVars,
  verifyHmacSignature,
} from "./IPaymentProvider";

interface CardPlusConfig {
  merchantId: string;
  storeKey: string;
  apiUrl: string;
}

interface CardPlusGatewayResponse {
  status?: string;
  paymentUrl?: string;
  redirectUrl?: string;
  threeDSUrl?: string;
  errorMessage?: string;
}

const REQUEST_TIMEOUT_MS = 15_000;

export class CardPlusPaymentProvider implements IPaymentProvider {
  public readonly providerName: PaymentProviderName = "CARDPLUS";
  public readonly mode: PaymentMode = "LIVE";

  private readonly config: CardPlusConfig;

  constructor() {
    this.config = this.loadAndValidateConfig();
  }

  private loadAndValidateConfig(): CardPlusConfig {
    const env = requireEnvVars("CardPlusPaymentProvider", [
      "CARDPLUS_MERCHANT_ID",
      "CARDPLUS_STORE_KEY",
      "CARDPLUS_API_URL",
    ] as const);

    return {
      merchantId: env.CARDPLUS_MERCHANT_ID,
      storeKey: env.CARDPLUS_STORE_KEY,
      apiUrl: env.CARDPLUS_API_URL.replace(/\/+$/, ""),
    };
  }

  public async initiatePayment(
    input: PaymentInitiationInput
  ): Promise<PaymentInitiationResult> {
    const { merchantId, storeKey, apiUrl } = this.loadAndValidateConfig();
    const txId = `txn_cp_${crypto.randomBytes(8).toString("hex")}`;
    const formattedAmount = Number(input.amount).toFixed(2);
    const cleanBaseUrl = input.baseUrl.replace(/\/+$/, "");
    const callbackUrl = `${cleanBaseUrl}/api/payments/3d-callback`;

    const signaturePayload = `${merchantId}:${txId}:${input.orderId}:${formattedAmount}:${input.currency}:${callbackUrl}`;
    const requestHash = computePaymentHmac(storeKey, signaturePayload);

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

    try {
      const response = await fetch(apiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CardPlus-Merchant-Id": merchantId,
          "X-CardPlus-Signature": requestHash,
        },
        body: JSON.stringify({
          merchantId,
          txId,
          orderId: input.orderId,
          amount: formattedAmount,
          currency: input.currency,
          okUrl: callbackUrl,
          failUrl: callbackUrl,
          storeType: "3d_pay_hosting",
          hash: requestHash,
          ...(input.cardDetails.cardToken ? { cardToken: input.cardDetails.cardToken } : {}),
          ...(input.cardDetails.cardHolderName ? { cardHolderName: input.cardDetails.cardHolderName } : {}),
          ...(input.cardDetails.cardBin ? { cardBin: input.cardDetails.cardBin } : {}),
          ...(input.cardDetails.cardLast4 ? { cardLast4: input.cardDetails.cardLast4 } : {}),
        }),
        signal: controller.signal,
      });

      if (!response.ok) {
        const errBody = await response.text().catch(() => "");
        throw new Error(
          `[CardPlusPaymentProvider] 3DS başlatma başarısız (HTTP ${response.status}): ${errBody || response.statusText}`
        );
      }

      const contentType = response.headers.get("content-type") || "";
      let resolvedUrl = "";

      if (contentType.includes("application/json")) {
        const data = (await response.json()) as CardPlusGatewayResponse;
        resolvedUrl = data.paymentUrl || data.redirectUrl || data.threeDSUrl || "";
        if (!resolvedUrl) {
          throw new Error(
            `[CardPlusPaymentProvider] CardPlus yanıtında 3DS yönlendirme URL'si bulunamadı: ${data.errorMessage || "Bilinmeyen hata"}`
          );
        }
      } else if (response.redirected && response.url) {
        resolvedUrl = response.url;
      } else {
        throw new Error(
          "[CardPlusPaymentProvider] CardPlus sunucusundan geçerli bir 3DS yönlendirme URL'si alınamadı."
        );
      }

      return {
        status: PaymentStatus.PENDING,
        providerTxId: txId,
        provider: this.providerName,
        routingType: input.routingType,
        amount: Number(formattedAmount),
        currency: input.currency,
        exchangeRate: input.exchangeRate,
        paymentUrl: resolvedUrl,
        mode: this.mode,
      };
    } catch (error) {
      console.error("[CardPlusPaymentProvider.initiatePayment] Error:", error);
      throw error instanceof Error
        ? error
        : new Error("[CardPlusPaymentProvider] Ödeme başlatılamadı.");
    } finally {
      clearTimeout(timeoutId);
    }
  }

  public async verifyCallback(
    payload: PaymentCallbackPayload
  ): Promise<PaymentCallbackVerificationResult> {
    const { storeKey } = this.config;
    const signature =
      payload.signature ||
      payload.rawPayload?.hash ||
      payload.rawPayload?.HASH ||
      "";

    if (!payload.txId || !signature || payload.amount === undefined || !payload.currency) {
      return {
        valid: false,
        status: PaymentStatus.FAILED,
        txId: payload.txId,
        orderId: payload.orderId,
        reason: "CardPlus callback parametreleri veya HMAC imzası eksik.",
      };
    }

    const formattedAmount = Number(payload.amount).toFixed(2);
    const signingData = `${payload.txId}:${payload.orderId || ""}:${formattedAmount}:${payload.currency}:${payload.status}`;
    const valid = verifyHmacSignature(storeKey, signingData, signature);

    if (!valid) {
      return {
        valid: false,
        status: PaymentStatus.FAILED,
        txId: payload.txId,
        orderId: payload.orderId,
        reason: "CardPlus callback HMAC doğrulaması başarısız.",
      };
    }

    const mdStatus = payload.rawPayload?.mdStatus;
    const procReturnCode = payload.rawPayload?.ProcReturnCode;
    const bankApproved =
      (!mdStatus || ["1", "2", "3", "4"].includes(mdStatus)) &&
      (!procReturnCode || procReturnCode === "00");

    const isSuccess = payload.status === "SUCCESS" && bankApproved;

    return {
      valid: true,
      status: isSuccess ? PaymentStatus.SUCCESS : PaymentStatus.FAILED,
      txId: payload.txId,
      orderId: payload.orderId,
      reason: isSuccess ? undefined : "CardPlus 3DS banka onayı reddedildi.",
    };
  }
}

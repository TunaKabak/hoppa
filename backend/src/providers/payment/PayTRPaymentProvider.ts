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

interface PayTRConfig {
  merchantId: string;
  merchantKey: string;
  merchantSalt: string;
  apiUrl: string;
}

interface PayTRTokenResponse {
  status?: string;
  token?: string;
  reason?: string;
}

const DEFAULT_PAYTR_API_URL = "https://www.paytr.com/odeme/api/get-token";
const REQUEST_TIMEOUT_MS = 15_000;

export class PayTRPaymentProvider implements IPaymentProvider {
  public readonly providerName: PaymentProviderName = "PAYTR";
  public readonly mode: PaymentMode = "LIVE";

  private readonly config: PayTRConfig;

  constructor() {
    this.config = this.loadAndValidateConfig();
  }

  private loadAndValidateConfig(): PayTRConfig {
    const env = requireEnvVars("PayTRPaymentProvider", [
      "PAYTR_MERCHANT_ID",
      "PAYTR_MERCHANT_KEY",
      "PAYTR_MERCHANT_SALT",
    ] as const);

    const apiUrl = (process.env.PAYTR_API_URL || DEFAULT_PAYTR_API_URL)
      .replace(/^["']|["']$/g, "")
      .trim();

    return {
      merchantId: env.PAYTR_MERCHANT_ID,
      merchantKey: env.PAYTR_MERCHANT_KEY,
      merchantSalt: env.PAYTR_MERCHANT_SALT,
      apiUrl,
    };
  }

  public async initiatePayment(
    input: PaymentInitiationInput
  ): Promise<PaymentInitiationResult> {
    const { merchantId, merchantKey, merchantSalt, apiUrl } =
      this.loadAndValidateConfig();
    const txId = `txn_ptr_${crypto.randomBytes(8).toString("hex")}`;
    const formattedAmount = Number(input.amount).toFixed(2);
    const paymentAmountKurus = String(Math.round(Number(formattedAmount) * 100));
    const userIp = input.customerIp || "127.0.0.1";
    const email = input.customerEmail || "customer@hoppanow.com";
    const cleanBaseUrl = input.baseUrl.replace(/\/+$/, "");

    // Do NOT pre-sign or pass status=SUCCESS on merchant_ok_url.
    // Final authorization relies strictly on PayTR's server-to-server webhook POST (/api/payments/3d-callback).
    const okUrl = `${cleanBaseUrl}/api/payments/paytr/pending?txId=${encodeURIComponent(txId)}&orderId=${encodeURIComponent(input.orderId)}`;
    const failUrl = `${cleanBaseUrl}/api/payments/3d-complete?result=failed&orderId=${encodeURIComponent(input.orderId)}&txId=${encodeURIComponent(txId)}`;

    const userBasket = Buffer.from(
      JSON.stringify([[`Hoppa Sipariş #${input.orderId}`, formattedAmount, 1]]),
      "utf8"
    ).toString("base64");

    const noInstallment = "0";
    const maxInstallment = "0";
    const currencyCode = input.currency === "TRY" ? "TL" : input.currency;
    const testMode = "0";

    const hashStr = `${merchantId}${userIp}${txId}${email}${paymentAmountKurus}${userBasket}${noInstallment}${maxInstallment}${currencyCode}${testMode}`;
    const paytrToken = computePaymentHmac(
      merchantKey,
      `${hashStr}${merchantSalt}`,
      "base64"
    );

    const bodyParams = new URLSearchParams({
      merchant_id: merchantId,
      user_ip: userIp,
      merchant_oid: txId,
      email,
      payment_amount: paymentAmountKurus,
      paytr_token: paytrToken,
      user_basket: userBasket,
      debug_on: "0",
      no_installment: noInstallment,
      max_installment: maxInstallment,
      user_name: input.cardDetails.cardHolderName || "Hoppa Müşterisi",
      user_address: "KKTC / Türkiye",
      user_phone: "05000000000",
      merchant_ok_url: okUrl,
      merchant_fail_url: failUrl,
      timeout_limit: "30",
      currency: currencyCode,
      test_mode: testMode,
    });

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

    try {
      const response = await fetch(apiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: bodyParams.toString(),
        signal: controller.signal,
      });

      if (!response.ok) {
        const errBody = await response.text().catch(() => "");
        throw new Error(
          `[PayTRPaymentProvider] Token isteği başarısız (HTTP ${response.status}): ${errBody || response.statusText}`
        );
      }

      const data = (await response.json()) as PayTRTokenResponse;
      if (data.status !== "success" || !data.token) {
        throw new Error(
          `[PayTRPaymentProvider] PayTR token üretilemedi: ${data.reason || "Bilinmeyen hata"}`
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
        paymentUrl: `https://www.paytr.com/odeme/guvenli/${encodeURIComponent(data.token)}`,
        mode: this.mode,
      };
    } catch (error) {
      console.error("[PayTRPaymentProvider.initiatePayment] Error:", error);
      throw error instanceof Error
        ? error
        : new Error("[PayTRPaymentProvider] Ödeme başlatılamadı.");
    } finally {
      clearTimeout(timeoutId);
    }
  }

  public async verifyCallback(
    payload: PaymentCallbackPayload
  ): Promise<PaymentCallbackVerificationResult> {
    const { merchantKey, merchantSalt } = this.config;

    // Strictly accept official PayTR server-to-server webhook POST format
    const rawOid = payload.rawPayload?.merchant_oid;
    const rawStatus = payload.rawPayload?.status;
    const rawTotalAmount = payload.rawPayload?.total_amount;
    const rawHash = payload.rawPayload?.hash;

    if (!rawOid || !rawStatus || !rawTotalAmount || !rawHash) {
      return {
        valid: false,
        status: PaymentStatus.FAILED,
        txId: payload.txId,
        orderId: payload.orderId,
        reason: "PayTR webhook HMAC parametreleri eksik.",
      };
    }

    const webhookData = `${rawOid}${merchantSalt}${rawStatus}${rawTotalAmount}`;
    const isWebhookValid = verifyHmacSignature(
      merchantKey,
      webhookData,
      rawHash,
      "base64"
    );

    if (!isWebhookValid) {
      return {
        valid: false,
        status: PaymentStatus.FAILED,
        txId: payload.txId,
        orderId: payload.orderId,
        reason: "PayTR webhook HMAC imzası geçersiz.",
      };
    }

    return {
      valid: true,
      status:
        rawStatus.toLowerCase() === "success"
          ? PaymentStatus.SUCCESS
          : PaymentStatus.FAILED,
      txId: payload.txId,
      orderId: payload.orderId,
    };
  }
}

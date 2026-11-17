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

interface StripeConfig {
  secretKey: string;
  webhookSecret: string;
  apiUrl: string;
}

interface StripeSessionResponse {
  id?: string;
  url?: string;
  error?: {
    message?: string;
  };
}

const DEFAULT_STRIPE_API_URL = "https://api.stripe.com/v1";
const REQUEST_TIMEOUT_MS = 15_000;

export class StripePaymentProvider implements IPaymentProvider {
  public readonly providerName: PaymentProviderName = "STRIPE";
  public readonly mode: PaymentMode = "LIVE";

  private readonly config: StripeConfig;

  constructor() {
    this.config = this.loadAndValidateConfig();
  }

  private loadAndValidateConfig(): StripeConfig {
    const env = requireEnvVars("StripePaymentProvider", [
      "STRIPE_SECRET_KEY",
      "STRIPE_WEBHOOK_SECRET",
    ] as const);

    const apiUrl = (process.env.STRIPE_API_URL || DEFAULT_STRIPE_API_URL)
      .replace(/^["']|["']$/g, "")
      .trim()
      .replace(/\/+$/, "");

    return {
      secretKey: env.STRIPE_SECRET_KEY,
      webhookSecret: env.STRIPE_WEBHOOK_SECRET,
      apiUrl,
    };
  }

  public async initiatePayment(
    input: PaymentInitiationInput
  ): Promise<PaymentInitiationResult> {
    const { secretKey, apiUrl } = this.loadAndValidateConfig();
    const txId = `txn_str_${crypto.randomBytes(8).toString("hex")}`;
    const formattedAmount = Number(input.amount).toFixed(2);
    const unitAmountMinor = String(Math.round(Number(formattedAmount) * 100));
    const cleanBaseUrl = input.baseUrl.replace(/\/+$/, "");

    // Do NOT pre-sign or embed status=SUCCESS on browser redirect URLs.
    // Final authorization relies strictly on signed Stripe webhooks or server-side Checkout Session lookup.
    const successUrl = `${cleanBaseUrl}/api/payments/stripe/return?session_id={CHECKOUT_SESSION_ID}&txId=${encodeURIComponent(txId)}&orderId=${encodeURIComponent(input.orderId)}`;
    const cancelUrl = `${cleanBaseUrl}/api/payments/stripe/return?canceled=1&txId=${encodeURIComponent(txId)}&orderId=${encodeURIComponent(input.orderId)}`;

    const formBody = new URLSearchParams({
      mode: "payment",
      "payment_method_types[0]": "card",
      "payment_method_options[card][request_three_d_secure]": "any",
      "line_items[0][price_data][currency]": input.currency.toLowerCase(),
      "line_items[0][price_data][unit_amount]": unitAmountMinor,
      "line_items[0][price_data][product_data][name]": `Hoppa Order #${input.orderId}`,
      "line_items[0][quantity]": "1",
      client_reference_id: input.orderId,
      "metadata[txId]": txId,
      "metadata[orderId]": input.orderId,
      success_url: successUrl,
      cancel_url: cancelUrl,
    });

    if (input.customerEmail) {
      formBody.set("customer_email", input.customerEmail);
    }

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

    try {
      const response = await fetch(`${apiUrl}/checkout/sessions`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${secretKey}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: formBody.toString(),
        signal: controller.signal,
      });

      const data = (await response.json()) as StripeSessionResponse;

      if (!response.ok || !data.url) {
        throw new Error(
          `[StripePaymentProvider] 3DS oturumu oluşturulamadı (HTTP ${response.status}): ${data.error?.message || response.statusText}`
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
        paymentUrl: data.url,
        mode: this.mode,
      };
    } catch (error) {
      console.error("[StripePaymentProvider.initiatePayment] Error:", error);
      throw error instanceof Error
        ? error
        : new Error("[StripePaymentProvider] Ödeme başlatılamadı.");
    } finally {
      clearTimeout(timeoutId);
    }
  }

  public async fetchCheckoutSession(sessionId: string): Promise<{
    id?: string;
    payment_status?: string;
    status?: string;
    metadata?: Record<string, string>;
  }> {
    const { secretKey, apiUrl } = this.config;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
    try {
      const response = await fetch(
        `${apiUrl}/checkout/sessions/${encodeURIComponent(sessionId)}`,
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${secretKey}`,
          },
          signal: controller.signal,
        }
      );
      if (!response.ok) {
        throw new Error(`Stripe oturum sorgusu başarısız (HTTP ${response.status})`);
      }
      return (await response.json()) as {
        id?: string;
        payment_status?: string;
        status?: string;
        metadata?: Record<string, string>;
      };
    } finally {
      clearTimeout(timeoutId);
    }
  }

  public async verifyCallback(
    payload: PaymentCallbackPayload
  ): Promise<PaymentCallbackVerificationResult> {
    const { webhookSecret } = this.config;

    // Strictly enforce official Stripe-Signature webhook verification (`t=...,v1=...`)
    const stripeHeader = payload.rawPayload?.stripeSignatureHeader;
    const rawBody = payload.rawPayload?.rawBody;
    if (!stripeHeader || !rawBody) {
      return {
        valid: false,
        status: PaymentStatus.FAILED,
        txId: payload.txId,
        orderId: payload.orderId,
        reason: "Stripe webhook imzası (Stripe-Signature + rawBody) zorunludur.",
      };
    }

    const parts = stripeHeader.split(",").reduce<Record<string, string>>((acc, part) => {
      const [k, v] = part.split("=");
      if (k && v) {
        acc[k.trim()] = v.trim();
      }
      return acc;
    }, {});

    const timestamp = parts.t;
    const v1 = parts.v1;
    const tsNum = Number(timestamp);
    if (!timestamp || !v1 || !Number.isFinite(tsNum) || Math.abs(Math.floor(Date.now() / 1000) - tsNum) > 300) {
      return {
        valid: false,
        status: PaymentStatus.FAILED,
        txId: payload.txId,
        orderId: payload.orderId,
        reason: "Stripe-Signature zaman damgası geçersiz veya süresi dolmuş.",
      };
    }

    const signedPayload = `${timestamp}.${rawBody}`;
    const isWebhookValid = verifyHmacSignature(webhookSecret, signedPayload, v1);

    if (!isWebhookValid) {
      return {
        valid: false,
        status: PaymentStatus.FAILED,
        txId: payload.txId,
        orderId: payload.orderId,
        reason: "Stripe webhook HMAC imzası doğrulanamadı.",
      };
    }

    return {
      valid: true,
      status:
        payload.status === "SUCCESS"
          ? PaymentStatus.SUCCESS
          : PaymentStatus.FAILED,
      txId: payload.txId,
      orderId: payload.orderId,
    };
  }
}

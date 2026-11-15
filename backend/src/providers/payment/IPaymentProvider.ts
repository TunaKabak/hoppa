import crypto from "crypto";
import { Currency, PaymentStatus } from "@prisma/client";

export type PaymentProviderName = "CARDPLUS" | "PAYTR" | "STRIPE";
export type PaymentMode = "SANDBOX" | "LIVE";

export interface PaymentCardDetails {
  cardNumber: string;
  expiryMonth: string;
  expiryYear: string;
  cvc: string;
  cardHolderName: string;
}

export interface PaymentInitiationInput {
  orderId: string;
  amount: number;
  currency: Currency;
  routingType: string;
  exchangeRate: number;
  cardDetails: PaymentCardDetails;
  baseUrl: string;
  customerEmail?: string;
  customerIp?: string;
}

export interface PaymentInitiationResult {
  status: PaymentStatus;
  providerTxId: string;
  provider: PaymentProviderName;
  routingType: string;
  amount: number;
  currency: Currency;
  exchangeRate: number;
  paymentUrl: string;
  mode: PaymentMode;
}

export interface PaymentCallbackPayload {
  txId: string;
  orderId?: string;
  status: "SUCCESS" | "FAILED";
  signature?: string;
  amount?: number;
  currency?: string;
  rawPayload?: Record<string, string>;
}

export interface PaymentCallbackVerificationResult {
  valid: boolean;
  status: PaymentStatus;
  txId: string;
  orderId?: string;
  reason?: string;
}

export interface IPaymentProvider {
  readonly providerName: PaymentProviderName;
  readonly mode: PaymentMode;
  initiatePayment(input: PaymentInitiationInput): Promise<PaymentInitiationResult>;
  verifyCallback(payload: PaymentCallbackPayload): Promise<PaymentCallbackVerificationResult>;
  refund?(
    providerTxId: string,
    amount: number,
    currency: Currency
  ): Promise<{ success: boolean; refundId?: string; message?: string }>;
}

export function computePaymentHmac(
  secret: string,
  data: string,
  encoding: "hex" | "base64" = "hex"
): string {
  return crypto.createHmac("sha256", secret).update(data, "utf8").digest(encoding);
}

export function verifyHmacSignature(
  secret: string,
  data: string,
  sig: string,
  encoding: "hex" | "base64" = "hex"
): boolean {
  if (!secret || !sig) {
    return false;
  }

  const expected = computePaymentHmac(secret, data, encoding);
  const received = encoding === "hex" ? sig.trim().toLowerCase() : sig.trim();

  const expectedBuf = Buffer.from(expected, "utf8");
  const receivedBuf = Buffer.from(received, "utf8");

  if (expectedBuf.length !== receivedBuf.length) {
    return false;
  }

  return crypto.timingSafeEqual(expectedBuf, receivedBuf);
}

export function getPaymentCallbackSecret(): string {
  const raw =
    process.env.PAYMENT_CALLBACK_SECRET ||
    process.env.JWT_SECRET ||
    "hoppa_dev_payment_secret";
  return raw.replace(/^["']|["']$/g, "").trim() || "hoppa_dev_payment_secret";
}

export function requireEnvVars<K extends string>(
  providerName: string,
  keys: readonly K[]
): Record<K, string> {
  const missing: string[] = [];
  const resolved = {} as Record<K, string>;

  for (const key of keys) {
    const val = (process.env[key] || "").replace(/^["']|["']$/g, "").trim();
    if (!val) {
      missing.push(key);
    } else {
      resolved[key] = val;
    }
  }

  if (missing.length > 0) {
    throw new Error(
      `[${providerName}] LIVE ödeme modu için zorunlu ortam değişkenleri eksik: ${missing.join(", ")}`
    );
  }

  return resolved;
}

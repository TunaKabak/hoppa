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
  getPaymentCallbackSecret,
  verifyHmacSignature,
} from "./IPaymentProvider";

export class Sandbox3DSPaymentProvider implements IPaymentProvider {
  public readonly providerName: PaymentProviderName;
  public readonly mode: PaymentMode = "SANDBOX";

  constructor(providerName: PaymentProviderName = "STRIPE") {
    this.providerName = providerName;
  }

  public async initiatePayment(
    input: PaymentInitiationInput
  ): Promise<PaymentInitiationResult> {
    const txId = `txn_sbx_${crypto.randomBytes(8).toString("hex")}`;
    const formattedAmount = Number(input.amount).toFixed(2);
    const signingData = `${txId}:${input.orderId}:${formattedAmount}:${input.currency}`;
    const signature = computePaymentHmac(getPaymentCallbackSecret(), signingData);

    const cleanBaseUrl = input.baseUrl.replace(/\/+$/, "");
    const params = new URLSearchParams({
      txId,
      orderId: input.orderId,
      provider: this.providerName,
      amount: formattedAmount,
      currency: input.currency,
      sig: signature,
    });

    return {
      status: PaymentStatus.PENDING,
      providerTxId: txId,
      provider: this.providerName,
      routingType: input.routingType,
      amount: Number(formattedAmount),
      currency: input.currency,
      exchangeRate: input.exchangeRate,
      paymentUrl: `${cleanBaseUrl}/api/payments/sandbox-3ds?${params.toString()}`,
      mode: this.mode,
    };
  }

  public async verifyCallback(
    payload: PaymentCallbackPayload
  ): Promise<PaymentCallbackVerificationResult> {
    if (
      !payload.txId ||
      !payload.orderId ||
      payload.amount === undefined ||
      !payload.currency ||
      !payload.signature
    ) {
      return {
        valid: false,
        status: PaymentStatus.FAILED,
        txId: payload.txId,
        orderId: payload.orderId,
        reason: "Eksik sandbox callback parametresi veya HMAC imzası.",
      };
    }

    const formattedAmount = Number(payload.amount).toFixed(2);
    const signingData = `${payload.txId}:${payload.orderId}:${formattedAmount}:${payload.currency}`;
    const isValid = verifyHmacSignature(
      getPaymentCallbackSecret(),
      signingData,
      payload.signature
    );

    if (!isValid) {
      return {
        valid: false,
        status: PaymentStatus.FAILED,
        txId: payload.txId,
        orderId: payload.orderId,
        reason: "Sandbox 3DS HMAC imza doğrulaması başarısız.",
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

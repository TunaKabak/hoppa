import { Currency, PaymentStatus } from "@prisma/client";
import {
  IPaymentProvider,
  PaymentCardDetails,
  PaymentMode,
  PaymentProviderName,
} from "../providers/payment/IPaymentProvider";
import { Sandbox3DSPaymentProvider } from "../providers/payment/Sandbox3DSPaymentProvider";
import { CardPlusPaymentProvider } from "../providers/payment/CardPlusPaymentProvider";
import { PayTRPaymentProvider } from "../providers/payment/PayTRPaymentProvider";
import { StripePaymentProvider } from "../providers/payment/StripePaymentProvider";

export type CardDetails = PaymentCardDetails;

export interface PaymentRequest {
  orderId: string;
  amount: number;
  cardDetails: CardDetails;
  currency?: Currency;
  baseUrl?: string;
  customerEmail?: string;
  customerIp?: string;
}

export interface PaymentResponse {
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

export class PaymentRoutingService {
  // KKTC Yerel Banka BIN Listesi
  private static readonly kktcBins = ["454360", "543771", "402235"];
  // Türkiye Banka BIN Listesi
  private static readonly trBins = ["432042", "516888", "540061"];

  public static getPaymentMode(): PaymentMode {
    const raw = (process.env.PAYMENT_PROVIDER_MODE || "SANDBOX")
      .replace(/^["']|["']$/g, "")
      .trim()
      .toUpperCase();

    if (raw === "LIVE") {
      return "LIVE";
    }
    if (raw === "SANDBOX" || raw === "") {
      return "SANDBOX";
    }

    throw new Error(`Geçersiz PAYMENT_PROVIDER_MODE yapılandırması: ${raw}`);
  }

  public static resolveProvider(providerName: PaymentProviderName): IPaymentProvider {
    const mode = this.getPaymentMode();

    if (mode === "SANDBOX") {
      return new Sandbox3DSPaymentProvider(providerName);
    }

    switch (providerName) {
      case "CARDPLUS":
        return new CardPlusPaymentProvider();
      case "PAYTR":
        return new PayTRPaymentProvider();
      case "STRIPE":
        return new StripePaymentProvider();
      default: {
        const exhaustiveCheck: never = providerName;
        throw new Error(`Desteklenmeyen ödeme sağlayıcısı: ${String(exhaustiveCheck)}`);
      }
    }
  }

  public static async routePayment(request: PaymentRequest): Promise<PaymentResponse> {
    const cardNumber = request.cardDetails.cardNumber.replace(/\s+/g, "");
    const bin = cardNumber.substring(0, 6);

    let provider: PaymentProviderName = "STRIPE";
    let routingType = "INTERNATIONAL";
    let currency = request.currency || Currency.TRY;
    let amount = request.amount;
    let exchangeRate = 1.0;

    if (this.kktcBins.includes(bin)) {
      provider = "CARDPLUS";
      routingType = "DOMESTIC_KKTC";
      currency = Currency.TRY;
    } else if (this.trBins.includes(bin)) {
      provider = "PAYTR";
      routingType = "DOMESTIC_TR";
      currency = Currency.TRY;
    } else {
      // Yabancı kart - DCC (Dynamic Currency Conversion: TRY -> GBP)
      if (currency === Currency.TRY) {
        exchangeRate = 0.025;
        currency = Currency.GBP;
        amount = request.amount * exchangeRate;
      }
    }

    const normalizedAmount = Number(amount.toFixed(2));
    const resolvedBaseUrl = (
      request.baseUrl ||
      process.env.PUBLIC_BASE_URL ||
      `http://localhost:${process.env.PORT || 3000}`
    )
      .replace(/^["']|["']$/g, "")
      .replace(/\/+$/, "");

    const mode = this.getPaymentMode();
    console.log(
      `[PaymentRoutingService] Routing to ${provider} (${routingType}, mode=${mode}). Original: ${request.amount} TRY, Converted: ${normalizedAmount.toFixed(2)} ${currency}`
    );

    const strategy = this.resolveProvider(provider);
    const result = await strategy.initiatePayment({
      orderId: request.orderId,
      amount: normalizedAmount,
      currency,
      routingType,
      exchangeRate,
      cardDetails: request.cardDetails,
      baseUrl: resolvedBaseUrl,
      customerEmail: request.customerEmail,
      customerIp: request.customerIp,
    });

    // 3D Secure doğrulanmadan asla SUCCESS dönülmez; başlangıç durumu daima PENDING'dir.
    return {
      ...result,
      status: PaymentStatus.PENDING,
    };
  }
}

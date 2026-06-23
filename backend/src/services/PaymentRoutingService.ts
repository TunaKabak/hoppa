import { Currency, PaymentStatus } from '@prisma/client';

export interface CardDetails {
    cardNumber: string;
    expiryMonth: string;
    expiryYear: string;
    cvc: string;
    cardHolderName: string;
}

export interface PaymentRequest {
    orderId: string;
    amount: number;
    cardDetails: CardDetails;
    currency?: Currency;
}

export interface PaymentResponse {
    status: PaymentStatus;
    providerTxId: string;
    provider: string;
    routingType: string;
    amount: number;
    currency: Currency;
    exchangeRate: number;
    paymentUrl?: string; // For 3D secure simulation
}

export class PaymentRoutingService {
    // Mock BIN list for KKTC
    private static readonly kktcBins = ['454360', '543771', '402235'];
    // Mock BIN list for TR
    private static readonly trBins = ['432042', '516888', '540061'];

    static async routePayment(request: PaymentRequest): Promise<PaymentResponse> {
        // Strip spaces from card number
        const cardNumber = request.cardDetails.cardNumber.replace(/\s+/g, '');
        const bin = cardNumber.substring(0, 6);
        
        let provider = 'STRIPE'; // Default for foreign cards
        let routingType = 'INTERNATIONAL';
        let currency = request.currency || Currency.TRY;
        let amount = request.amount;
        let exchangeRate = 1.0;

        if (this.kktcBins.includes(bin)) {
            provider = 'CARDPLUS';
            routingType = 'DOMESTIC_KKTC';
            currency = Currency.TRY;
        } else if (this.trBins.includes(bin)) {
            provider = 'PAYTR';
            routingType = 'DOMESTIC_TR';
            currency = Currency.TRY;
        } else {
            // Foreign card - Apply DCC (Dynamic Currency Conversion)
            // Simulating DCC: Converting TRY to GBP
            if (currency === Currency.TRY) {
                exchangeRate = 0.025; // Example rate: 1 TRY = 0.025 GBP
                currency = Currency.GBP;
                amount = request.amount * exchangeRate;
            }
        }

        console.log(`[PaymentRoutingService] Routing to ${provider} (${routingType}). Original Amount: ${request.amount} TRY, Converted Amount: ${amount} ${currency}`);

        // Forward to Mock Payment Service
        return MockPaymentService.processPayment({
            ...request,
            amount,
            currency,
            provider,
            routingType,
            exchangeRate
        });
    }
}

export class MockPaymentService {
    static async processPayment(data: {
        orderId: string;
        amount: number;
        currency: Currency;
        provider: string;
        routingType: string;
        exchangeRate: number;
        cardDetails: CardDetails;
    }): Promise<PaymentResponse> {
        
        console.log(`[MockPaymentService] Processing payment via ${data.provider}. Amount: ${data.amount} ${data.currency}`);
        
        // Simulating processing delay
        await new Promise(resolve => setTimeout(resolve, 500));

        const txId = `txn_mock_${Math.random().toString(36).substring(2, 11)}`;

        // Durumu doğrudan SUCCESS yapacak şekilde simüle et (ama 3D secure için url de dönüyoruz)
        return {
            status: PaymentStatus.SUCCESS,
            providerTxId: txId,
            provider: data.provider,
            routingType: data.routingType,
            amount: data.amount,
            currency: data.currency,
            exchangeRate: data.exchangeRate,
            paymentUrl: `https://hoppa-backend.onrender.com/mock-3d-secure?txId=${txId}`
        };
    }
}

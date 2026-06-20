import { ISmsProvider } from "./ISmsProvider";

export class RealSmsProvider implements ISmsProvider {
  async sendSms(phoneNumber: string, message: string): Promise<boolean> {
    // TODO: Gerçek SMS API entegrasyonu (Twilio, Netgsm vb.) buraya eklenecek
    console.log(`[REAL SMS] Gönderiliyor: ${phoneNumber} -> ${message}`);
    
    // Mock network delay
    await new Promise(resolve => setTimeout(resolve, 500));
    return true;
  }
}

import { ISmsProvider } from "./ISmsProvider";

export class RealSmsProvider implements ISmsProvider {
  async sendOtp(phoneNumber: string, code: string): Promise<boolean> {
    // TODO: Gerçek SMS API entegrasyonu (Twilio, Netgsm vb.) buraya eklenecek
    console.log(`[REAL SMS] Gönderiliyor: ${phoneNumber} -> ${code}`);
    
    // Mock network delay
    await new Promise(resolve => setTimeout(resolve, 500));
    return true;
  }
}

import { ISmsProvider } from "./ISmsProvider";
import twilio from "twilio";

export class TwilioSmsProvider implements ISmsProvider {
  private client: twilio.Twilio;
  private fromNumber: string;

  constructor() {
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    this.fromNumber = process.env.TWILIO_FROM_NUMBER || "";

    if (!accountSid || !authToken) {
      console.warn("[TwilioSmsProvider] UYARI: Twilio credentials eksik. SMS gönderimi mock olarak çalışacaktır.");
    }

    // Use dummy fallbacks to avoid crashes when credentials are not configured in local dev
    this.client = twilio(accountSid || "AC00000000000000000000000000000000", authToken || "fake_auth_token");
  }

  public async sendOtp(phoneNumber: string, code: string): Promise<boolean> {
    try {
      const messageBody = `Hoppa doğrulama kodunuz: ${code}. Bu kodu kimseyle paylaşmayınız.`;
      const formattedPhone = phoneNumber.startsWith("+") ? phoneNumber : `+${phoneNumber}`;

      const response = await this.client.messages.create({
        body: messageBody,
        from: this.fromNumber,
        to: formattedPhone,
      });

      console.log(`[Twilio] SMS başarıyla gönderildi. SID: ${response.sid}`);
      return true;
    } catch (error) {
      console.error("[Twilio] SMS gönderme hatası:", error);
      return false;
    }
  }
}

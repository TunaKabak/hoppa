import { PrismaClient } from "@prisma/client";
import { ISmsProvider } from "../providers/sms/ISmsProvider";
import { MockSmsProvider } from "../providers/sms/MockSmsProvider";
import { RealSmsProvider } from "../providers/sms/RealSmsProvider";

const prisma = new PrismaClient();

export class OtpService {
  private smsProvider: ISmsProvider;

  constructor() {
    // Strategy Pattern: ORTAM değişkenine göre provider seç
    const isMock = process.env.SMS_PROVIDER_MODE !== "REAL";
    this.smsProvider = isMock ? new MockSmsProvider() : new RealSmsProvider();
  }

  /**
   * Yeni bir OTP talebi oluşturur (Whitelist dahil).
   */
  public async requestOtp(phoneNumber: string): Promise<boolean> {
    // 1. Whitelist (Apple/Google Test Hesapları vb.)
    const testNumbers = process.env.TEST_PHONE_NUMBERS?.split(",") || [];
    if (testNumbers.includes(phoneNumber)) {
      console.log(`[OtpService] Whitelist numara algılandı: ${phoneNumber}. SMS atlanıyor.`);
      return true; // Whitelist için SMS atmaya veya DB'ye kaydetmeye gerek yok.
    }

    // 2. Rastgele 6 haneli OTP kodu üretimi
    const rawCode = Math.floor(100000 + Math.random() * 900000).toString();

    // 3. Geçerlilik Süresi (şu anki zamandan 3 dakika sonra)
    const expiresAt = new Date(Date.now() + 3 * 60 * 1000);

    try {
      // 4. Veritabanına kaydet (Varsa güncelle, yoksa oluştur - Upsert)
      await prisma.otpCode.upsert({
        where: { phoneNumber },
        update: {
          code: rawCode,
          expiresAt: expiresAt,
          createdAt: new Date(),
        },
        create: {
          phoneNumber: phoneNumber,
          code: rawCode,
          expiresAt: expiresAt,
        },
      });

      // 5. SMS Gönder
      const message = `Hoppa doğrulama kodunuz: ${rawCode}. Bizi seçtiğiniz için teşekkürler!`;
      await this.smsProvider.sendSms(phoneNumber, message);
      return true;
    } catch (error: any) {
      console.error("[OtpService] OTP istek hatası:", error);
      throw new Error("DB_ERROR: " + error.message);
    }
  }

  /**
   * Kullanıcının girdiği OTP kodunu doğrular.
   */
  public async verifyOtp(phoneNumber: string, code: string): Promise<boolean> {
    // 1. Whitelist kontrolü
    const testNumbers = process.env.TEST_PHONE_NUMBERS?.split(",") || [];
    if (testNumbers.includes(phoneNumber)) {
      const testCode = process.env.TEST_OTP_CODE || "123456";
      return code === testCode;
    }

    // 2. DB Kontrolü
    const otpRecord = await prisma.otpCode.findUnique({
      where: { phoneNumber },
    });

    if (!otpRecord) return false;

    // 3. Süre veya Kod eşleşmeme durumu
    const now = new Date();
    if (otpRecord.code !== code || otpRecord.expiresAt < now) {
      return false; // Geçersiz veya süresi dolmuş
    }

    // 4. Doğrulama başarılı - OTP kaydını DB'den temizle (Aynı kodun tekrar kullanımını engelle)
    await prisma.otpCode.delete({
      where: { id: otpRecord.id },
    });

    return true;
  }
}

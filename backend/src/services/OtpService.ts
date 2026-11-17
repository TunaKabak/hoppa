import crypto from "crypto";
import { prisma } from "../config/db";
import { ISmsProvider } from "../providers/sms/ISmsProvider";
import { SmsProviderFactory } from "../providers/sms/SmsProviderFactory";

const MAX_OTP_ATTEMPTS = 5;

export class OtpService {
  private smsProvider: ISmsProvider;
  private static failedAttempts = new Map<string, number>();

  constructor() {
    this.smsProvider = SmsProviderFactory.getProvider();
  }

  private static getWhitelistNumbers(): string[] {
    const isProd = process.env.NODE_ENV === "production";
    if (isProd && process.env.ALLOW_STORE_REVIEW_TEST_ACCOUNTS !== "true") {
      return [];
    }
    return (process.env.TEST_PHONE_NUMBERS || "")
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
  }

  private static constantTimeEquals(a: string, b: string): boolean {
    const bufA = Buffer.from(a, "utf8");
    const bufB = Buffer.from(b, "utf8");
    if (bufA.length !== bufB.length) {
      return false;
    }
    return crypto.timingSafeEqual(bufA, bufB);
  }

  /**
   * Yeni bir OTP talebi oluşturur (Whitelist dahil).
   */
  public async requestOtp(phoneNumber: string): Promise<boolean> {
    OtpService.failedAttempts.delete(phoneNumber);

    // 1. Whitelist (Store review / test ortamı - prod'da ALLOW_STORE_REVIEW_TEST_ACCOUNTS=true gerekir)
    const testNumbers = OtpService.getWhitelistNumbers();
    if (testNumbers.includes(phoneNumber)) {
      console.log(`[OtpService] Test whitelist numara algılandı: ${phoneNumber}. SMS atlanıyor.`);
      return true;
    }

    // 2. Kriptografik rastgele 6 haneli OTP kodu üretimi (CSPRNG)
    const rawCode = crypto.randomInt(100000, 1000000).toString();

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
      await this.smsProvider.sendOtp(phoneNumber, rawCode);
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
    const testNumbers = OtpService.getWhitelistNumbers();
    if (testNumbers.includes(phoneNumber)) {
      const configuredTestCode = (process.env.TEST_OTP_CODE || "").trim();
      if (process.env.NODE_ENV === "production") {
        if (configuredTestCode.length < 6) {
          return false;
        }
        return OtpService.constantTimeEquals(code, configuredTestCode);
      }
      const devTestCode = configuredTestCode || "123456";
      return OtpService.constantTimeEquals(code, devTestCode);
    }

    // 2. DB Kontrolü
    const otpRecord = await prisma.otpCode.findUnique({
      where: { phoneNumber },
    });

    if (!otpRecord) return false;

    const currentFailures = OtpService.failedAttempts.get(phoneNumber) ?? 0;
    if (currentFailures >= MAX_OTP_ATTEMPTS) {
      await prisma.otpCode.deleteMany({ where: { id: otpRecord.id } });
      return false;
    }

    // 3. Süre veya sabit zamanlı (constant-time) kod doğrulaması
    const now = new Date();
    const isCodeValid = OtpService.constantTimeEquals(otpRecord.code, code);
    if (!isCodeValid || otpRecord.expiresAt < now) {
      const nextFailures = currentFailures + 1;
      OtpService.failedAttempts.set(phoneNumber, nextFailures);
      if (nextFailures >= MAX_OTP_ATTEMPTS || otpRecord.expiresAt < now) {
        await prisma.otpCode.deleteMany({ where: { id: otpRecord.id } });
      }
      return false;
    }

    // 4. Doğrulama başarılı - OTP kaydını DB'den temizle ve hata sayacını sıfırla
    OtpService.failedAttempts.delete(phoneNumber);
    await prisma.otpCode.delete({
      where: { id: otpRecord.id },
    });

    return true;
  }
}

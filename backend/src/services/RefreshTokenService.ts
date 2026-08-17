import crypto from "crypto";
import { prisma } from "../config/db";
import { JwtUtils } from "../utils/JwtUtils";

export interface TokenPairResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number; // saniye cinsinden access token ömrü (900s = 15m)
}

export class RefreshTokenService {
  private static REFRESH_TOKEN_EXPIRY_DAYS = 30;

  /**
   * Token dizesinin SHA-256 özetini üretir (DB'de güvenli saklamak için)
   */
  private static hashToken(token: string): string {
    return crypto.createHash("sha256").update(token).digest("hex");
  }

  /**
   * Yeni bir Access Token ve Refresh Token çifti oluşturup veritabanına kaydeder.
   */
  public static async createTokenPair(params: {
    userId?: string;
    merchantId?: string;
    role: string;
    deviceInfo?: string;
  }): Promise<TokenPairResult> {
    const { userId, merchantId, role, deviceInfo } = params;
    const targetId = userId || merchantId;

    if (!targetId) {
      throw new Error("Token oluşturmak için userId veya merchantId gereklidir.");
    }

    const expiresAt = new Date(
      Date.now() + this.REFRESH_TOKEN_EXPIRY_DAYS * 24 * 60 * 60 * 1000
    );

    // 1. Yeni Refresh Token DB kaydı için benzersiz kimlik
    const tempHash = crypto.randomBytes(32).toString("hex");
    const record = await prisma.refreshToken.create({
      data: {
        tokenHash: tempHash,
        userId: userId || null,
        merchantId: merchantId || null,
        expiresAt: expiresAt,
        deviceInfo: deviceInfo || null,
      },
    });

    // 2. JWT'leri üret
    const accessToken = JwtUtils.generateAccessToken(targetId, role);
    const refreshToken = JwtUtils.generateRefreshToken(targetId, role, record.id);

    // 3. Gerçek token hash'ini güncelle
    const tokenHash = this.hashToken(refreshToken);
    await prisma.refreshToken.update({
      where: { id: record.id },
      data: { tokenHash: tokenHash },
    });

    return {
      accessToken,
      refreshToken,
      expiresIn: 15 * 60, // 15 dakika = 900 saniye
    };
  }

  /**
   * Refresh Token ile yeni bir Access Token ve Refresh Token çifti üretir (Token Rotation).
   * Çalınma / Tekrar kullanım tespit edilirse (Reuse Detection) tüm oturumları kapatır.
   */
  public static async rotateRefreshToken(
    rawRefreshToken: string,
    deviceInfo?: string
  ): Promise<{ success: boolean; data?: TokenPairResult; message?: string; status?: number }> {
    // 1. Token JWT formatı ve imza doğrulaması
    const decoded = JwtUtils.verifyRefreshToken(rawRefreshToken);
    if (!decoded || !decoded.tokenId) {
      return {
        success: false,
        status: 401,
        message: "Geçersiz veya süresi dolmuş refresh token.",
      };
    }

    // 2. Veritabanından token kaydını sorgula
    const existingToken = await prisma.refreshToken.findUnique({
      where: { id: decoded.tokenId },
      include: {
        user: true,
        merchant: true,
      },
    });

    if (!existingToken) {
      return {
        success: false,
        status: 401,
        message: "Oturum kaydı bulunamadı.",
      };
    }

    // 3. REUSE DETECTION (Çalınma Tespiti): Daha önce iptal edilmiş bir token tekrar kullanılırsa!
    if (existingToken.revokedAt !== null) {
      console.warn(
        `[SECURITY ALERT] Revoke edilmiş refresh token tekrar kullanıldı! ID: ${existingToken.id}, User: ${existingToken.userId || existingToken.merchantId}`
      );

      // İlgili kullanıcının/satıcının TÜM oturumlarını güvenlik amacıyla kapat
      if (existingToken.userId) {
        await this.revokeAllForUser(existingToken.userId);
      } else if (existingToken.merchantId) {
        await this.revokeAllForMerchant(existingToken.merchantId);
      }

      return {
        success: false,
        status: 403,
        message: "Güvenlik ihlali şüphesi: Oturumunuz sonlandırıldı. Lütfen tekrar giriş yapın.",
      };
    }

    // 4. Süre kontrolü
    if (existingToken.expiresAt < new Date()) {
      await prisma.refreshToken.update({
        where: { id: existingToken.id },
        data: { revokedAt: new Date() },
      });
      return {
        success: false,
        status: 401,
        message: "Oturum süresi dolmuş. Lütfen tekrar giriş yapın.",
      };
    }

    // 5. Kullanıcı/Merchant aktiflik durumu kontrolü
    if (existingToken.merchant && existingToken.merchant.status === "REJECTED") {
      return {
        success: false,
        status: 403,
        message: "Hesabınız askıya alınmış veya reddedilmiştir.",
      };
    }

    const role = existingToken.merchant?.role || existingToken.user?.role || decoded.role || "user";
    const targetId = existingToken.userId || existingToken.merchantId;

    if (!targetId) {
      return {
        success: false,
        status: 401,
        message: "Oturum sahibi bulunamadı.",
      };
    }

    // 6. Yeni Token Çifti Üret
    const newTokens = await this.createTokenPair({
      userId: existingToken.userId || undefined,
      merchantId: existingToken.merchantId || undefined,
      role: role,
      deviceInfo: deviceInfo || existingToken.deviceInfo || undefined,
    });

    // 7. Eski token'ı revoke et ve yeni token ile ilişkilendir (Rotation)
    const newDecoded = JwtUtils.verifyRefreshToken(newTokens.refreshToken);
    await prisma.refreshToken.update({
      where: { id: existingToken.id },
      data: {
        revokedAt: new Date(),
        replacedBy: newDecoded?.tokenId || null,
      },
    });

    return {
      success: true,
      data: newTokens,
    };
  }

  /**
   * Belirli bir refresh token'ı iptal eder (Logout işlemi)
   */
  public static async revokeRefreshToken(rawRefreshToken: string): Promise<boolean> {
    try {
      const decoded = JwtUtils.verifyRefreshToken(rawRefreshToken);
      if (!decoded || !decoded.tokenId) return false;

      await prisma.refreshToken.updateMany({
        where: {
          id: decoded.tokenId,
          revokedAt: null,
        },
        data: {
          revokedAt: new Date(),
        },
      });

      return true;
    } catch (error) {
      console.error("[RefreshTokenService.revokeRefreshToken] Error:", error);
      return false;
    }
  }

  /**
   * Kullanıcının tüm oturumlarını iptal eder
   */
  public static async revokeAllForUser(userId: string): Promise<void> {
    await prisma.refreshToken.updateMany({
      where: {
        userId: userId,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
  }

  /**
   * Satıcının tüm oturumlarını iptal eder
   */
  public static async revokeAllForMerchant(merchantId: string): Promise<void> {
    await prisma.refreshToken.updateMany({
      where: {
        merchantId: merchantId,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
  }
}

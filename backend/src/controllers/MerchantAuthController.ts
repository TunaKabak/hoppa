import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcrypt";
import { JwtUtils } from "../utils/JwtUtils";

const prisma = new PrismaClient();

export class MerchantAuthController {
  /**
   * POST /api/merchant/auth/login
   * Body: { email: string, password: string }
   * Başarı: { error: false, data: { token, merchant: { id, email, businessName, status, role, ... } } }
   * Hata:   { error: true, message: "..." }
   */
  public async login(req: Request, res: Response): Promise<void> {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        res.status(400).json({ error: true, message: "E-posta ve şifre zorunludur." });
        return;
      }

      // Merchant'ı e-posta ile bul
      const merchant = await prisma.merchant.findUnique({
        where: { email: email.trim().toLowerCase() },
      });

      if (!merchant) {
        res.status(401).json({ error: true, message: "E-posta veya şifre hatalı." });
        return;
      }

      // Şifre doğrulama
      const isPasswordValid = await bcrypt.compare(password, merchant.passwordHash);
      if (!isPasswordValid) {
        res.status(401).json({ error: true, message: "E-posta veya şifre hatalı." });
        return;
      }

      // Hesap durum kontrolü — REJECTED ise giriş yapılamaz
      if (merchant.status === "REJECTED") {
        res.status(403).json({
          error: true,
          message: "Başvurunuz reddedilmiştir. Detaylı bilgi için destek ekibiyle iletişime geçiniz.",
          data: { status: merchant.status, revisionMessage: merchant.revisionMessage },
        });
        return;
      }

      // Son giriş tarihini güncelle
      await prisma.merchant.update({
        where: { id: merchant.id },
        data: { lastLogin: new Date() },
      });

      // JWT oluştur
      const token = JwtUtils.generateToken(merchant.id, merchant.role);

      // Şifre hash'ini response'tan çıkar
      const { passwordHash: _, ...merchantPublic } = merchant;

      res.status(200).json({
        error: false,
        data: {
          message: "Giriş başarılı.",
          token,
          merchant: merchantPublic,
        },
      });
    } catch (error) {
      console.error("[MerchantAuthController.login] Error:", error);
      res.status(500).json({ error: true, message: "Sunucu hatası." });
    }
  }

  /**
   * POST /api/merchant/auth/register
   * Body: { email, password, businessName, msNumber, taxNumber, phone, district, fullAddress }
   * Yeni merchant başvurusu oluşturur (status: PENDING)
   */
  public async register(req: Request, res: Response): Promise<void> {
    try {
      const { 
        email, password, businessName, msNumber, taxNumber, phone, district, fullAddress,
        ownerFirstName, ownerLastName, ownerPhone, businessPhone, merchantType, subType,
        hasHardware, agreedToTerms, identityNumber, countryCode
      } = req.body;

      if (!email || !password || !businessName) {
        res.status(400).json({ error: true, message: "E-posta, şifre ve işletme adı zorunludur." });
        return;
      }

      // Duplicate e-posta kontrolü
      const existing = await prisma.merchant.findUnique({
        where: { email: email.trim().toLowerCase() },
      });
      if (existing) {
        res.status(409).json({ error: true, message: "Bu e-posta adresi ile zaten bir başvuru yapılmış." });
        return;
      }

      const passwordHash = await bcrypt.hash(password, 12);

      const merchant = await prisma.merchant.create({
        data: {
          email: email.trim().toLowerCase(),
          passwordHash,
          businessName,
          msNumber: msNumber ?? null,
          taxNumber: taxNumber ?? null,
          phone: phone ?? null,
          district: district ?? null,
          fullAddress: fullAddress ?? null,
          ownerFirstName: ownerFirstName ?? "",
          ownerLastName: ownerLastName ?? "",
          ownerPhone: ownerPhone ?? "",
          businessPhone: businessPhone ?? "",
          merchantType: merchantType ?? "OTHER",
          subType: subType ?? null,
          hasHardware: hasHardware ?? false,
          agreedToTerms: agreedToTerms ?? false,
          identityNumber: identityNumber ?? null,
          countryCode: countryCode ?? "TR",
        },
      });

      const { passwordHash: _, ...merchantPublic } = merchant;

      res.status(201).json({
        error: false,
        data: {
          message: "Başvurunuz alındı. Ekibimiz en kısa sürede sizinle iletişime geçecek.",
          merchant: merchantPublic,
        },
      });
    } catch (error) {
      console.error("[MerchantAuthController.register] Error:", error);
      res.status(500).json({ error: true, message: "Sunucu hatası." });
    }
  }

  /**
   * POST /api/merchant/auth/submit-revision
   * Body: { merchantId, businessName, msNumber, taxNumber, phone, district, fullAddress }
   * Merchant'ın revizyon bilgilerini günceller (status → PENDING)
   */
  public async submitRevision(req: Request, res: Response): Promise<void> {
    try {
      const { merchantId, businessName, msNumber, taxNumber, phone, district, fullAddress } = req.body;

      if (!merchantId) {
        res.status(400).json({ error: true, message: "merchantId zorunludur." });
        return;
      }

      await prisma.merchant.update({
        where: { id: merchantId },
        data: {
          businessName,
          msNumber: msNumber ?? null,
          taxNumber: taxNumber ?? null,
          phone: phone ?? null,
          district: district ?? null,
          fullAddress: fullAddress ?? null,
          status: "PENDING",      // Revizyon gönderildi, tekrar incelemeye giriyor
          revisionMessage: null,  // Yönetici mesajını temizle
        },
      });

      res.status(200).json({
        error: false,
        data: { message: "Bilgileriniz güncellendi. Tekrar incelemeye alındı." },
      });
    } catch (error) {
      console.error("[MerchantAuthController.submitRevision] Error:", error);
      res.status(500).json({ error: true, message: "Sunucu hatası." });
    }
  }
}

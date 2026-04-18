import { Request, Response } from "express";
import { OtpService } from "../services/OtpService";
import { PrismaClient } from "@prisma/client";
import { JwtUtils } from "../utils/JwtUtils";

const otpService = new OtpService();
const prisma = new PrismaClient();

export class AuthController {
  
  /**
   * POST /api/auth/request-otp
   * Body: { phoneNumber: string }
   */
  public async requestOtp(req: Request, res: Response): Promise<void> {
    try {
      const { phoneNumber } = req.body;

      if (!phoneNumber) {
        res.status(400).json({ error: true, message: "Telefon numarası eksik." });
        return;
      }

      const success = await otpService.requestOtp(phoneNumber);

      if (success) {
        res.status(200).json({ error: false, data: { message: "OTP başarıyla gönderildi." } });
      } else {
        res.status(500).json({ error: true, message: "OTP gönderimi sırasında bir hata oluştu." });
      }
    } catch (error) {
      console.error("[AuthController.requestOtp] Error:", error);
      res.status(500).json({ error: true, message: "Sunucu hatası." });
    }
  }

  /**
   * POST /api/auth/verify-otp
   * Body: { phoneNumber: string, code: string }
   */
  public async verifyOtp(req: Request, res: Response): Promise<void> {
    try {
      const { phoneNumber, code } = req.body;

      if (!phoneNumber || !code) {
        res.status(400).json({ error: true, message: "Telefon numarası veya kod eksik." });
        return;
      }

      const isValid = await otpService.verifyOtp(phoneNumber, code);

      if (!isValid) {
        res.status(401).json({ error: true, message: "Geçersiz veya süresi dolmuş OTP kodu." });
        return;
      }

      // OTP geçerli, Prisma ile User'ı bul veya oluştur (upsert)
      const user = await prisma.user.upsert({
        where: { phone: phoneNumber },
        create: {
          phone: phoneNumber,
          name: "Misafir", // Varsayılan değerler
          surname: "Kullanıcı"
        },
        update: {
          lastLogin: new Date()
        }
      });

      const token = JwtUtils.generateToken(user.id, user.role);

      res.status(200).json({
        error: false,
        data: {
          message: "Oturum başarıyla açıldı.",
          token: token,
          user: user
        }
      });
    } catch (error) {
      console.error("[AuthController.verifyOtp] Error:", error);
      res.status(500).json({ error: true, message: "Sunucu hatası." });
    }
  }
}

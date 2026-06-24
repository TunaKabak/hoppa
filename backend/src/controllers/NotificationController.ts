import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class NotificationController {
  async registerToken(req: Request, res: Response) {
    try {
      const id = req.user?.id;
      const role = req.user?.role;
      if (!id || !role) {
        return res.status(401).json({ error: true, message: "Kullanıcı yetkisi bulunamadı." });
      }

      const { token, platform } = req.body;

      if (!token || !platform) {
        return res.status(400).json({ error: true, message: "Cihaz token ve platform bilgisi zorunludur." });
      }

      const userId = role === "merchant" ? null : id;
      const merchantId = role === "merchant" ? id : null;

      // Upsert the device token to prevent duplicates
      const deviceToken = await prisma.deviceToken.upsert({
        where: { token },
        update: { userId, merchantId, platform },
        create: {
          token,
          platform,
          userId,
          merchantId
        }
      });

      return res.status(200).json({ 
        error: false, 
        message: "Cihaz token başarıyla kaydedildi.",
        data: deviceToken 
      });
    } catch (error: any) {
      console.error("Token registration error:", error);
      return res.status(500).json({ error: true, message: "Sunucu hatası oluştu." });
    }
  }
}

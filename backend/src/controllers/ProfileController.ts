import { Request, Response } from 'express';
import { prisma } from '../config/db';

export class ProfileController {
  
  // 1. Profil Bilgilerini Getir
  public static async getProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          phone: true,
          email: true,
          name: true,
          surname: true,
          notifyOrderStatus: true,
          notifyCampaigns: true,
          notifyNews: true,
          createdAt: true
        }
      });

      if (!user) {
        res.status(404).json({ error: true, message: "Kullanıcı bulunamadı." });
        return;
      }

      res.status(200).json({ error: false, data: user });
    } catch (error) {
      console.error("Profile getProfile error:", error);
      res.status(500).json({ error: true, message: "Profil bilgileri getirilemedi." });
    }
  }

  // 2. Profil ve Bildirim Ayarlarını Güncelle
  public static async updateProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { name, surname, notifyOrderStatus, notifyCampaigns, notifyNews } = req.body;

      const updatedUser = await prisma.user.update({
        where: { id: userId },
        data: {
          ...(name !== undefined && { name }),
          ...(surname !== undefined && { surname }),
          ...(notifyOrderStatus !== undefined && { notifyOrderStatus: Boolean(notifyOrderStatus) }),
          ...(notifyCampaigns !== undefined && { notifyCampaigns: Boolean(notifyCampaigns) }),
          ...(notifyNews !== undefined && { notifyNews: Boolean(notifyNews) }),
        },
        select: {
          id: true,
          phone: true,
          email: true,
          name: true,
          surname: true,
          notifyOrderStatus: true,
          notifyCampaigns: true,
          notifyNews: true
        }
      });

      res.status(200).json({ error: false, data: updatedUser, message: "Profiliniz başarıyla güncellendi." });
    } catch (error) {
      console.error("Profile updateProfile error:", error);
      res.status(500).json({ error: true, message: "Profil güncellenemedi." });
    }
  }
}

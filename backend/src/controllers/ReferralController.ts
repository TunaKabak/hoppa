import { Request, Response } from "express";
import { ReferralService } from "../services/ReferralService";

export class ReferralController {
  async getReferralData(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: true, message: "Yetkisiz işlem." });
        return;
      }

      const referralCode = await ReferralService.getOrCreateReferralCode(userId);
      const referrals = await ReferralService.getReferrals(userId);
      
      const completedCount = referrals.filter((r: any) => r.status === "COMPLETED").length;
      const totalEarnings = completedCount * 100.0;

      res.status(200).json({
        error: false,
        data: {
          referralCode,
          referralCount: referrals.length,
          totalEarnings,
          referrals
        }
      });
    } catch (err: any) {
      res.status(500).json({ error: true, message: err.message || "Davet bilgileri alınamadı." });
    }
  }

  async getReferralCode(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: true, message: "Yetkisiz işlem." });
        return;
      }

      const code = await ReferralService.getOrCreateReferralCode(userId);
      const inviteLink = `https://hoppa.delivery/invite?code=${code}`;

      res.status(200).json({
        error: false,
        code,
        inviteLink
      });
    } catch (err: any) {
      res.status(500).json({ error: true, message: err.message || "Davet kodu alınamadı." });
    }
  }

  async applyReferralCode(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const { code } = req.body;

      if (!userId) {
        res.status(401).json({ error: true, message: "Yetkisiz işlem." });
        return;
      }

      if (!code) {
        res.status(400).json({ error: true, message: "Davet kodu gereklidir." });
        return;
      }

      await ReferralService.applyReferral(userId, code);
      res.status(200).json({
        error: false,
        message: "Davet kodu başarıyla uygulandı ve kuponlarınız tanımlandı!"
      });
    } catch (err: any) {
      res.status(500).json({ error: true, message: err.message || "Davet kodu uygulanamadı." });
    }
  }

  async getReferrals(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: true, message: "Yetkisiz işlem." });
        return;
      }

      const history = await ReferralService.getReferrals(userId);
      res.status(200).json({
        error: false,
        referrals: history
      });
    } catch (err: any) {
      res.status(500).json({ error: true, message: err.message || "Davet geçmişi alınamadı." });
    }
  }
}

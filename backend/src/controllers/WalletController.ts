import { Request, Response } from "express";
import { WalletService } from "../services/WalletService";

export class WalletController {
  async getWallet(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: true, message: "Yetkisiz işlem." });
        return;
      }

      const wallet = await WalletService.getOrCreateWallet(userId);
      res.status(200).json({
        error: false,
        data: {
          wallet: {
            id: wallet.id,
            balance: Number(wallet.balance),
            transactions: (wallet as any).transactions ? (wallet as any).transactions.map((tx: any) => ({
              id: tx.id,
              amount: Number(tx.amount),
              type: tx.type,
              description: tx.description,
              expiresAt: tx.expiresAt,
              createdAt: tx.createdAt
            })) : [],
            createdAt: wallet.createdAt,
            updatedAt: wallet.updatedAt
          }
        }
      });
    } catch (err: any) {
      console.error("[WalletController.getWallet] Hata:", err);
      res.status(500).json({ error: true, message: "Cüzdan bilgileri alınamadı." });
    }
  }

  async deposit(req: Request, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      res.status(401).json({ error: true, message: "Yetkisiz işlem." });
      return;
    }

    res.status(403).json({
      error: true,
      message:
        "Doğrulanmamış bakiye yükleme işlemi güvenlik nedeniyle kapatılmıştır. Lütfen 3D Secure ödeme akışını kullanın.",
    });
  }

  async getTransactions(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: true, message: "Yetkisiz işlem." });
        return;
      }

      const wallet = await WalletService.getOrCreateWallet(userId);
      res.status(200).json({
        error: false,
        transactions: wallet.transactions.map((tx: any) => ({
          id: tx.id,
          amount: Number(tx.amount),
          type: tx.type,
          description: tx.description,
          expiresAt: tx.expiresAt,
          createdAt: tx.createdAt
        }))
      });
    } catch (err: any) {
      console.error("[WalletController.getTransactions] Hata:", err);
      res.status(500).json({ error: true, message: "İşlem geçmişi alınamadı." });
    }
  }
}

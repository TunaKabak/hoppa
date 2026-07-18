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
      res.status(500).json({ error: true, message: err.message || "Cüzdan bilgileri alınamadı." });
    }
  }

  async deposit(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const { amount } = req.body;

      if (!userId) {
        res.status(401).json({ error: true, message: "Yetkisiz işlem." });
        return;
      }

      if (!amount || isNaN(amount) || amount <= 0) {
        res.status(400).json({ error: true, message: "Geçersiz yükleme tutarı." });
        return;
      }

      const wallet = await WalletService.deposit(userId, parseFloat(amount));
      res.status(200).json({
        error: false,
        message: "Bakiye başarıyla yüklendi.",
        balance: Number(wallet.balance)
      });
    } catch (err: any) {
      res.status(500).json({ error: true, message: err.message || "Bakiye yüklenemedi." });
    }
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
      res.status(500).json({ error: true, message: err.message || "İşlem geçmişi alınamadı." });
    }
  }
}

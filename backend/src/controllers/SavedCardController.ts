import crypto from 'crypto';
import { Request, Response } from 'express';
import { prisma } from '../config/db';

export class SavedCardController {

  // 1. Kartları Listele
  public async getCards(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const cards = await prisma.savedCard.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' }
      });
      res.status(200).json({ error: false, data: cards });
    } catch (error) {
      console.error("SavedCard getCards error:", error);
      res.status(500).json({ error: true, message: "Kartlar yüklenirken hata oluştu." });
    }
  }

  // 2. Yeni Kart Kaydet (PCI-DSS uyumlu: tam PAN/CVC kabul edilmez, yalnızca BIN + Last4 + Token)
  public async createCard(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const {
        cardTitle,
        cardHolderName,
        cardNumber,
        cvc,
        cardBin,
        cardLast4,
        cardToken: providedToken,
        cardType,
      } = req.body;

      if (cardNumber !== undefined || cvc !== undefined) {
        res.status(400).json({
          error: true,
          message:
            "Güvenlik (PCI-DSS) gereği tam kart numarası ve CVC sunucuya gönderilemez. Yalnızca BIN, son 4 hane ve kart belirteci gönderiniz.",
        });
        return;
      }

      const normalizedBin = typeof cardBin === "string" ? cardBin.replace(/\D/g, "") : "";
      const normalizedLast4 = typeof cardLast4 === "string" ? cardLast4.replace(/\D/g, "") : "";

      if (
        !cardTitle ||
        !cardHolderName ||
        !cardType ||
        normalizedBin.length !== 6 ||
        normalizedLast4.length !== 4
      ) {
        res.status(400).json({
          error: true,
          message: "Geçersiz veya eksik kart özeti (cardTitle, cardHolderName, cardBin[6], cardLast4[4], cardType).",
        });
        return;
      }

      const cardNumberHidden = `${normalizedBin.substring(0, 4)} ${normalizedBin.substring(4, 6)}** **** ${normalizedLast4}`;
      const cardToken =
        typeof providedToken === "string" && providedToken.trim().length >= 8
          ? providedToken.trim()
          : `tok_${crypto.randomBytes(16).toString("hex")}`;

      // Kullanıcının başka kayıtlı kartı var mı? Eğer yoksa bu varsayılan karttır.
      const existingCardsCount = await prisma.savedCard.count({
        where: { userId }
      });
      const isDefault = existingCardsCount === 0;

      const newCard = await prisma.savedCard.create({
        data: {
          userId,
          cardTitle,
          cardHolderName,
          cardNumberHidden,
          cardToken,
          cardType,
          isDefault
        }
      });

      res.status(201).json({ error: false, data: newCard, message: "Kartınız başarıyla kaydedildi!" });
    } catch (error) {
      console.error("SavedCard createCard error:", error);
      res.status(500).json({ error: true, message: "Kart kaydedilemedi." });
    }
  }

  // 3. Kart Sil
  public async deleteCard(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const cardId = req.params.id as string;

      const card = await prisma.savedCard.findFirst({
        where: { id: cardId, userId }
      });

      if (!card) {
        res.status(404).json({ error: true, message: "Kart bulunamadı." });
        return;
      }

      const wasDefault = card.isDefault;

      await prisma.savedCard.delete({
        where: { id: cardId }
      });

      // Eğer silinen kart varsayılansa ve kullanıcının başka kartı kalmışsa, birini varsayılan yap
      if (wasDefault) {
        const nextCard = await prisma.savedCard.findFirst({
          where: { userId }
        });
        if (nextCard) {
          await prisma.savedCard.update({
            where: { id: nextCard.id },
            data: { isDefault: true }
          });
        }
      }

      res.status(200).json({ error: false, message: "Kart başarıyla silindi." });
    } catch (error) {
      console.error("SavedCard deleteCard error:", error);
      res.status(500).json({ error: true, message: "Kart silinemedi." });
    }
  }

  // 4. Varsayılan Kart Seç
  public async setDefaultCard(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const cardId = req.params.id as string;

      const card = await prisma.savedCard.findFirst({
        where: { id: cardId, userId }
      });

      if (!card) {
        res.status(404).json({ error: true, message: "Kart bulunamadı." });
        return;
      }

      await prisma.$transaction([
        prisma.savedCard.updateMany({
          where: { userId },
          data: { isDefault: false }
        }),
        prisma.savedCard.update({
          where: { id: cardId },
          data: { isDefault: true }
        })
      ]);

      res.status(200).json({ error: false, message: "Varsayılan ödeme kartı güncellendi." });
    } catch (error) {
      console.error("SavedCard setDefaultCard error:", error);
      res.status(500).json({ error: true, message: "Varsayılan kart güncellenirken hata oluştu." });
    }
  }
}

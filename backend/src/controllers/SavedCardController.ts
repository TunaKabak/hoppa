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

  // 2. Yeni Kart Kaydet (Mock token ile)
  public async createCard(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { cardTitle, cardHolderName, cardNumber, cardType } = req.body;

      if (!cardTitle || !cardHolderName || !cardNumber || !cardType) {
        res.status(400).json({ error: true, message: "Eksik kart bilgileri." });
        return;
      }

      // Kart numarasını maskele: 4355 24** **** 4321
      const cleanNum = cardNumber.replace(/\s+/g, '');
      if (cleanNum.length < 12) {
        res.status(400).json({ error: true, message: "Geçersiz kart numarası." });
        return;
      }
      const cardNumberHidden = `${cleanNum.substring(0, 4)} ${cleanNum.substring(4, 6)}** **** ${cleanNum.substring(cleanNum.length - 4)}`;

      // Mock token üretelim
      const cardToken = `mock_token_${Math.random().toString(36).substring(2, 15)}`;

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

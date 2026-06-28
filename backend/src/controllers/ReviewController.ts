import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class ReviewController {
  
  // 1. Sipariş Değerlendirmesi Oluştur
  public static async createReview(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { orderId, rating, comment } = req.body;

      if (!orderId || !rating || rating < 1 || rating > 5) {
        res.status(400).json({ error: true, message: "Geçersiz puanlama veya eksik sipariş ID." });
        return;
      }

      // Siparişi ve teslim durumunu kontrol et
      const order = await prisma.order.findUnique({ where: { id: orderId } });
      if (!order || order.consumerId !== userId) {
        res.status(404).json({ error: true, message: "Sipariş bulunamadı." });
        return;
      }

      if (order.status !== "DELIVERED") {
        res.status(400).json({ error: true, message: "Yalnızca teslim edilmiş siparişleri değerlendirebilirsiniz." });
        return;
      }

      // Mükerrer yorum kontrolü
      const existingReview = await prisma.review.findUnique({ where: { orderId } });
      if (existingReview) {
        res.status(400).json({ error: true, message: "Bu sipariş için zaten bir değerlendirme yapılmış." });
        return;
      }

      // Atomik Yorum ve Puan Güncellemesi (Prisma Transaction)
      const [newReview] = await prisma.$transaction(async (tx) => {
        // 1. Yorumu oluştur
        const review = await tx.review.create({
          data: {
            rating: Number(rating),
            comment,
            userId,
            shopId: order.shopId,
            orderId
          }
        });

        // 2. Dükkanın mevcut istatistiklerini çek
        const shop = await tx.shop.findUnique({
          where: { id: order.shopId },
          select: { averageRating: true, reviewCount: true }
        });

        if (shop) {
          const newCount = shop.reviewCount + 1;
          const newRating = ((shop.averageRating * shop.reviewCount) + Number(rating)) / newCount;

          // 3. Dükkanı güncelle
          await tx.shop.update({
            where: { id: order.shopId },
            data: {
              averageRating: parseFloat(newRating.toFixed(2)),
              reviewCount: newCount
            }
          });
        }

        return [review];
      });

      res.status(201).json({ error: false, data: newReview, message: "Değerlendirmeniz başarıyla kaydedildi!" });
    } catch (error) {
      console.error("Yorum kaydetme hatası:", error);
      res.status(500).json({ error: true, message: "İşlem sırasında bir hata oluştu." });
    }
  }

  // 2. Dükkan Değerlendirmelerini Getir
  public static async getShopReviews(req: Request, res: Response): Promise<void> {
    try {
      const { shopId } = req.params;
      const reviews = await prisma.review.findMany({
        where: { shopId: shopId as string },
        include: {
          user: { select: { name: true, surname: true } }
        },
        orderBy: { createdAt: 'desc' }
      });
      res.status(200).json({ error: false, data: reviews });
    } catch (error) {
      console.error("Yorum getirme hatası:", error);
      res.status(500).json({ error: true, message: "Yorumlar getirilirken hata oluştu." });
    }
  }
}

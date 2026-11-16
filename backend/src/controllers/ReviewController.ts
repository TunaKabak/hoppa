import { Request, Response } from 'express';
import { Prisma, PrismaClient, ReviewStatus } from '@prisma/client';
import { WalletService } from '../services/WalletService';
import { SystemConfigService } from '../services/SystemConfigService';
import { realtimeEventService } from '../services/RealtimeEventService';

const prisma = new PrismaClient();

export class ReviewController {
  
  // 1. Sipariş Değerlendirmesi Oluştur
  public static async createReview(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { orderId, rating, comment, serviceRating, speedRating, tasteRating } = req.body;

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
            serviceRating: serviceRating ? Number(serviceRating) : null,
            speedRating: speedRating ? Number(speedRating) : null,
            tasteRating: tasteRating ? Number(tasteRating) : null,
            userId,
            shopId: order.shopId,
            orderId
          }
        });

        // 2. Dükkanın mevcut istatistiklerini çek
        const shop = await tx.shop.findUnique({
          where: { id: order.shopId },
          select: { 
            averageRating: true, 
            reviewCount: true,
            avgServiceRating: true,
            avgSpeedRating: true,
            avgTasteRating: true
          }
        });

        if (shop) {
          const newCount = shop.reviewCount + 1;
          const newRating = ((shop.averageRating * shop.reviewCount) + Number(rating)) / newCount;
          
          const newServiceRating = serviceRating 
            ? ((shop.avgServiceRating * shop.reviewCount) + Number(serviceRating)) / newCount 
            : shop.avgServiceRating;

          const newSpeedRating = speedRating 
            ? ((shop.avgSpeedRating * shop.reviewCount) + Number(speedRating)) / newCount 
            : shop.avgSpeedRating;

          const newTasteRating = tasteRating 
            ? ((shop.avgTasteRating * shop.reviewCount) + Number(tasteRating)) / newCount 
            : shop.avgTasteRating;

          // 3. Dükkanı güncelle
          await tx.shop.update({
            where: { id: order.shopId },
            data: {
              averageRating: parseFloat(newRating.toFixed(2)),
              avgServiceRating: parseFloat(newServiceRating.toFixed(2)),
              avgSpeedRating: parseFloat(newSpeedRating.toFixed(2)),
              avgTasteRating: parseFloat(newTasteRating.toFixed(2)),
              reviewCount: newCount
            }
          });
        }

        return [review];
      });

      try {
        realtimeEventService.publishToAdmin("ADMIN_ALERT", {
          alertType: "REVIEW_SUBMITTED",
          reviewId: newReview.id,
          orderId: newReview.orderId,
          shopId: newReview.shopId,
          userId: newReview.userId,
          rating: newReview.rating,
          status: newReview.status,
        });
      } catch (sseError) {
        console.error("[ReviewController.createReview] SSE ADMIN_ALERT yayın hatası:", sseError);
      }

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
      const enriched = await ReviewController.attachMerchantReplies(reviews);
      res.status(200).json({ error: false, data: enriched });
    } catch (error) {
      console.error("Yorum getirme hatası:", error);
      res.status(500).json({ error: true, message: "Yorumlar getirilirken hata oluştu." });
    }
  }

  private static async attachMerchantReplies<T extends { id: string }>(
    reviews: T[]
  ): Promise<Array<T & { merchantReply: string | null; merchantRepliedAt: string | null }>> {
    if (reviews.length === 0) {
      return [];
    }
    const keys = reviews.map((r) => `review_reply:${r.id}`);
    const configs = await prisma.systemConfig.findMany({
      where: { key: { in: keys } }
    });
    const replyMap = new Map<string, { reply: string; repliedAt: string | null }>();
    for (const cfg of configs) {
      try {
        const parsed = JSON.parse(cfg.value) as { reply?: string; repliedAt?: string };
        if (parsed.reply) {
          replyMap.set(cfg.key.replace(/^review_reply:/, ""), {
            reply: parsed.reply,
            repliedAt: parsed.repliedAt || null
          });
        }
      } catch {
        // Ignore malformed config entries
      }
    }
    return reviews.map((r) => {
      const entry = replyMap.get(r.id);
      return {
        ...r,
        merchantReply: entry ? entry.reply : null,
        merchantRepliedAt: entry ? entry.repliedAt : null
      };
    });
  }

  // 3. Tüketicinin Kendi Değerlendirmelerini Getir
  public static async getMyReviews(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const reviews = await prisma.review.findMany({
        where: { userId },
        include: {
          shop: { select: { id: true, name: true, imageUrl: true, type: true } }
        },
        orderBy: { createdAt: 'desc' }
      });
      res.status(200).json({ error: false, data: reviews });
    } catch (error) {
      console.error("Kendi yorumlarını getirme hatası:", error);
      res.status(500).json({ error: true, message: "Değerlendirmeleriniz getirilirken hata oluştu." });
    }
  }

  // 4. Değerlendirmeyi Onayla (Admin) ve Ödül Kazandır
  public static async approveReview(req: Request, res: Response): Promise<void> {
    try {
      const reviewId = req.params.reviewId as string;

      if (!reviewId) {
        res.status(400).json({ error: true, message: "Değerlendirme ID gereklidir." });
        return;
      }

      const review = await prisma.review.findUnique({
        where: { id: reviewId },
        include: { user: true }
      });

      if (!review) {
        res.status(404).json({ error: true, message: "Değerlendirme bulunamadı." });
        return;
      }

      if (review.status === ReviewStatus.APPROVED) {
        res.status(400).json({ error: true, message: "Bu değerlendirme zaten onaylanmış." });
        return;
      }

      // Ödül tutarlarını Sistem Ayarlarından çek
      const ratingBonusStr = await SystemConfigService.getSetting("review_rating_bonus", "5");
      const commentBonusStr = await SystemConfigService.getSetting("review_comment_bonus", "10");

      const ratingBonus = parseFloat(ratingBonusStr);
      const commentBonus = parseFloat(commentBonusStr);

      // Yorum yazılmış mı kontrolü
      const hasComment = review.comment && review.comment.trim().length > 0;
      const rewardAmount = hasComment ? commentBonus : ratingBonus;
      const description = hasComment 
        ? "Yorumlu Değerlendirme Ödülü (Hoppa Para)" 
        : "Yıldızlı Değerlendirme Ödülü (Hoppa Para)";

      await prisma.$transaction(async (tx) => {
        // Yorum durumunu güncelle
        await tx.review.update({
          where: { id: reviewId },
          data: { status: ReviewStatus.APPROVED }
        });

        // Cüzdana Hoppa Para (ödül) ekle (30 gün süreli)
        await WalletService.addReward(
          review.userId,
          rewardAmount,
          "REVIEW_BONUS",
          description,
          30 // 30 gün geçerlilik süresi
        );
      });

      res.status(200).json({
        error: false,
        message: "Değerlendirme onaylandı ve cüzdana ödül Hoppa Para yüklendi.",
        rewardAmount
      });
    } catch (error: any) {
      console.error("Yorum onaylama hatası:", error);
      res.status(500).json({ error: true, message: error.message || "İşlem sırasında bir hata oluştu." });
    }
  }

  // 5. Değerlendirmeyi Reddet (Admin)
  public static async rejectReview(req: Request, res: Response): Promise<void> {
    try {
      const reviewId = req.params.reviewId as string;

      if (!reviewId) {
        res.status(400).json({ error: true, message: "Değerlendirme ID gereklidir." });
        return;
      }

      const review = await prisma.review.findUnique({ where: { id: reviewId } });

      if (!review) {
        res.status(404).json({ error: true, message: "Değerlendirme bulunamadı." });
        return;
      }

      await prisma.review.update({
        where: { id: reviewId },
        data: { status: ReviewStatus.REJECTED }
      });

      res.status(200).json({
        error: false,
        message: "Değerlendirme reddedildi."
      });
    } catch (error: any) {
      console.error("Yorum reddetme hatası:", error);
      res.status(500).json({ error: true, message: error.message || "İşlem sırasında bir hata oluştu." });
    }
  }

  // 6. Tüm Değerlendirmeleri Listele (Süper Admin Moderasyon)
  public static async getAdminReviews(req: Request, res: Response): Promise<void> {
    try {
      const rawStatus = typeof req.query.status === 'string' ? req.query.status.trim().toUpperCase() : 'ALL';
      const where: Prisma.ReviewWhereInput = {};

      if (rawStatus && rawStatus !== 'ALL') {
        const validStatuses = Object.values(ReviewStatus) as string[];
        if (!validStatuses.includes(rawStatus)) {
          res.status(400).json({ error: true, message: "Geçersiz yorum durum filtresi." });
          return;
        }
        where.status = rawStatus as ReviewStatus;
      }

      const reviews = await prisma.review.findMany({
        where,
        include: {
          user: {
            select: {
              id: true,
              name: true,
              surname: true,
              phone: true,
            },
          },
          shop: {
            select: {
              id: true,
              name: true,
              type: true,
            },
          },
          order: {
            select: {
              id: true,
              totalAmount: true,
              createdAt: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      res.status(200).json({ error: false, data: reviews });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Yorumlar getirilirken hata oluştu.";
      console.error("[ReviewController.getAdminReviews] Hata:", error);
      res.status(500).json({ error: true, message });
    }
  }

  // 7. Satıcı Portalı: Kendi Dükkanının Yorumlarını ve Puan Özetini Getir (x-business-id uyumlu)
  public static async getMerchantShopReviews(req: Request, res: Response): Promise<void> {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        res.status(401).json({ error: true, message: "Kullanıcı yetkilendirmesi başarısız." });
        return;
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId },
        select: {
          id: true,
          name: true,
          averageRating: true,
          reviewCount: true,
          avgServiceRating: true,
          avgSpeedRating: true,
          avgTasteRating: true,
        },
      });

      if (!shop) {
        res.status(404).json({ error: true, message: "Mağaza bulunamadı." });
        return;
      }

      const reviews = await prisma.review.findMany({
        where: { shopId: shop.id },
        include: {
          user: {
            select: {
              name: true,
              surname: true,
            },
          },
          order: {
            select: {
              id: true,
              totalAmount: true,
              createdAt: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      const enrichedReviews = await ReviewController.attachMerchantReplies(reviews);

      res.status(200).json({
        error: false,
        data: {
          shop,
          reviews: enrichedReviews,
        },
      });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Mağaza yorumları getirilemedi.";
      console.error("[ReviewController.getMerchantShopReviews] Hata:", error);
      res.status(500).json({ error: true, message });
    }
  }

  // 8. Satıcı Portalı: Değerlendirmeye İşletme Yanıtı Ekle/Güncelle
  public static async replyToReview(req: Request, res: Response): Promise<void> {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        res.status(401).json({ error: true, message: "Kullanıcı yetkilendirmesi başarısız." });
        return;
      }

      const reviewId = req.params.reviewId as string;
      const reply = typeof req.body?.reply === "string" ? req.body.reply.trim() : "";

      if (!reviewId) {
        res.status(400).json({ error: true, message: "Değerlendirme ID gereklidir." });
        return;
      }
      if (reply.length < 2 || reply.length > 500) {
        res.status(400).json({ error: true, message: "Yanıt metni 2 ile 500 karakter arasında olmalıdır." });
        return;
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId },
        select: { id: true }
      });
      if (!shop) {
        res.status(404).json({ error: true, message: "Mağaza bulunamadı." });
        return;
      }

      const review = await prisma.review.findUnique({
        where: { id: reviewId },
        select: { id: true, shopId: true }
      });
      if (!review || review.shopId !== shop.id) {
        res.status(404).json({ error: true, message: "Değerlendirme bulunamadı veya mağazanıza ait değil." });
        return;
      }

      const repliedAt = new Date().toISOString();
      await prisma.systemConfig.upsert({
        where: { key: `review_reply:${reviewId}` },
        update: { value: JSON.stringify({ reply, repliedAt }) },
        create: { key: `review_reply:${reviewId}`, value: JSON.stringify({ reply, repliedAt }) }
      });

      res.status(200).json({
        error: false,
        message: "Değerlendirme yanıtınız kaydedildi.",
        data: { reviewId, merchantReply: reply, merchantRepliedAt: repliedAt }
      });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Yanıt kaydedilemedi.";
      console.error("[ReviewController.replyToReview] Hata:", error);
      res.status(500).json({ error: true, message });
    }
  }
}

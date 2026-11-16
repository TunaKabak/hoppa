import { Request, Response } from "express";
import { Prisma, PrismaClient } from "@prisma/client";
import { realtimeEventService } from "../services/RealtimeEventService";

const prisma = new PrismaClient();

export class ShopCampaignController {
  /**
   * GET /api/merchant/coupons
   * Dükkanın kendi oluşturduğu indirim kuponlarını kullanım sayısıyla listeler.
   */
  async getMerchantCoupons(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı yetkilendirmesi başarısız." });
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId },
        select: { id: true }
      });
      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const coupons = await prisma.coupon.findMany({
        where: { creatorShopId: shop.id },
        include: {
          _count: { select: { usages: true } }
        },
        orderBy: { createdAt: "desc" }
      });

      return res.status(200).json({ error: false, data: coupons });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Kuponlar alınamadı.";
      console.error("[ShopCampaignController.getMerchantCoupons] Error:", error);
      return res.status(500).json({ error: true, message });
    }
  }

  /**
   * POST /api/merchant/coupons
   * Dükkana özel indirim kuponu oluşturur.
   */
  async createMerchantCoupon(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı yetkilendirmesi başarısız." });
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId },
        select: { id: true, name: true }
      });
      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const rawCode = typeof req.body?.code === "string" ? req.body.code.trim().toUpperCase() : "";
      const discountType = req.body?.discountType === "FIXED" ? "FIXED" : req.body?.discountType === "PERCENTAGE" ? "PERCENTAGE" : "";
      const discountValue = Number(req.body?.discountValue);
      const minOrderAmount = req.body?.minOrderAmount !== undefined ? Number(req.body.minOrderAmount) : 0;
      const rawTitle = typeof req.body?.title === "string" ? req.body.title.trim() : "";

      if (!/^[A-Z0-9_-]{3,24}$/.test(rawCode)) {
        return res.status(400).json({
          error: true,
          message: "Kupon kodu 3-24 karakter arası harf ve rakamlardan oluşmalıdır."
        });
      }
      if (!discountType) {
        return res.status(400).json({ error: true, message: "Geçersiz indirim tipi (PERCENTAGE veya FIXED)." });
      }
      if (!Number.isFinite(discountValue) || discountValue <= 0) {
        return res.status(400).json({ error: true, message: "İndirim miktarı sıfırdan büyük olmalıdır." });
      }
      if (discountType === "PERCENTAGE" && discountValue > 90) {
        return res.status(400).json({ error: true, message: "Yüzde indirim oranı en fazla %90 olabilir." });
      }
      if (!Number.isFinite(minOrderAmount) || minOrderAmount < 0) {
        return res.status(400).json({ error: true, message: "Minimum sepet tutarı negatif olamaz." });
      }

      const startDate = new Date();
      let endDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      if (typeof req.body?.endDate === "string" && req.body.endDate.trim().length > 0) {
        const parsedEnd = new Date(req.body.endDate);
        if (Number.isNaN(parsedEnd.getTime())) {
          return res.status(400).json({ error: true, message: "Geçersiz son kullanma tarihi." });
        }
        parsedEnd.setHours(23, 59, 59, 999);
        if (parsedEnd <= startDate) {
          return res.status(400).json({ error: true, message: "Son kullanma tarihi bugünden sonraki bir tarih olmalıdır." });
        }
        endDate = parsedEnd;
      }

      const existing = await prisma.coupon.findUnique({ where: { code: rawCode } });
      if (existing) {
        return res.status(400).json({ error: true, message: `"${rawCode}" kupon kodu sistemde zaten tanımlı.` });
      }

      const defaultTitle = discountType === "PERCENTAGE"
        ? `${shop.name} %${discountValue} İndirim`
        : `${shop.name} ₺${discountValue} İndirim`;

      const created = await prisma.$transaction(async (tx) => {
        const coupon = await tx.coupon.create({
          data: {
            code: rawCode,
            title: rawTitle || defaultTitle,
            discountType,
            discountValue,
            minOrderAmount,
            startDate,
            endDate,
            isActive: true,
            isSystemCoupon: false,
            creatorShopId: shop.id
          }
        });

        await tx.couponShop.create({
          data: {
            couponId: coupon.id,
            shopId: shop.id
          }
        });

        return coupon;
      });

      return res.status(201).json({
        error: false,
        message: "İndirim kuponunuz yayınlandı.",
        data: { ...created, _count: { usages: 0 } }
      });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Kupon oluşturulamadı.";
      console.error("[ShopCampaignController.createMerchantCoupon] Error:", error);
      return res.status(500).json({ error: true, message });
    }
  }

  /**
   * DELETE /api/merchant/coupons/:id
   * Dükkana ait indirim kuponunu kaldırır (kullanımı varsa pasife çeker).
   */
  async deleteMerchantCoupon(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı yetkilendirmesi başarısız." });
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId },
        select: { id: true }
      });
      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const couponId = req.params.id as string;
      const coupon = await prisma.coupon.findUnique({
        where: { id: couponId },
        include: { _count: { select: { usages: true } } }
      });

      if (!coupon || coupon.creatorShopId !== shop.id) {
        return res.status(404).json({ error: true, message: "Kupon bulunamadı veya yetkiniz yok." });
      }

      if (coupon._count.usages > 0) {
        await prisma.coupon.update({
          where: { id: coupon.id },
          data: { isActive: false }
        });
        return res.status(200).json({
          error: false,
          message: "Daha önce kullanıldığı için kupon pasife çekildi."
        });
      }

      await prisma.coupon.delete({ where: { id: coupon.id } });
      return res.status(200).json({
        error: false,
        message: "Kupon kalıcı olarak kaldırıldı."
      });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Kupon kaldırılamadı.";
      console.error("[ShopCampaignController.deleteMerchantCoupon] Error:", error);
      return res.status(500).json({ error: true, message });
    }
  }

  /**
   * GET /api/admin/campaigns
   * Süper Admin için kampanya/slider onay kuyruğunu ve mevcut kampanyaları listeler.
   */
  async getAdminCampaigns(req: Request, res: Response) {
    try {
      const rawStatus = typeof req.query.status === "string" ? req.query.status.trim().toUpperCase() : "";
      const where: Prisma.CampaignWhereInput = {};

      if (rawStatus && rawStatus !== "ALL") {
        const mappedStatus = rawStatus === "PENDING" ? "PENDING_APPROVAL" : rawStatus;
        if (!["PENDING_APPROVAL", "APPROVED", "REJECTED"].includes(mappedStatus)) {
          return res.status(400).json({ error: true, message: "Geçersiz kampanya durum filtresi." });
        }
        where.status = mappedStatus;
      }

      const campaigns = await prisma.campaign.findMany({
        where,
        include: {
          shop: {
            select: {
              id: true,
              name: true,
              type: true,
            },
          },
        },
        orderBy: { createdAt: "desc" },
      });

      return res.status(200).json({ error: false, data: campaigns });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Kampanyalar getirilemedi.";
      console.error("[ShopCampaignController.getAdminCampaigns] Error:", error);
      return res.status(500).json({ error: true, message });
    }
  }

  async createCampaign(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı yetkilendirmesi başarısız." });
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId }
      });
      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const { title, description, imageUrl, targetArea, designService, targetProducts } = req.body;
      if (!title || !description || !targetArea) {
        return res.status(400).json({ error: true, message: "Lütfen başlık, açıklama ve kampanya alanını seçin." });
      }

      const isSlider = targetArea === "CATEGORY_SLIDER" || targetArea === "MAIN_SLIDER";
      const status = isSlider ? "PENDING_APPROVAL" : "APPROVED";

      const campaign = await prisma.campaign.create({
        data: {
          shopId: shop.id,
          title,
          description,
          imageUrl: imageUrl || "",
          targetArea,
          designService: Boolean(designService),
          status,
          type: "SHOP",
          isActive: true,
          targetProducts: Array.isArray(targetProducts) ? targetProducts : []
        }
      });

      try {
        realtimeEventService.publishToAdmin("ADMIN_ALERT", {
          alertType: "CAMPAIGN_SUBMITTED",
          campaignId: campaign.id,
          shopId: shop.id,
          shopName: shop.name,
          title: campaign.title,
          targetArea: campaign.targetArea,
          status: campaign.status,
        });
      } catch (sseError) {
        console.error("[ShopCampaignController.createCampaign] SSE ADMIN_ALERT yayın hatası:", sseError);
      }

      return res.status(201).json({ error: false, data: campaign });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async getMyCampaigns(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı yetkilendirmesi başarısız." });
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId }
      });
      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const campaigns = await prisma.campaign.findMany({
        where: { shopId: shop.id, type: "SHOP" },
        orderBy: { createdAt: "desc" }
      });

      return res.status(200).json({ error: false, data: campaigns });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async approveCampaign(req: Request, res: Response) {
    try {
      const campaignId = req.params.campaignId as string;
      const { status } = req.body; // "APPROVED" veya "REJECTED"

      if (!campaignId || !status) {
        return res.status(400).json({ error: true, message: "Eksik parametre." });
      }

      const campaign = await prisma.campaign.update({
        where: { id: campaignId },
        data: { status }
      });

      // Eğer kampanya onaylandıysa ve bir slider reklamı ise dükkana ShopPromotion (sponsorship) kaydı da ekle
      if (status === "APPROVED" && campaign.shopId && (campaign.targetArea === "MAIN_SLIDER" || campaign.targetArea === "CATEGORY_SLIDER")) {
        const promoType = campaign.targetArea === "MAIN_SLIDER" ? "MAIN_SCREEN" : "CATEGORY";
        
        // 7 günlük sponsorluk oluştur
        await prisma.shopPromotion.create({
          data: {
            shopId: campaign.shopId,
            promoType,
            startDate: new Date(),
            endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
            isActive: true
          }
        });
      }

      return res.status(200).json({ error: false, message: "Kampanya onay durumu güncellendi.", data: campaign });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async getActiveSliders(req: Request, res: Response) {
    try {
      const campaigns = await prisma.campaign.findMany({
        where: {
          status: "APPROVED",
          isActive: true,
          OR: [
            { type: "SHOP" },
            { type: "SYSTEM" },
            { type: "AD" }
          ]
        },
        include: {
          shop: true
        },
        orderBy: { createdAt: "desc" }
      });

      return res.status(200).json({ error: false, data: campaigns });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

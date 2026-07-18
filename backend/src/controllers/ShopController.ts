import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class ShopController {
  async getMyShop(req: Request, res: Response) {
    try {
      const isSuperAdmin = req.user?.role === "super_admin";
      const queryShopId = req.query.shopId as string;

      let shop;
      if (isSuperAdmin && queryShopId) {
        shop = await prisma.shop.findUnique({
          where: { id: queryShopId },
          include: { merchant: { select: { businessName: true, status: true, businessPhone: true, identityNumber: true, taxNumber: true } } }
        });
      } else {
        const merchantId = req.user?.id;
        if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

        shop = await prisma.shop.findUnique({
          where: { merchantId },
          include: { merchant: { select: { businessName: true, status: true, businessPhone: true, identityNumber: true, taxNumber: true } } }
        });
      }

      if (shop) {
        const now = new Date();
        const activePromotions = await prisma.shopPromotion.findMany({
          where: {
            shopId: shop.id,
            isActive: true,
            startDate: { lte: now },
            endDate: { gte: now }
          }
        });

        const hasMainScreen = activePromotions.some(p => p.promoType === "MAIN_SCREEN");
        const hasCategory = activePromotions.some(p => p.promoType === "CATEGORY");

        let activeCommissionRate = 0.05;
        if (hasMainScreen) {
          activeCommissionRate = 0.15;
        } else if (hasCategory) {
          activeCommissionRate = 0.10;
        }

        const enrichedShop = {
          ...shop,
          activeCommissionRate,
          activePromotions
        };

        return res.status(200).json({ error: false, data: enrichedShop });
      }

      return res.status(200).json({ error: false, data: shop });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async updateMyShop(req: Request, res: Response) {
    try {
      const isSuperAdmin = req.user?.role === "super_admin";
      const queryShopId = req.query.shopId as string;

      let targetShop;
      if (isSuperAdmin && queryShopId) {
        targetShop = await prisma.shop.findUnique({
          where: { id: queryShopId }
        });
      } else {
        const merchantId = req.user?.id;
        if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

        targetShop = await prisma.shop.findUnique({
          where: { merchantId }
        });
      }

      if (!targetShop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const {
        name, description, address, latitude, longitude,
        deliveryRadiusKm, deliveryPolygon, workingHours, minOrderAmount, minimumOrderAmount, minimumOrderLimit, imageUrl, headerImageUrl,
        taxNumber, businessPhone, identityNumber,
        deliveryPricingType, baseDeliveryFee, deliveryFeePerKm, freeDeliveryThreshold, deliveryTime,
        allowedPaymentMethods, allowedFulfillmentModels
      } = req.body;

      if (allowedPaymentMethods !== undefined) {
        if (!Array.isArray(allowedPaymentMethods) || allowedPaymentMethods.length === 0) {
          return res.status(400).json({ error: true, message: "En az bir ödeme yöntemi kabul edilmelidir." });
        }
        const validMethods = ["CASH_ON_DELIVERY", "CARD_ON_DELIVERY", "ONLINE_PAYMENT"];
        for (const m of allowedPaymentMethods) {
          if (!validMethods.includes(m)) {
            return res.status(400).json({ error: true, message: `Geçersiz ödeme yöntemi: ${m}` });
          }
        }
      }

      if (allowedFulfillmentModels !== undefined) {
        if (!Array.isArray(allowedFulfillmentModels) || allowedFulfillmentModels.length === 0) {
          return res.status(400).json({ error: true, message: "En az bir teslimat/hizmet yöntemi kabul edilmelidir." });
        }
        const validModels = ["PLATFORM_DELIVERY", "SELF_DELIVERY", "PICKUP"];
        for (const m of allowedFulfillmentModels) {
          if (!validModels.includes(m)) {
            return res.status(400).json({ error: true, message: `Geçersiz teslimat yöntemi: ${m}` });
          }
        }
      }

      // Build merchant update payload dynamically
      const merchantUpdate: any = {};
      if (businessPhone !== undefined) merchantUpdate.businessPhone = businessPhone;
      if (identityNumber !== undefined) merchantUpdate.identityNumber = identityNumber;

      const updated = await prisma.shop.update({
        where: { id: targetShop.id },
        data: {
          name,
          description,
          address,
          latitude,
          longitude,
          deliveryRadiusKm,
          deliveryPolygon,
          workingHours,
          minOrderAmount: minimumOrderAmount ?? minOrderAmount,
          minimumOrderAmount: minimumOrderAmount ?? minOrderAmount,
          minimumOrderLimit: minimumOrderLimit !== undefined ? minimumOrderLimit : undefined,
          deliveryPricingType,
          baseDeliveryFee,
          deliveryFeePerKm,
          freeDeliveryThreshold,
          deliveryTime,
          imageUrl,
          headerImageUrl,
          taxNumber,
          allowedPaymentMethods,
          allowedFulfillmentModels,
          ...(Object.keys(merchantUpdate).length > 0 ? {
            merchant: {
              update: merchantUpdate
            }
          } : {})
        },
        include: { merchant: { select: { businessName: true, status: true, businessPhone: true, identityNumber: true, taxNumber: true } } }
      });

      return res.status(200).json({ error: false, data: updated });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async openCloseShop(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      const { isActive } = req.body;

      if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

      if (isActive) {
        const shop = await prisma.shop.findUnique({
          where: { merchantId },
          include: { merchant: true }
        });

        if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });

        const { latitude, longitude, workingHours } = shop;
        const { businessPhone, identityNumber } = shop.merchant;
        const taxNumber = shop.taxNumber || shop.merchant.taxNumber;

        if (!latitude || !longitude || !workingHours || !businessPhone || (!identityNumber && !taxNumber)) {
          return res.status(400).json({
            error: true,
            message: "Lütfen Dükkan ve Resmi İşletme (Kimlik/Vergi) ayarlarınızı tamamlayın."
          });
        }
      }

      const updated = await prisma.shop.update({
        where: { merchantId },
        data: { isActive }
      });

      return res.status(200).json({ error: false, data: updated });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async getDashboardStats(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

      const shop = await prisma.shop.findUnique({ where: { merchantId } });
      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const allOrders = await prisma.order.findMany({
        where: { shopId: shop.id }
      });

      const todayOrders = allOrders.filter(o => o.createdAt >= today && o.status !== "CANCELLED");
      const todayOrderCount = todayOrders.length;

      const totalRevenue = allOrders
        .filter(o => o.paymentStatus === "SUCCESS")
        .reduce((sum, o) => sum + Number(o.totalAmount), 0);

      const totalOrdersCount = allOrders.length;
      const cancelledOrdersCount = allOrders.filter(o => o.status === "CANCELLED").length;
      const cancelRate = totalOrdersCount > 0 ? (cancelledOrdersCount / totalOrdersCount) * 100 : 0;

      // Haftalık Trend: Son 7 günün başarılı siparişleri
      const weeklyTrend = [];
      for (let i = 6; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        d.setHours(0, 0, 0, 0);
        const nextD = new Date(d);
        nextD.setDate(d.getDate() + 1);

        const dailyCount = allOrders.filter(
          o => o.createdAt >= d && o.createdAt < nextD && o.status !== "CANCELLED"
        ).length;

        weeklyTrend.push({ date: d.toISOString().split('T')[0], orderCount: dailyCount });
      }

      return res.status(200).json({
        error: false,
        data: {
          todayOrderCount,
          totalRevenue,
          cancelRate,
          weeklyTrend
        }
      });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async createPromotion(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

      const { promoType } = req.body;
      if (promoType !== "MAIN_SCREEN" && promoType !== "CATEGORY") {
        return res.status(400).json({ error: true, message: "Geçersiz sponsorluk türü." });
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId }
      });

      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const now = new Date();
      // Aktif sponsorluk var mı kontrolü (Karşılıklı Dışlama)
      const existing = await prisma.shopPromotion.findFirst({
        where: {
          shopId: shop.id,
          isActive: true,
          startDate: { lte: now },
          endDate: { gte: now }
        }
      });

      if (existing) {
        // Kategori promosyonundan Ana Sayfa promosyonuna yükseltmeye (upgrade) izin ver
        if (existing.promoType === "CATEGORY" && promoType === "MAIN_SCREEN") {
          await prisma.shopPromotion.update({
            where: { id: existing.id },
            data: { isActive: false }
          });
        } else {
          return res.status(400).json({
            error: true,
            message: existing.promoType === "MAIN_SCREEN"
              ? "Ana sayfa tepe slider sponsorluğunuz zaten aktif durumdadır. Kategori içi öne çıkarma satın alamazsınız."
              : "Zaten aktif bir öne çıkarma kampanyanız bulunmaktadır. Karşılıklı dışlama kuralı gereği aynı anda birden fazla reklam satın alamazsınız."
          });
        }
      }

      // Sponsorluk 1 haftalık (7 gün) oluşturulur
      const startDate = new Date();
      const endDate = new Date(startDate.getTime() + 7 * 24 * 60 * 60 * 1000);

      await prisma.shopPromotion.create({
        data: {
          shopId: shop.id,
          promoType,
          startDate,
          endDate,
          isActive: true
        }
      });

      // Zenginleştirilmiş shop bilgisini dönelim ki frontend state'i anında güncellensin
      const queryTime = new Date();
      const activePromotions = await prisma.shopPromotion.findMany({
        where: {
          shopId: shop.id,
          isActive: true,
          startDate: { lte: queryTime },
          endDate: { gte: queryTime }
        }
      });

      const hasMainScreen = activePromotions.some(p => p.promoType === "MAIN_SCREEN");
      const hasCategory = activePromotions.some(p => p.promoType === "CATEGORY");

      let activeCommissionRate = 0.05;
      if (hasMainScreen) {
        activeCommissionRate = 0.15;
      } else if (hasCategory) {
        activeCommissionRate = 0.10;
      }

      const enrichedShop = {
        ...shop,
        activeCommissionRate,
        activePromotions
      };

      return res.status(201).json({
        error: false,
        message: "Sponsorluk başarıyla aktif edildi.",
        data: enrichedShop
      });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async getPromotions(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

      const shop = await prisma.shop.findUnique({
        where: { merchantId }
      });

      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const promotions = await prisma.shopPromotion.findMany({
        where: { shopId: shop.id },
        orderBy: { createdAt: "desc" }
      });

      return res.status(200).json({ error: false, data: promotions });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async cancelPromotion(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

      const { promoType } = req.body;
      if (!promoType) {
        return res.status(400).json({ error: true, message: "İptal edilecek sponsorluk türü (promoType) belirtilmelidir." });
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId }
      });

      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      // Aktif promosyonu devre dışı bırak
      const now = new Date();
      const activePromo = await prisma.shopPromotion.findFirst({
        where: {
          shopId: shop.id,
          promoType,
          isActive: true,
          startDate: { lte: now },
          endDate: { gte: now }
        }
      });

      if (!activePromo) {
        return res.status(400).json({
          error: true,
          message: "İptal edilecek aktif bir sponsorluk bulunamadı."
        });
      }

      // Pasifleştir
      await prisma.shopPromotion.update({
        where: { id: activePromo.id },
        data: { isActive: false }
      });

      // Zenginleştirilmiş güncel dükkan bilgisini geri dön
      const queryTime = new Date();
      const activePromotions = await prisma.shopPromotion.findMany({
        where: {
          shopId: shop.id,
          isActive: true,
          startDate: { lte: queryTime },
          endDate: { gte: queryTime }
        }
      });

      const hasMainScreen = activePromotions.some(p => p.promoType === "MAIN_SCREEN");
      const hasCategory = activePromotions.some(p => p.promoType === "CATEGORY");

      let activeCommissionRate = 0.05;
      if (hasMainScreen) {
        activeCommissionRate = 0.15;
      } else if (hasCategory) {
        activeCommissionRate = 0.10;
      }

      const enrichedShop = {
        ...shop,
        activeCommissionRate,
        activePromotions
      };

      return res.status(200).json({
        error: false,
        message: "Sponsorluk başarıyla iptal edildi.",
        data: enrichedShop
      });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

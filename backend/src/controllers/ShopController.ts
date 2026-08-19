import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class ShopController {
  async getMyShop(req: Request, res: Response) {
    try {
      const isSuperAdmin = req.user?.role === "super_admin" || req.user?.role === "admin";
      const shopIdHeader = (req.headers["x-business-id"] || req.headers["x-shop-id"]) as string;
      const queryShopId = (req.query.shopId as string) || shopIdHeader;

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
          businessName: shop.name || shop.merchant?.businessName,
          phone: shop.merchant?.businessPhone,
          logoUrl: shop.imageUrl,
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
      const isSuperAdmin = req.user?.role === "super_admin" || req.user?.role === "admin";
      const shopIdHeader = (req.headers["x-business-id"] || req.headers["x-shop-id"]) as string;
      const queryShopId = (req.query.shopId as string) || shopIdHeader;

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
        name, businessName, description, address, latitude, longitude,
        deliveryRadiusKm, deliveryPolygon, workingHours, minOrderAmount, minimumOrderAmount, minimumOrderLimit,
        imageUrl, logoUrl, headerImageUrl,
        taxNumber, phone, phoneNumber, businessPhone, identityNumber,
        deliveryPricingType, baseDeliveryFee, deliveryFeePerKm, freeDeliveryThreshold, deliveryTime,
        allowedPaymentMethods, allowedFulfillmentModels, campaignText, isActive
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

      const finalName = name || businessName;
      const finalLogoUrl = imageUrl || logoUrl;
      const finalPhone = businessPhone || phone || phoneNumber;
      const finalMinOrderAmount = minOrderAmount ?? minimumOrderAmount;

      // Build merchant update payload dynamically
      const merchantUpdate: any = {};
      if (finalPhone !== undefined) merchantUpdate.businessPhone = finalPhone;
      if (identityNumber !== undefined) merchantUpdate.identityNumber = identityNumber;
      if (finalName !== undefined) merchantUpdate.businessName = finalName;

      const shopData: any = {};
      if (finalName !== undefined) shopData.name = finalName;
      if (description !== undefined) shopData.description = description;
      if (address !== undefined) shopData.address = address;
      if (latitude !== undefined) shopData.latitude = latitude !== null ? Number(latitude) : null;
      if (longitude !== undefined) shopData.longitude = longitude !== null ? Number(longitude) : null;
      if (deliveryRadiusKm !== undefined) shopData.deliveryRadiusKm = Number(deliveryRadiusKm);
      if (deliveryPolygon !== undefined) shopData.deliveryPolygon = deliveryPolygon;
      if (workingHours !== undefined) shopData.workingHours = workingHours;
      if (finalMinOrderAmount !== undefined) {
        shopData.minOrderAmount = Number(finalMinOrderAmount);
        shopData.minimumOrderAmount = Number(finalMinOrderAmount);
      }
      if (minimumOrderLimit !== undefined) shopData.minimumOrderLimit = Number(minimumOrderLimit);
      if (deliveryPricingType !== undefined) shopData.deliveryPricingType = deliveryPricingType;
      if (baseDeliveryFee !== undefined) shopData.baseDeliveryFee = Number(baseDeliveryFee);
      if (deliveryFeePerKm !== undefined) shopData.deliveryFeePerKm = Number(deliveryFeePerKm);
      if (freeDeliveryThreshold !== undefined) shopData.freeDeliveryThreshold = freeDeliveryThreshold !== null ? Number(freeDeliveryThreshold) : null;
      if (deliveryTime !== undefined) shopData.deliveryTime = deliveryTime;
      if (finalLogoUrl !== undefined) shopData.imageUrl = finalLogoUrl;
      if (headerImageUrl !== undefined) shopData.headerImageUrl = headerImageUrl;
      if (taxNumber !== undefined) shopData.taxNumber = taxNumber;
      if (allowedPaymentMethods !== undefined) shopData.allowedPaymentMethods = allowedPaymentMethods;
      if (allowedFulfillmentModels !== undefined) shopData.allowedFulfillmentModels = allowedFulfillmentModels;
      if (campaignText !== undefined) shopData.campaignText = campaignText;
      if (isActive !== undefined) {
        if (isActive === true) {
          const activeProductCount = await prisma.product.count({
            where: { shopId: targetShop.id, isActive: true }
          });
          if (activeProductCount === 0) {
            return res.status(400).json({
              error: true,
              message: "İşletmenizi aktif hale getirebilmek için en az 1 aktif ürün eklemiş olmanız gerekmektedir."
            });
          }
        }
        shopData.isActive = isActive;
      }

      if (Object.keys(merchantUpdate).length > 0) {
        shopData.merchant = {
          update: merchantUpdate
        };
      }

      const updated = await prisma.shop.update({
        where: { id: targetShop.id },
        data: shopData,
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
      if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

      const shop = await prisma.shop.findUnique({
        where: { merchantId },
        include: { merchant: true }
      });

      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });

      // req.body.isActive tanımlıysa onu kullan, değilse mevcut durumun tersini al
      let newActiveState = typeof req.body?.isActive === 'boolean' 
        ? req.body.isActive 
        : !shop.isActive;

      if (newActiveState === true) {
        const activeProductCount = await prisma.product.count({
          where: { shopId: shop.id, isActive: true }
        });
        if (activeProductCount === 0) {
          return res.status(400).json({
            error: true,
            message: "İşletmenizi aktif hale getirebilmek için en az 1 aktif ürün eklemiş olmanız gerekmektedir."
          });
        }
      }

      const updated = await prisma.shop.update({
        where: { merchantId },
        data: { isActive: newActiveState }
      });

      return res.status(200).json({ 
        error: false, 
        message: updated.isActive ? "Dükkanınız sipariş alımına AÇILDI." : "Dükkanınız sipariş alımına KAPATILDI.",
        data: updated 
      });
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

  async getShopReadiness(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

      const shop = await prisma.shop.findUnique({
        where: { merchantId },
        include: { merchant: true }
      });

      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });

      const activeProductCount = await prisma.product.count({
        where: { shopId: shop.id, isActive: true }
      });

      // 6 Prosedür Adımı Kontrolü
      const step1_Identity = Boolean(shop.name && shop.imageUrl && shop.description);
      const step2_Location = Boolean(shop.latitude && shop.longitude && (shop.deliveryRadiusKm || shop.deliveryPolygon));
      const step3_Hours = Boolean(shop.workingHours);
      const step4_Payment = Boolean(
        shop.allowedPaymentMethods &&
        Array.isArray(shop.allowedPaymentMethods) &&
        shop.allowedPaymentMethods.length > 0 &&
        shop.allowedFulfillmentModels &&
        Array.isArray(shop.allowedFulfillmentModels) &&
        shop.allowedFulfillmentModels.length > 0
      );
      const step5_Products = activeProductCount >= 1;
      const step6_Legal = Boolean((shop.merchant?.taxNumber || shop.taxNumber || shop.merchant?.identityNumber) && (shop.merchant?.businessPhone));

      const steps = [
        {
          id: 'identity',
          title: 'Marka Kimliği & Görseller',
          description: 'Dükkan adı, logosu ve açıklaması tanımlanmış olmalıdır.',
          category: 'IDENTITY',
          isCompleted: step1_Identity,
          weight: 15,
          actionText: 'Profili Düzenle',
          actionUrl: '/merchant/settings?tab=general'
        },
        {
          id: 'location',
          title: 'Konum & Teslimat Bölgesi',
          description: 'İşletmenizin harita konumu ve teslimat yarıçapı belirlenmelidir.',
          category: 'LOCATION',
          isCompleted: step2_Location,
          weight: 20,
          actionText: 'Konumu Seç',
          actionUrl: '/merchant/settings?tab=location'
        },
        {
          id: 'hours',
          title: 'Çalışma Saatleri',
          description: 'Otomatik sipariş alımı için haftalık açık olunan saatler ayarlanmalıdır.',
          category: 'HOURS',
          isCompleted: step3_Hours,
          weight: 15,
          actionText: 'Saatleri Ayarla',
          actionUrl: '/merchant/settings?tab=working_hours'
        },
        {
          id: 'payment',
          title: 'Ödeme ve Teslimat Yöntemleri',
          description: 'Kabul edilen ödeme ve teslimat yöntemleri ile minimum sipariş tutarı seçilmelidir.',
          category: 'PAYMENT',
          isCompleted: step4_Payment,
          weight: 20,
          actionText: 'Yöntemleri Seç',
          actionUrl: '/merchant/settings?tab=payment_delivery'
        },
        {
          id: 'products',
          title: 'Menü & Ürün Kataloğu',
          description: 'Müşterilerin sipariş verebilmesi için en az 1 aktif ürün eklenmelidir.',
          category: 'PRODUCTS',
          isCompleted: step5_Products,
          weight: 20,
          actionText: 'Ürün Ekle',
          actionUrl: '/merchant/products'
        },
        {
          id: 'legal',
          title: 'Resmi İşletme & Finansal Bilgiler',
          description: 'Fatura ve finans işlemleri için vergi/kimlik no ve resmi telefon girilmelidir.',
          category: 'LEGAL',
          isCompleted: step6_Legal,
          weight: 10,
          actionText: 'Bilgileri Tamamla',
          actionUrl: '/merchant/settings?tab=official'
        }
      ];

      let score = 0;
      steps.forEach(s => {
        if (s.isCompleted) score += s.weight;
      });

      const missingSteps = steps.filter(s => !s.isCompleted);
      const isReadyToOpen = score === 100 && step5_Products;

      return res.status(200).json({
        error: false,
        data: {
          score,
          isReadyToOpen,
          totalSteps: steps.length,
          completedStepsCount: steps.length - missingSteps.length,
          steps,
          missingSteps,
          activeProductCount
        }
      });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

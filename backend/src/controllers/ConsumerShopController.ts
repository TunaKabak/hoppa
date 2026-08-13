import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

function formatProduct(product: any) {
  if (!product) return null;
  const cat = product.category;
  const parent = cat?.parent;
  
  return {
    ...product,
    unit: product.unit ? product.unit.code : "ADET",
    brand: product.brand ? product.brand.name : null,
    imageUrl: product.imageUrl || product.globalProduct?.imageUrl || "/images/default-product.png",
    category: cat ? {
      id: cat.id,
      name: cat.name,
      parent: parent ? {
        id: parent.id,
        name: parent.name,
        shopType: parent.shopType
      } : null
    } : null,
    categoryId: cat ? cat.id : null,
    optionGroups: product.optionGroups || []
  };
}

function checkIsOpen(shop: any): boolean {
  if (!shop.isActive) return false;

  if (!shop.workingHours) {
    // Çalışma saatleri henüz girilmemişse dükkan aktifse AÇIK kabul et
    return true;
  }

  const countryCode = shop.merchant?.countryCode || "TR";
  const tz = (countryCode === "CY" || countryCode === "KKTC") ? "Europe/Nicosia" : "Europe/Istanbul";

  const now = new Date();
  
  const formatter = new Intl.DateTimeFormat("tr-TR", {
    timeZone: tz,
    hour: "numeric",
    minute: "numeric",
    hour12: false,
    weekday: "long"
  });
  
  const parts = formatter.formatToParts(now);
  let currentHour = 0;
  let currentMinute = 0;
  let weekdayNameTR = "";
  
  for (const part of parts) {
    if (part.type === "hour") {
      currentHour = parseInt(part.value, 10);
    } else if (part.type === "minute") {
      currentMinute = parseInt(part.value, 10);
    } else if (part.type === "weekday") {
      weekdayNameTR = part.value.toLowerCase();
    }
  }

  const wh = shop.workingHours;

  // 1. Dizi Formatı (Array): [{ day: 'Çarşamba', open: '09:00', close: '23:00', isClosed: false }]
  if (Array.isArray(wh)) {
    const todaySchedule = wh.find((w: any) => 
      w.day?.toLowerCase() === weekdayNameTR || 
      w.day?.toLowerCase() === weekdayNameTR.replace('ı', 'i')
    );

    if (todaySchedule) {
      if (todaySchedule.isClosed) return false;
      if (todaySchedule.open && todaySchedule.close) {
        const [openH, openM] = todaySchedule.open.split(':').map(Number);
        const [closeH, closeM] = todaySchedule.close.split(':').map(Number);

        const currentTotalMins = currentHour * 60 + currentMinute;
        const openTotalMins = openH * 60 + openM;
        let closeTotalMins = closeH * 60 + closeM;

        if (closeTotalMins <= openTotalMins) {
          closeTotalMins += 24 * 60; // Gece yarısını geçen saatler (Örn: 10:00 - 02:00)
        }

        let checkMins = currentTotalMins;
        if (currentTotalMins < openTotalMins && closeTotalMins > 24 * 60) {
          checkMins += 24 * 60;
        }

        if (checkMins < openTotalMins || checkMins >= closeTotalMins) {
          return false;
        }
      }
    }
    return true;
  }

  // 2. Obje Formatı (Object): { wednesday: { isOpen: true, openTime: '09:00', closeTime: '22:00' } }
  if (typeof wh === 'object') {
    const enFormatter = new Intl.DateTimeFormat("en-US", { timeZone: tz, weekday: "long" });
    const enWeekday = enFormatter.format(now).toLowerCase();
    const todaySchedule = wh[enWeekday];

    if (todaySchedule) {
      if (todaySchedule.isOpen === false) return false;
      if (todaySchedule.openTime && todaySchedule.closeTime) {
        const [openH, openM] = todaySchedule.openTime.split(':').map(Number);
        const [closeH, closeM] = todaySchedule.closeTime.split(':').map(Number);

        const currentTotalMins = currentHour * 60 + currentMinute;
        const openTotalMins = openH * 60 + openM;
        let closeTotalMins = closeH * 60 + closeM;

        if (closeTotalMins <= openTotalMins) {
          closeTotalMins += 24 * 60;
        }

        let checkMins = currentTotalMins;
        if (currentTotalMins < openTotalMins && closeTotalMins > 24 * 60) {
          checkMins += 24 * 60;
        }

        if (checkMins < openTotalMins || checkMins >= closeTotalMins) {
          return false;
        }
      }
    }
  }

  return true;
}

function enrichShopWithTags(shop: any) {
  if (!shop) return null;
  const tags: string[] = [];

  // 1. Yeni etiketi (Son 30 gün içinde oluşturulduysa)
  if (shop.createdAt) {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    if (new Date(shop.createdAt) >= thirtyDaysAgo) {
      tags.push("Yeni");
    }
  }

  if (shop.reviewCount > 0) {
    // 2. Hızlı Teslimat (Hız puanı >= 4.5)
    if (shop.avgSpeedRating >= 4.5) {
      tags.push("Hızlı Teslimat");
    }
    // 3. Müşteri Favorisi (Ortalama puan >= 4.7)
    if (shop.averageRating >= 4.7) {
      tags.push("Müşteri Favorisi");
    }
  }

  // 4. Öne Çıkan etiketi (Aktif sponsorluk varsa)
  if (shop.promotions && shop.promotions.length > 0) {
    const hasMainScreen = shop.promotions.some((p: any) => p.promoType === "MAIN_SCREEN");
    const hasCategory = shop.promotions.some((p: any) => p.promoType === "CATEGORY");
    if (hasMainScreen) {
      tags.push("Öne Çıkan (Ana Sayfa)");
    }
    if (hasCategory) {
      tags.push("Öne Çıkan (Kategori)");
    }
  }

  return {
    ...shop,
    isOpen: checkIsOpen(shop),
    tags
  };
}

export class ConsumerShopController {

  // Tüketiciler için sadece AKTİF dükkanları getirir (mesafe filtresi ve onaylı satıcı kontrolü ile)
  async getActiveShops(req: Request, res: Response) {
    try {
      const { latitude, longitude, radius } = req.query;

      // Sadece onaylanmış (ACTIVE) satıcıların aktif (isActive: true) dükkanlarını getir
      const shops = await prisma.shop.findMany({
        where: {
          merchant: {
            status: "ACTIVE" // represents isApproved: true
          }
        },
        include: {
          merchant: { select: { businessName: true, status: true, countryCode: true } },
          promotions: {
            where: {
              isActive: true,
              startDate: { lte: new Date() },
              endDate: { gte: new Date() }
            }
          }
        }
      });

      const enrichedShops = shops.map(enrichShopWithTags);

      // Eğer koordinatlar gönderildiyse mesafe bazlı filtreleme yap (Haversine)
      if (latitude && longitude) {
        const userLat = Number(latitude);
        const userLng = Number(longitude);
        const filterRadius = radius ? Number(radius) : null;

        if (!isNaN(userLat) && !isNaN(userLng)) {
          const shopsWithDistance = enrichedShops.map((shop: any) => {
            const sLat = shop.latitude != null ? Number(shop.latitude) : null;
            const sLng = shop.longitude != null ? Number(shop.longitude) : null;

            if (sLat === null || sLng === null || isNaN(sLat) || isNaN(sLng)) {
              return { ...shop, distanceKm: 0 };
            }

            const R = 6371; // Earth's radius in km
            const dLat = (sLat - userLat) * Math.PI / 180;
            const dLng = (sLng - userLng) * Math.PI / 180;
            const a =
              Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(userLat * Math.PI / 180) * Math.cos(sLat * Math.PI / 180) *
              Math.sin(dLng / 2) * Math.sin(dLng / 2);
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            const distance = Math.round(R * c * 10) / 10;

            return { ...shop, distanceKm: distance };
          });

          // Yarıçap içindeki dükkanları filtrele
          let filteredShops = shopsWithDistance.filter((shop: any) => {
            if (shop.latitude == null || shop.longitude == null) return true;
            const maxRadius = filterRadius || shop.deliveryRadiusKm || 15.0;
            return shop.distanceKm <= maxRadius;
          });

          // Mesafe bazlı yakın dükkanlar ilk sırada
          filteredShops.sort((a: any, b: any) => a.distanceKm - b.distanceKm);

          // FALLBACK SAFEGUARD: Eğer kullanıcının GPS lokasyonu yarıçap dışında kaldığı için 0 dükkan bulunduysa,
          // ekranın boş gelmesini önlemek için tüm dükkanları en yakından uzağa sıralayarak getir.
          if (filteredShops.length === 0) {
            shopsWithDistance.sort((a: any, b: any) => a.distanceKm - b.distanceKm);
            return res.status(200).json({ error: false, data: shopsWithDistance });
          }

          return res.status(200).json({ error: false, data: filteredShops });
        }
      }

      // Fallback: Koordinatlar yoksa tüm dükkanları getir
      return res.status(200).json({ error: false, data: enrichedShops });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Belirli bir dükkanın sadece AKTİF ürünlerini getirir (satıcı aktif olmalı)
  async getShopProducts(req: Request, res: Response) {
    try {
      const shopId = req.params.shopId as string;

      const shop = await prisma.shop.findFirst({
        where: {
          id: shopId,
          merchant: {
            status: "ACTIVE"
          }
        }
      });

      if (!shop) {
        return res.status(404).json({ error: true, message: "Aktif dükkan bulunamadı veya kapalı." });
      }

      const products = await prisma.product.findMany({
        where: {
          shopId: shop.id,
          isActive: true
        },
        include: {
          category: {
            include: {
              parent: true
            }
          },
          unit: true,
          brand: true,
          globalProduct: true,
          optionGroups: {
            include: {
              options: true
            }
          }
        },
        orderBy: { createdAt: 'desc' }
      });

      const enrichedProducts = products
        .map(formatProduct)
        .filter((p: any) => {
          const trackStock = p.trackStock ?? false;
          const stockQuantity = p.stockQuantity ?? 0;
          return (trackStock === false) || (stockQuantity > 0);
        });

      return res.status(200).json({ error: false, data: enrichedProducts });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Sadece seçili dükkana (shopId) ait aktif olarak satılan ürünlerin bağlı olduğu kategori ve alt kategorileri dinamik olarak hiyerarşik ağaç yapısında getirir
  async getShopActiveCategories(req: Request, res: Response) {
    try {
      const shopId = req.params.shopId as string;

      const shop = await prisma.shop.findUnique({
        where: { id: shopId }
      });
      const shopType = shop ? shop.type : "MARKET";

      // 🚨 HIYERARŞİK SQL SORGUSU (Prisma):
      // 1. Sadece bu dükkanda aktif ürünü olan kategorileri bul.
      const activeCategoriesWithProducts = await prisma.category.findMany({
        where: {
          products: { some: { shopId: shopId, isActive: true } }
        },
        select: { id: true }
      });

      const activeCategoryIds = activeCategoriesWithProducts.map(c => c.id);

      // Kök kategorileri çekip sadece aktif çocukları içerecek şekilde ağacı oluşturuyoruz
      const categoryTree = await prisma.category.findMany({
        where: {
          parentId: null, // Sadece en üst seviye (Root) kategoriler
          shopType: shopType // İlgili dükkan tipine göre (Örn: MARKET, RESTAURANT)
        },
        include: {
          children: {
            include: {
              children: true // Gerekirse 3. seviye derinlik
            }
          }
        },
        orderBy: { name: "asc" }
      });

      // Yardımcı fonksiyon: Ağacın bu dalında veya alt kollarında aktif ürün var mı?
      const hasActiveProductInBranch = (node: any, activeIds: string[]): boolean => {
        if (activeIds.includes(node.id)) return true;
        if (node.children && node.children.length > 0) {
          return node.children.some((child: any) => hasActiveProductInBranch(child, activeIds));
        }
        return false;
      };

      // Filtreleme: Sadece içinde aktif ürün olan veya alt kırılımlarında aktif ürün barındıran dalları tut
      const filteredTree = categoryTree.filter(node => {
        return hasActiveProductInBranch(node, activeCategoryIds);
      });

      // Map ve formatlama: İstemciye geri uyumluluk için alt kırılımları zenginleştiriyoruz
      const formatCategoryNode = (node: any): any => {
        const childNodes = (node.children || [])
          .filter((child: any) => hasActiveProductInBranch(child, activeCategoryIds))
          .map((child: any) => formatCategoryNode(child));

        return {
          id: node.id,
          name: node.name,
          shopType: node.shopType,
          iconName: node.imageUrl,
          iconUrl: node.imageUrl,
          imageUrl: node.imageUrl,
          color: node.color,
          parentId: node.parentId,
          children: childNodes
        };
      };

      const formatted = filteredTree.map(node => formatCategoryNode(node));

      return res.status(200).json({ error: false, data: formatted });
    } catch (error: any) {
      console.error("Hiyerarşik kategori ağacı hatası:", error);
      return res.status(500).json({ error: true, message: "Kategori ağacı oluşturulurken hata oluştu." });
    }
  }

  // Tüm aktif kampanyaları getirir
  async getCampaigns(req: Request, res: Response) {
    try {
      const campaigns = await prisma.campaign.findMany({
        where: { isActive: true }
      });
      return res.status(200).json({ error: false, data: campaigns });
    } catch (error: any) {
      console.error("Kampanyalar çekilemedi:", error);
      return res.status(500).json({ error: true, message: error.message || "Kampanyalar listelenirken hata oluştu." });
    }
  }

  // Global Arama: Kategori, Dükkan ve Ürünleri arar
  async globalSearch(req: Request, res: Response) {
    try {
      const q = req.query.q as string || "";
      if (!q.trim()) {
        return res.status(200).json({ error: false, data: { categories: [], shops: [], products: [] } });
      }

      // 1. İşletme Kategorilerini Ara
      const categories = await prisma.businessCategory.findMany({
        where: {
          isActive: true,
          name: { contains: q, mode: "insensitive" }
        },
        orderBy: { order: "asc" }
      });

      // 2. Dükkanları Ara
      const shops = await prisma.shop.findMany({
        where: {
          merchant: { status: "ACTIVE" },
          OR: [
            { name: { contains: q, mode: "insensitive" } },
            { description: { contains: q, mode: "insensitive" } }
          ]
        },
        include: {
          merchant: { select: { businessName: true, status: true, countryCode: true } }
        }
      });
      const enrichedShops = shops.map(enrichShopWithTags);

      // 3. Ürünleri Ara
      const products = await prisma.product.findMany({
        where: {
          isActive: true,
          shop: { merchant: { status: "ACTIVE" } },
          OR: [
            { name: { contains: q, mode: "insensitive" } },
            { description: { contains: q, mode: "insensitive" } },
            { brand: { name: { contains: q, mode: "insensitive" } } }
          ]
        },
        include: {
          category: { include: { parent: true } },
          unit: true,
          brand: true,
          globalProduct: true,
          optionGroups: { include: { options: true } }
        },
        take: 30
      });

      const formattedProducts = products.map(formatProduct);

      // Kategori resimlerinin önüne dinamik base URL ekle
      const protocol = req.headers["x-forwarded-proto"] || req.protocol;
      const baseUrl = `${protocol}://${req.get("host")}`;
      const formattedCategories = categories.map(cat => {
        let imageUrl = cat.imageUrl;
        if (imageUrl && imageUrl.startsWith("/")) {
          imageUrl = `${baseUrl}${imageUrl}`;
        }
        return { ...cat, imageUrl };
      });

      return res.status(200).json({
        error: false,
        data: {
          categories: formattedCategories,
          shops: enrichedShops,
          products: formattedProducts
        }
      });
    } catch (error: any) {
      console.error("Global arama hatası:", error);
      return res.status(500).json({ error: true, message: error.message || "Arama yapılırken hata oluştu." });
    }
  }
}

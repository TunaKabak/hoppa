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
    categoryId: cat ? cat.id : null
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
          merchant: { select: { businessName: true, status: true } }
        }
      });

      // Eğer koordinatlar gönderildiyse mesafe bazlı filtreleme yap (Haversine)
      if (latitude && longitude) {
        const userLat = Number(latitude);
        const userLng = Number(longitude);
        const filterRadius = radius ? Number(radius) : null;

        if (!isNaN(userLat) && !isNaN(userLng)) {
          const filteredShops = shops.filter(shop => {
            // Lokasyonu girilmemiş dükkanlar için fallback olarak her durumda göster
            if (shop.latitude === null || shop.longitude === null) {
              return true;
            }

            // Haversine formülü ile mesafe hesabı (km cinsinden)
            const R = 6371; // Earth's radius in km
            const dLat = (shop.latitude - userLat) * Math.PI / 180;
            const dLng = (shop.longitude - userLng) * Math.PI / 180;
            const a =
              Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(userLat * Math.PI / 180) * Math.cos(shop.latitude * Math.PI / 180) *
              Math.sin(dLng / 2) * Math.sin(dLng / 2);
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            const distance = R * c;

            // Dükkanın teslimat yarıçapı (varsayılan 5 km)
            const maxRadius = filterRadius || shop.deliveryRadiusKm || 5.0;
            return distance <= maxRadius;
          });

          return res.status(200).json({ error: false, data: filteredShops });
        }
      }

      // Fallback: Koordinatlar yoksa veya geçersizse tüm dükkanları getir
      return res.status(200).json({ error: false, data: shops });
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
          globalProduct: true
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
}

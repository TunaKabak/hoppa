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

  // Sadece seçili dükkana (shopId) ait aktif olarak satılan ürünlerin bağlı olduğu kategori ve alt kategorileri dinamik olarak getirir
  async getShopActiveCategories(req: Request, res: Response) {
    try {
      const shopId = req.params.shopId as string;

      const categories = await prisma.category.findMany({
        where: {
          parentId: null, // Only root categories
          OR: [
            {
              products: {
                some: { 
                  shopId: shopId,
                  isActive: true
                }
              }
            },
            {
              children: {
                some: {
                  products: {
                    some: { 
                      shopId: shopId,
                      isActive: true
                    }
                  }
                }
              }
            }
          ]
        },
        include: {
          children: {
            where: {
              products: { 
                some: { 
                  shopId: shopId,
                  isActive: true
                } 
              }
            }
          }
        },
        orderBy: { name: "asc" }
      });

      // Map new 3NF self-referential Category relation to old children list format for client backward compatibility
      const formatted = (categories as any[]).map(cat => ({
        id: cat.id,
        name: cat.name,
        shopType: cat.shopType,
        iconName: cat.imageUrl, 
        iconUrl: cat.imageUrl,
        imageUrl: cat.imageUrl,
        color: cat.color,
        parent: null,
        children: (cat.children || []).map((sub: any) => ({
          id: sub.id,
          name: sub.name,
          categoryId: sub.parentId,
          imageUrl: sub.imageUrl,
          color: sub.color,
          parent: {
            id: cat.id,
            name: cat.name,
            shopType: cat.shopType,
            imageUrl: cat.imageUrl
          },
          children: []
        }))
      }));

      return res.status(200).json({ error: false, data: formatted });
    } catch (error: any) {
      console.error("Dinamik kategori çekme hatası:", error);
      return res.status(500).json({ error: true, message: "Kategoriler getirilirken hata oluştu." });
    }
  }
}

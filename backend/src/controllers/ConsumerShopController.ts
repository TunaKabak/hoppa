import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

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
          }
        },
        orderBy: { createdAt: 'desc' }
      });

      return res.status(200).json({ error: false, data: products });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

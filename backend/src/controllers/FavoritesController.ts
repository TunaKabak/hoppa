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

export class FavoritesController {
  
  // 1. Favori Ürünleri Listeleme (Dinamik 3NF JOIN ve Görsel Fallback Destekli)
  public async getFavoriteProducts(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      let products: any[] = [];

      // Eğer POST ile productIds dizisi gönderildiyse geriye dönük uyumluluk için oradan çek
      if (req.method === "POST" && req.body.productIds && Array.isArray(req.body.productIds)) {
        const { productIds } = req.body;
        if (productIds.length > 0) {
          products = await prisma.product.findMany({
            where: {
              id: { in: productIds }
            },
            include: {
              unit: true,
              brand: true,
              category: {
                include: { parent: true }
              },
              globalProduct: true,
              shop: {
                include: {
                  merchant: true
                }
              }
            }
          });
        }
      } else {
        // Aksi takdirde kullanıcının 3NF ilişkisel tablodaki favorilerini çek
        const favoriteRecords = await prisma.favoriteProduct.findMany({
          where: { userId },
          include: {
            product: {
              include: {
                unit: true,
                brand: true,
                category: {
                  include: { parent: true }
                },
                globalProduct: true,
                shop: {
                  include: {
                    merchant: true
                  }
                }
              }
            }
          }
        });
        products = favoriteRecords.map(fav => fav.product).filter(Boolean);
      }

      const results = products.map(p => {
        // Tüketici tarafına gönderilirken 'isAvailable' hesaplanmalı
        // Dükkan açık mı? isActive=true ve merchant status=ACTIVE olmalı.
        const isAvailable = !!(p.shop && p.shop.isActive && p.shop.merchant?.status === "ACTIVE");

        return {
          product: formatProduct(p),
          isAvailable
        };
      });

      res.status(200).json({ error: false, data: results });
    } catch (error: any) {
      console.error("Favori ürünler çekilemedi:", error);
      res.status(500).json({ error: true, message: error.message || "Favori ürünler listelenirken hata oluştu." });
    }
  }

  // 2. Ürünü Favoriye Ekleme / Çıkarma (Toggle)
  public async toggleFavoriteProduct(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { productId } = req.body;

      if (!productId) {
        res.status(400).json({ error: true, message: "productId alanı zorunludur." });
        return;
      }

      // Zaten favoride mi kontrol et
      const existing = await prisma.favoriteProduct.findUnique({
        where: {
          userId_productId: { userId, productId }
        }
      });

      if (existing) {
        // Varsa favorilerden kaldır
        await prisma.favoriteProduct.delete({
          where: {
            userId_productId: { userId, productId }
          }
        });
        res.status(200).json({ error: false, isFavorite: false, message: "Ürün favorilerden çıkarıldı." });
      } else {
        // Yoksa favorilere ekle
        await prisma.favoriteProduct.create({
          data: { userId, productId }
        });
        res.status(200).json({ error: false, isFavorite: true, message: "Ürün favorilere eklendi." });
      }
    } catch (error: any) {
      console.error("Favori toggle işlemi başarısız:", error);
      res.status(500).json({ error: true, message: error.message || "İşlem gerçekleştirilirken hata oluştu." });
    }
  }
}

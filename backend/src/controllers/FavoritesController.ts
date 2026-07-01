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

      const favoriteRecords = await prisma.favoriteProduct.findMany({
        where: { userId },
        include: {
          product: {
            include: {
              unit: true,
              brand: true,
              category: true,
              globalProduct: true, // Görsel fallback için master ürün dahil edilmelidir!
            }
          }
        }
      });

      const products = favoriteRecords.map(fav => {
        const prod = fav.product;
        return {
          id: prod.id,
          name: prod.name,
          price: prod.price,
          regularPrice: prod.regularPrice,
          discountRate: prod.discountRate,
          // Görsel fallback kuralı:
          imageUrl: prod.imageUrl || prod.globalProduct?.imageUrl || "/images/default-product.png",
          unit: prod.unit, // İlişkisel birim nesnesi
          minQuantity: prod.minQuantity,
          stepSize: prod.stepSize,
          shopId: prod.shopId,
        };
      });

      res.status(200).json({ error: false, data: products });
    } catch (error) {
      console.error("Favori ürünler çekilemedi:", error);
      res.status(500).json({ error: true, message: "İşlem sırasında bir hata oluştu." });
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

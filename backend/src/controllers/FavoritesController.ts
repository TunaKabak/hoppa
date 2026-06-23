import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class FavoritesController {
  
  // Tüketici tarafından gönderilen favori ürün ID'lerine göre Prisma'dan ürünleri ve dükkan uygunluğunu çeker
  async getFavoriteProducts(req: Request, res: Response) {
    try {
      const { productIds } = req.body;

      if (!productIds || !Array.isArray(productIds) || productIds.length === 0) {
        return res.status(200).json({ error: false, data: [] });
      }

      // Ürünleri shop, merchant ve category bilgileriyle birlikte çek
      const products = await prisma.product.findMany({
        where: {
          id: { in: productIds }
        },
        include: {
          shop: {
            include: {
              merchant: true
            }
          },
          category: {
            include: {
              parent: true
            }
          }
        }
      });

      // Enrich with GlobalProduct categories if category is missing
      const barcodes = products.map(p => p.barcode).filter(Boolean) as string[];
      let globalProducts: any[] = [];
      if (barcodes.length > 0) {
        globalProducts = await prisma.globalProduct.findMany({
          where: { barcode: { in: barcodes } }
        });
      }

      const results = products.map(p => {
        // Kategori düzenlemesi (ConsumerShopController'daki mantık)
        let catObj = p.category as any;
        if (!catObj && p.barcode) {
          const gp = globalProducts.find(g => g.barcode === p.barcode);
          if (gp) {
            catObj = {
              name: gp.subCategory || gp.category,
              parent: gp.subCategory ? { name: gp.category } : null
            };
          }
        }

        // Tüketici tarafına gönderilirken 'isAvailable' hesaplanmalı
        // Dükkan açık mı? isActive=true ve merchant status=ACTIVE olmalı.
        // Ayrıca mesai saatleri içinde mi diye de bakılabilir, şimdilik aktiflik yeterli.
        const isAvailable = p.shop && p.shop.isActive && p.shop.merchant.status === "ACTIVE";

        return {
          product: {
            ...p,
            category: catObj
          },
          isAvailable
        };
      });

      return res.status(200).json({ error: false, data: results });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

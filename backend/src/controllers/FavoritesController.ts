import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

function formatProduct(product: any) {
  if (!product) return null;
  return {
    ...product,
    unit: product.unit ? product.unit.code : "ADET",
    brand: product.brand ? product.brand.name : null,
    imageUrl: product.imageUrl || product.globalProduct?.imageUrl || "/images/default-product.png",
    category: product.subCategory ? {
      id: product.subCategory.id,
      name: product.subCategory.name,
      parent: product.category ? {
        id: product.category.id,
        name: product.category.name,
        shopType: product.category.shopType
      } : null
    } : (product.category ? {
      id: product.category.id,
      name: product.category.name,
      parent: null
    } : null),
    categoryId: product.subCategory ? product.subCategory.id : product.categoryId
  };
}

export class FavoritesController {
  
  // Tüketici tarafından gönderilen favori ürün ID'lerine göre Prisma'dan ürünleri ve dükkan uygunluğunu çeker
  async getFavoriteProducts(req: Request, res: Response) {
    try {
      const { productIds } = req.body;

      if (!productIds || !Array.isArray(productIds) || productIds.length === 0) {
        return res.status(200).json({ error: false, data: [] });
      }

      // Ürünleri shop, merchant ve ilişkisel kategori/unit/brand bilgileriyle birlikte çek
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
          category: true,
          subCategory: true,
          unit: true,
          brand: true,
          globalProduct: true
        }
      });

      const results = products.map(p => {
        // Tüketici tarafına gönderilirken 'isAvailable' hesaplanmalı
        // Dükkan açık mı? isActive=true ve merchant status=ACTIVE olmalı.
        const isAvailable = !!(p.shop && p.shop.isActive && p.shop.merchant.status === "ACTIVE");

        return {
          product: formatProduct(p),
          isAvailable
        };
      });

      return res.status(200).json({ error: false, data: results });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

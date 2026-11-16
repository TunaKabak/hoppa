import { Request, Response } from "express";
import { randomUUID } from "crypto";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class CategoryController {
  async getCategories(req: Request, res: Response) {
    try {
      const { shopType } = req.query;
      
      const categories = await prisma.category.findMany({
        where: {
          shopType: shopType ? (shopType as string) : undefined,
          parentId: null, // Only root categories
        },
        include: {
          children: true,
        },
        orderBy: { name: "asc" },
      });

      // Map self-referential children relation to old format for client backward compatibility
      const formatted = categories.map(cat => ({
        id: cat.id,
        name: cat.name,
        shopType: cat.shopType,
        iconUrl: cat.imageUrl,
        imageUrl: cat.imageUrl,
        parent: null,
        children: (cat.children || []).map(sub => ({
          id: sub.id,
          name: sub.name,
          categoryId: sub.parentId,
          imageUrl: sub.imageUrl,
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
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async getMerchantCategories(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      let shopType = req.query.shopType as string | undefined;

      if (merchantId && !shopType) {
        const shop = await prisma.shop.findUnique({ where: { merchantId } });
        if (shop) {
          shopType = shop.type;
        }
      }

      const categories = await prisma.category.findMany({
        where: shopType ? { shopType } : undefined,
        include: {
          children: true,
          parent: true,
          _count: { select: { products: true } }
        },
        orderBy: { name: "asc" }
      });

      return res.status(200).json({ error: false, data: categories });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async createMerchantCategory(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId },
        select: { id: true, type: true }
      });
      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const name = typeof req.body?.name === "string" ? req.body.name.trim() : "";
      const parentId = typeof req.body?.parentId === "string" && req.body.parentId.trim().length > 0
        ? req.body.parentId.trim()
        : null;
      const color = typeof req.body?.color === "string" && req.body.color.trim().length > 0
        ? req.body.color.trim()
        : null;
      const imageUrl = typeof req.body?.imageUrl === "string" && req.body.imageUrl.trim().length > 0
        ? req.body.imageUrl.trim()
        : null;

      if (name.length < 2 || name.length > 80) {
        return res.status(400).json({ error: true, message: "Kategori adı 2 ile 80 karakter arasında olmalıdır." });
      }

      if (parentId) {
        const parentExists = await prisma.category.findUnique({ where: { id: parentId }, select: { id: true } });
        if (!parentExists) {
          return res.status(400).json({ error: true, message: "Seçilen üst kategori bulunamadı." });
        }
      }

      const created = await prisma.category.create({
        data: {
          id: randomUUID(),
          name,
          shopType: shop.type,
          parentId,
          color,
          imageUrl
        },
        include: {
          children: true,
          parent: true,
          _count: { select: { products: true } }
        }
      });

      return res.status(201).json({
        error: false,
        message: "Menü kategorisi oluşturuldu.",
        data: created
      });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Kategori oluşturulamadı.";
      console.error("[CategoryController.createMerchantCategory] Error:", error);
      return res.status(500).json({ error: true, message });
    }
  }

  async updateMerchantCategory(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });
      }

      const categoryId = req.params.id as string;
      const existing = await prisma.category.findUnique({ where: { id: categoryId } });
      if (!existing) {
        return res.status(404).json({ error: true, message: "Kategori bulunamadı." });
      }

      const updateData: {
        name?: string;
        color?: string | null;
        imageUrl?: string | null;
        parentId?: string | null;
      } = {};

      if (req.body?.name !== undefined) {
        const trimmedName = typeof req.body.name === "string" ? req.body.name.trim() : "";
        if (trimmedName.length < 2 || trimmedName.length > 80) {
          return res.status(400).json({ error: true, message: "Kategori adı 2 ile 80 karakter arasında olmalıdır." });
        }
        updateData.name = trimmedName;
      }

      if (req.body?.color !== undefined) {
        updateData.color = typeof req.body.color === "string" && req.body.color.trim() ? req.body.color.trim() : null;
      }

      if (req.body?.imageUrl !== undefined) {
        updateData.imageUrl = typeof req.body.imageUrl === "string" && req.body.imageUrl.trim() ? req.body.imageUrl.trim() : null;
      }

      if (req.body?.parentId !== undefined) {
        const nextParentId = typeof req.body.parentId === "string" && req.body.parentId.trim() ? req.body.parentId.trim() : null;
        if (nextParentId === categoryId) {
          return res.status(400).json({ error: true, message: "Bir kategori kendisinin alt kategorisi olamaz." });
        }
        if (nextParentId) {
          const parentExists = await prisma.category.findUnique({ where: { id: nextParentId }, select: { id: true } });
          if (!parentExists) {
            return res.status(400).json({ error: true, message: "Üst kategori bulunamadı." });
          }
        }
        updateData.parentId = nextParentId;
      }

      const updated = await prisma.category.update({
        where: { id: categoryId },
        data: updateData,
        include: {
          children: true,
          parent: true,
          _count: { select: { products: true } }
        }
      });

      return res.status(200).json({
        error: false,
        message: "Kategori güncellendi.",
        data: updated
      });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Kategori güncellenemedi.";
      console.error("[CategoryController.updateMerchantCategory] Error:", error);
      return res.status(500).json({ error: true, message });
    }
  }

  async deleteMerchantCategory(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });
      }

      const categoryId = req.params.id as string;
      const existing = await prisma.category.findUnique({ where: { id: categoryId } });
      if (!existing) {
        return res.status(404).json({ error: true, message: "Kategori bulunamadı." });
      }

      const [productCount, childCount] = await Promise.all([
        prisma.product.count({ where: { categoryId } }),
        prisma.category.count({ where: { parentId: categoryId } })
      ]);

      if (productCount > 0) {
        return res.status(400).json({
          error: true,
          message: `Bu kategoride ${productCount} adet ürün bulunuyor. Silmeden önce ürünleri başka bir kategoriye taşıyın.`
        });
      }

      if (childCount > 0) {
        return res.status(400).json({
          error: true,
          message: `Bu kategoriye bağlı ${childCount} adet alt kategori bulunuyor. Önce alt kategorileri kaldırın.`
        });
      }

      await prisma.category.delete({ where: { id: categoryId } });
      return res.status(200).json({ error: false, message: "Kategori silindi." });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Kategori silinemedi.";
      console.error("[CategoryController.deleteMerchantCategory] Error:", error);
      return res.status(500).json({ error: true, message });
    }
  }
}


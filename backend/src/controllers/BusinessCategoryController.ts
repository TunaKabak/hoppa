import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

function getShopTypeForCategory(catName: string): string | null {
  const norm = catName.toLowerCase();
  if (norm.includes("restoran") || norm.includes("restaurant")) return "RESTAURANT";
  if (norm.includes("market")) return "MARKET";
  if (norm.includes("su")) return "WATER";
  if (norm.includes("çiçek") || norm.includes("flower")) return "FLOWER";
  if (norm.includes("manav") || norm.includes("greengrocer")) return "GREENGROCER";
  if (norm.includes("kasap") || norm.includes("butcher")) return "BUTCHER";
  return null;
}

async function enrichCategoryWithMetrics(cat: any) {
  const shopType = getShopTypeForCategory(cat.name);
  if (!shopType) {
    return {
      ...cat,
      shopCount: 0
    };
  }

  const shops = await prisma.shop.findMany({
    where: { type: shopType as any },
    select: { id: true, createdAt: true }
  });
  const shopIds = shops.map(s => s.id);
  const shopCount = shops.length;

  // 1. Calculate Average Delivery Time from Delivered Orders
  const orders = await prisma.order.findMany({
    where: {
      shopId: { in: shopIds },
      status: "DELIVERED"
    },
    select: {
      createdAt: true,
      updatedAt: true
    }
  });

  let avgDeliveryTime = cat.avgDeliveryTime || "30-45 dk";
  if (orders.length > 0) {
    const totalMinutes = orders.reduce((sum, o) => {
      const diffMs = o.updatedAt.getTime() - o.createdAt.getTime();
      const diffMins = Math.max(1, Math.round(diffMs / 60000));
      return sum + diffMins;
    }, 0);
    const avgMinutes = Math.round(totalMinutes / orders.length);
    const rounded = Math.round(avgMinutes / 5) * 5;
    const minTime = Math.max(10, rounded - 5);
    const maxTime = rounded + 5;
    avgDeliveryTime = `${minTime}-${maxTime} dk`;
  }

  // 2. Calculate Badge standard rules
  const oneWeekAgo = new Date();
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
  const hasNewShop = shops.some(s => s.createdAt >= oneWeekAgo);

  let badge = cat.badge || null;
  if (hasNewShop) {
    badge = "yeni";
  } else {
    const oneMonthAgo = new Date();
    oneMonthAgo.setDate(oneMonthAgo.getDate() - 30);
    const orderCount = await prisma.order.count({
      where: {
        shopId: { in: shopIds },
        status: "DELIVERED",
        createdAt: { gte: oneMonthAgo }
      }
    });
    if (orderCount > 10) {
      badge = "popüler";
    }
  }

  return {
    ...cat,
    avgDeliveryTime,
    badge,
    shopCount
  };
}

export class BusinessCategoryController {
  // Consumer-facing: Get only active business categories
  async getBusinessCategories(req: Request, res: Response) {
    try {
      const categories = await prisma.businessCategory.findMany({
        where: { isActive: true },
        orderBy: { order: "asc" },
      });

      const enriched = await Promise.all(categories.map(c => enrichCategoryWithMetrics(c)));
      return res.status(200).json({ error: false, data: enriched });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Admin-facing: Get all business categories (including inactive ones)
  async adminGetBusinessCategories(req: Request, res: Response) {
    try {
      const categories = await prisma.businessCategory.findMany({
        orderBy: { order: "asc" },
      });

      const enriched = await Promise.all(categories.map(c => enrichCategoryWithMetrics(c)));
      return res.status(200).json({ error: false, data: enriched });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Admin-facing: Create a new category
  async adminCreateBusinessCategory(req: Request, res: Response) {
    try {
      const { name, icon, color, badge, avgDeliveryTime, subtitle, isActive, order } = req.body;
      
      if (!name || !icon || !color) {
        return res.status(400).json({ error: true, message: "Kategori adı, ikon ve renk alanları zorunludur." });
      }

      // Check uniqueness
      const existing = await prisma.businessCategory.findUnique({
        where: { name }
      });
      if (existing) {
        return res.status(400).json({ error: true, message: "Bu isimde bir kategori zaten mevcut." });
      }

      const category = await prisma.businessCategory.create({
        data: {
          name,
          icon,
          color,
          badge: badge || null,
          avgDeliveryTime: avgDeliveryTime || null,
          subtitle: subtitle || null,
          isActive: isActive !== undefined ? isActive : true,
          order: order !== undefined ? Number(order) : 0,
        }
      });

      return res.status(201).json({ error: false, data: category });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Admin-facing: Update category details or status
  async adminUpdateBusinessCategory(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const { name, icon, color, badge, avgDeliveryTime, subtitle, isActive, order } = req.body;

      const category = await prisma.businessCategory.findUnique({
        where: { id }
      });
      if (!category) {
        return res.status(404).json({ error: true, message: "Kategori bulunamadı." });
      }

      if (name && name !== category.name) {
        const existing = await prisma.businessCategory.findUnique({
          where: { name }
        });
        if (existing) {
          return res.status(400).json({ error: true, message: "Bu isimde bir kategori zaten mevcut." });
        }
      }

      const updated = await prisma.businessCategory.update({
        where: { id },
        data: {
          name: name ?? undefined,
          icon: icon ?? undefined,
          color: color ?? undefined,
          badge: badge === null ? null : (badge ?? undefined),
          avgDeliveryTime: avgDeliveryTime === null ? null : (avgDeliveryTime ?? undefined),
          subtitle: subtitle === null ? null : (subtitle ?? undefined),
          isActive: isActive !== undefined ? isActive : undefined,
          order: order !== undefined ? Number(order) : undefined,
        }
      });

      return res.status(200).json({ error: false, data: updated });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Admin-facing: Delete category
  async adminDeleteBusinessCategory(req: Request, res: Response) {
    try {
      const id = req.params.id as string;

      const category = await prisma.businessCategory.findUnique({
        where: { id }
      });
      if (!category) {
        return res.status(404).json({ error: true, message: "Kategori bulunamadı." });
      }

      // Check if any business is associated with this category
      const shopType = getShopTypeForCategory(category.name);
      if (shopType) {
        const shopCount = await prisma.shop.count({
          where: { type: shopType as any }
        });
        if (shopCount > 0) {
          return res.status(400).json({
            error: true,
            message: `Bu kategoriye bağlı ${shopCount} adet işletme bulunmaktadır. Bağlı işletmeler varken kategori silinemez.`
          });
        }
      }

      await prisma.businessCategory.delete({
        where: { id }
      });

      return res.status(200).json({ error: false, message: "Kategori başarıyla silindi." });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Admin-facing: Reorder categories
  async adminReorderBusinessCategories(req: Request, res: Response) {
    try {
      const { orders } = req.body;
      if (!Array.isArray(orders)) {
        return res.status(400).json({ error: true, message: "Geçersiz sıralama bilgisi." });
      }

      await prisma.$transaction(
        orders.map((o: any) => prisma.businessCategory.update({
          where: { id: o.id },
          data: { order: Number(o.order) }
        }))
      );

      return res.status(200).json({ error: false, message: "Kategori sıralaması başarıyla güncellendi." });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

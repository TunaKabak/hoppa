import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class BusinessCategoryController {
  // Consumer-facing: Get only active business categories
  async getBusinessCategories(req: Request, res: Response) {
    try {
      const categories = await prisma.businessCategory.findMany({
        where: { isActive: true },
        orderBy: { order: "asc" },
      });
      return res.status(200).json({ error: false, data: categories });
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
      return res.status(200).json({ error: false, data: categories });
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
      const { id } = req.params;
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
      const { id } = req.params;

      const category = await prisma.businessCategory.findUnique({
        where: { id }
      });
      if (!category) {
        return res.status(404).json({ error: true, message: "Kategori bulunamadı." });
      }

      await prisma.businessCategory.delete({
        where: { id }
      });

      return res.status(200).json({ error: false, message: "Kategori başarıyla silindi." });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

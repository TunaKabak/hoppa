import { Request, Response } from "express";
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
}

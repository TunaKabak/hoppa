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
        },
        include: {
          subCategories: true,
        },
        orderBy: { name: "asc" },
      });

      // Map new 3NF SubCategory relation to old children list format for client backward compatibility
      const formatted = categories.map(cat => ({
        id: cat.id,
        name: cat.name,
        shopType: cat.shopType,
        iconUrl: cat.iconUrl,
        parent: null,
        children: cat.subCategories.map(sub => ({
          id: sub.id,
          name: sub.name,
          categoryId: sub.categoryId,
          parent: {
            id: cat.id,
            name: cat.name,
            shopType: cat.shopType
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

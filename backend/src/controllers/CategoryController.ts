import { Request, Response } from "express";
import { PrismaClient, ShopType } from "@prisma/client";

const prisma = new PrismaClient();

export class CategoryController {
  async getCategories(req: Request, res: Response) {
    try {
      const { shopType } = req.query;
      
      const categories = await prisma.category.findMany({
        where: {
          shopType: shopType ? (shopType as ShopType) : undefined,
        },
        include: {
          parent: true,
          children: true,
        },
        orderBy: { name: "asc" },
      });

      return res.status(200).json({ error: false, data: categories });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class ProductController {
  
  // Sadece satıcının kendi ürünlerini getirir
  async getProductsByShop(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Yetkisiz erişim" });

      const shop = await prisma.shop.findUnique({ where: { merchantId } });
      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı" });

      const products = await prisma.product.findMany({
        where: { shopId: shop.id },
        orderBy: { createdAt: 'desc' }
      });

      return res.status(200).json({ error: false, data: products });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async createProduct(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Yetkisiz erişim" });

      const shop = await prisma.shop.findUnique({ where: { merchantId } });
      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı" });

      const { 
        name, description, price, discountPrice, stock, imageUrl, categoryId, categoryName,
        barcode, brand, stockQuantity, weightOrVolume, preparationTime, hasDeposit, depositPrice,
        unit, minQuantity, stepSize
      } = req.body;

      // Smart Validation: Eğer dükkan MARKET kategorisindeyse ve barcode boşsa 400 hatası dön
      if (shop.type === "MARKET" && (!barcode || barcode.trim() === "")) {
        return res.status(400).json({ error: true, message: "Market ürünleri için barkod zorunludur." });
      }

      let resolvedCategoryId = categoryId;
      if (categoryName && categoryName.trim() !== "") {
        let category = await prisma.category.findFirst({
          where: { name: { equals: categoryName.trim(), mode: "insensitive" } }
        });
        if (!category) {
          category = await prisma.category.create({
            data: { name: categoryName.trim() }
          });
        }
        resolvedCategoryId = category.id;
      } else if (categoryId && !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(categoryId)) {
        let category = await prisma.category.findFirst({
          where: { name: { equals: categoryId.trim(), mode: "insensitive" } }
        });
        if (!category) {
          category = await prisma.category.create({
            data: { name: categoryId.trim() }
          });
        }
        resolvedCategoryId = category.id;
      }

      const parsedStock = stock !== null && stock !== undefined && stock !== "" ? parseInt(stock.toString()) : null;
      const parsedStockQty = stockQuantity !== null && stockQuantity !== undefined && stockQuantity !== "" ? parseInt(stockQuantity.toString()) : (parsedStock || 0);
      const parsedPrepTime = preparationTime !== null && preparationTime !== undefined && preparationTime !== "" ? parseInt(preparationTime.toString()) : null;
      const parsedDepositPrice = depositPrice !== null && depositPrice !== undefined && depositPrice !== "" ? parseFloat(depositPrice.toString()) : null;
      const parsedHasDeposit = hasDeposit === true || hasDeposit === "true";
      const parsedMinQuantity = minQuantity !== null && minQuantity !== undefined && minQuantity !== "" ? parseFloat(minQuantity.toString()) : 1.0;
      const parsedStepSize = stepSize !== null && stepSize !== undefined && stepSize !== "" ? parseFloat(stepSize.toString()) : 1.0;

      const product = await prisma.product.create({
        data: {
          shopId: shop.id,
          name,
          description,
          price,
          discountPrice,
          stock: parsedStock,
          imageUrl,
          categoryId: resolvedCategoryId || null,
          isActive: true,
          barcode: barcode || null,
          brand: brand || null,
          stockQuantity: parsedStockQty,
          weightOrVolume: weightOrVolume || null,
          preparationTime: parsedPrepTime,
          hasDeposit: parsedHasDeposit,
          depositPrice: parsedDepositPrice,
          unit: unit || "ADET",
          minQuantity: parsedMinQuantity,
          stepSize: parsedStepSize
        }
      });

      return res.status(201).json({ error: false, data: product });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async updateProduct(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      const productId = req.params.id as string;
      
      const shop = await prisma.shop.findUnique({ where: { merchantId } });
      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı" });

      // Ürünün bu dükkana ait olduğunu doğrula
      const existingProduct = await prisma.product.findUnique({ where: { id: productId } });
      if (!existingProduct || existingProduct.shopId !== shop.id) {
        return res.status(403).json({ error: true, message: "Ürün bulunamadı veya yetkiniz yok." });
      }

      const { 
        name, description, price, discountPrice, stock, imageUrl, isActive, categoryId, categoryName,
        barcode, brand, stockQuantity, weightOrVolume, preparationTime, hasDeposit, depositPrice,
        unit, minQuantity, stepSize
      } = req.body;

      // Smart Validation: Eğer dükkan MARKET kategorisindeyse ve barcode boşsa 400 hatası dön
      if (shop.type === "MARKET" && (!barcode || barcode.trim() === "")) {
        return res.status(400).json({ error: true, message: "Market ürünleri için barkod zorunludur." });
      }

      let resolvedCategoryId = categoryId;
      if (categoryName !== undefined) {
        if (categoryName && categoryName.trim() !== "") {
          let category = await prisma.category.findFirst({
            where: { name: { equals: categoryName.trim(), mode: "insensitive" } }
          });
          if (!category) {
            category = await prisma.category.create({
              data: { name: categoryName.trim() }
            });
          }
          resolvedCategoryId = category.id;
        } else {
          resolvedCategoryId = null;
        }
      } else if (categoryId && !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(categoryId)) {
        let category = await prisma.category.findFirst({
          where: { name: { equals: categoryId.trim(), mode: "insensitive" } }
        });
        if (!category) {
          category = await prisma.category.create({
            data: { name: categoryId.trim() }
          });
        }
        resolvedCategoryId = category.id;
      }

      const parsedStock = stock !== null && stock !== undefined && stock !== "" ? parseInt(stock.toString()) : null;
      const parsedStockQty = stockQuantity !== null && stockQuantity !== undefined && stockQuantity !== "" ? parseInt(stockQuantity.toString()) : (parsedStock || 0);
      const parsedPrepTime = preparationTime !== null && preparationTime !== undefined && preparationTime !== "" ? parseInt(preparationTime.toString()) : null;
      const parsedDepositPrice = depositPrice !== null && depositPrice !== undefined && depositPrice !== "" ? parseFloat(depositPrice.toString()) : null;
      const parsedHasDeposit = hasDeposit === true || hasDeposit === "true";
      const parsedMinQuantity = minQuantity !== null && minQuantity !== undefined && minQuantity !== "" ? parseFloat(minQuantity.toString()) : undefined;
      const parsedStepSize = stepSize !== null && stepSize !== undefined && stepSize !== "" ? parseFloat(stepSize.toString()) : undefined;

      const updated = await prisma.product.update({
        where: { id: productId },
        data: { 
          name, 
          description, 
          price, 
          discountPrice, 
          stock: parsedStock, 
          imageUrl, 
          isActive, 
          categoryId: resolvedCategoryId !== undefined ? resolvedCategoryId : undefined,
          barcode: barcode !== undefined ? (barcode || null) : undefined,
          brand: brand !== undefined ? (brand || null) : undefined,
          stockQuantity: stockQuantity !== undefined ? parsedStockQty : undefined,
          weightOrVolume: weightOrVolume !== undefined ? (weightOrVolume || null) : undefined,
          preparationTime: preparationTime !== undefined ? parsedPrepTime : undefined,
          hasDeposit: hasDeposit !== undefined ? parsedHasDeposit : undefined,
          depositPrice: depositPrice !== undefined ? parsedDepositPrice : undefined,
          unit: unit !== undefined ? unit : undefined,
          minQuantity: parsedMinQuantity,
          stepSize: parsedStepSize
        }
      });

      return res.status(200).json({ error: false, data: updated });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async deleteProduct(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      const productId = req.params.id as string;
      
      const shop = await prisma.shop.findUnique({ where: { merchantId } });
      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı" });

      const existingProduct = await prisma.product.findUnique({ where: { id: productId } });
      if (!existingProduct || existingProduct.shopId !== shop.id) {
        return res.status(403).json({ error: true, message: "Ürün bulunamadı veya yetkiniz yok." });
      }

      // Soft delete: isActive = false
      const deleted = await prisma.product.update({
        where: { id: productId },
        data: { isActive: false }
      });

      return res.status(200).json({ error: false, message: "Ürün başarıyla pasife alındı (Soft delete)", data: deleted });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Katalogdaki tüm benzersiz kategori ve markaları çeker
  async getCatalogFilters(req: Request, res: Response) {
    try {
      const products = await prisma.globalProduct.findMany({
        select: {
          category: true,
          brand: true
        }
      });

      const categories = Array.from(new Set(products.map(p => p.category))).sort();
      const brands = Array.from(new Set(products.map(p => p.brand))).sort();

      return res.status(200).json({
        error: false,
        data: { categories, brands }
      });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Katalogda arama ve filtreleme yapar
  async searchCatalog(req: Request, res: Response) {
    try {
      const q = req.query.q as string;
      const category = req.query.category as string;
      const brand = req.query.brand as string;
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;

      const whereClause: any = {};

      if (q) {
        whereClause.OR = [
          { name: { contains: q, mode: "insensitive" } },
          { brand: { contains: q, mode: "insensitive" } },
          { barcode: { contains: q, mode: "insensitive" } },
          { category: { contains: q, mode: "insensitive" } }
        ];
      }

      if (category) {
        whereClause.category = { equals: category, mode: "insensitive" };
      }

      if (brand) {
        whereClause.brand = { equals: brand, mode: "insensitive" };
      }

      const skip = (page - 1) * limit;

      const results = await prisma.globalProduct.findMany({
        where: whereClause,
        orderBy: { name: "asc" },
        skip,
        take: limit,
      });

      return res.status(200).json({ error: false, data: results });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Katalogdan dükkan envanterine tekil ürün kopyalar
  async addFromCatalog(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Yetkisiz erişim" });

      const { barcode, price, stock } = req.body;
      if (!barcode || price === undefined) {
        return res.status(400).json({ error: true, message: "Barkod ve fiyat alanları zorunludur." });
      }

      const shop = await prisma.shop.findUnique({ where: { merchantId } });
      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı" });

      const globalProduct = await prisma.globalProduct.findUnique({ where: { barcode } });
      if (!globalProduct) return res.status(404).json({ error: true, message: "Katalogda bu barkodlu ürün bulunamadı." });

      // Kategori kontrolü
      let category = await prisma.category.findFirst({
        where: { name: { equals: globalProduct.category, mode: "insensitive" } }
      });
      if (!category) {
        category = await prisma.category.create({
          data: { name: globalProduct.category }
        });
      }

      const parsedStock = stock !== null && stock !== undefined && stock !== "" ? parseInt(stock.toString()) : null;

      // Bu dükkanda aynı isimli ürün zaten var mı?
      const existingProduct = await prisma.product.findFirst({
        where: {
          shopId: shop.id,
          name: globalProduct.name
        }
      });

      let savedProduct;
      if (existingProduct) {
        savedProduct = await prisma.product.update({
          where: { id: existingProduct.id },
          data: {
            price,
            stock: parsedStock,
            isActive: true,
            imageUrl: globalProduct.imageUrl,
            categoryId: category.id
          }
        });
      } else {
        savedProduct = await prisma.product.create({
          data: {
            shopId: shop.id,
            categoryId: category.id,
            name: globalProduct.name,
            description: `${globalProduct.brand} • ${globalProduct.subCategory || ""}`,
            price,
            stock: parsedStock,
            imageUrl: globalProduct.imageUrl,
            isActive: true
          }
        });
      }

      return res.status(200).json({ error: false, message: "Ürün başarıyla envanterinize eklendi.", data: savedProduct });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Birden fazla ürünü katalogdan dükkan envanterine toplu ekler
  async bulkAddFromCatalog(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Yetkisiz erişim" });

      const { items } = req.body; // Array<{ barcode: string, price: number, stock?: number | null }>
      if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ error: true, message: "Geçerli ürün listesi gönderilmelidir." });
      }

      const shop = await prisma.shop.findUnique({ where: { merchantId } });
      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı" });

      const results = [];

      for (const item of items) {
        const { barcode, price, stock } = item;
        if (!barcode || price === undefined) continue;

        const globalProduct = await prisma.globalProduct.findUnique({ where: { barcode } });
        if (!globalProduct) continue;

        // Kategori kontrolü
        let category = await prisma.category.findFirst({
          where: { name: { equals: globalProduct.category, mode: "insensitive" } }
        });
        if (!category) {
          category = await prisma.category.create({
            data: { name: globalProduct.category }
          });
        }

        const parsedStock = stock !== null && stock !== undefined && stock !== "" ? parseInt(stock.toString()) : null;

        // Aynı isimli ürün zaten var mı?
        const existingProduct = await prisma.product.findFirst({
          where: {
            shopId: shop.id,
            name: globalProduct.name
          }
        });

        let savedProduct;
        if (existingProduct) {
          savedProduct = await prisma.product.update({
            where: { id: existingProduct.id },
            data: {
              price,
              stock: parsedStock,
              isActive: true,
              imageUrl: globalProduct.imageUrl,
              categoryId: category.id
            }
          });
        } else {
          savedProduct = await prisma.product.create({
            data: {
              shopId: shop.id,
              categoryId: category.id,
              name: globalProduct.name,
              description: `${globalProduct.brand} • ${globalProduct.subCategory || ""}`,
              price,
              stock: parsedStock,
              imageUrl: globalProduct.imageUrl,
              isActive: true
            }
          });
        }
        results.push(savedProduct);
      }

      return res.status(200).json({
        error: false,
        message: `${results.length} adet ürün başarıyla envanterinize eklendi.`,
        data: results
      });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

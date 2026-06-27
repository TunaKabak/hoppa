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
        include: {
          category: true,
          subCategory: true,
          unit: true,
          brand: true,
          globalProduct: true
        },
        orderBy: { createdAt: 'desc' }
      });

      const formatted = products.map(formatProduct);
      return res.status(200).json({ error: false, data: formatted });
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
        unit, minQuantity, stepSize, trackStock
      } = req.body;

      // Smart Validation: Eğer dükkan MARKET kategorisindeyse ve barcode boşsa 400 hatası dön
      if (shop.type === "MARKET" && (!barcode || barcode.trim() === "")) {
        return res.status(400).json({ error: true, message: "Market ürünleri için barkod zorunludur." });
      }

      // Unit Id bul veya oluştur
      let unitObj = await prisma.unit.findUnique({ where: { code: unit || "ADET" } });
      if (!unitObj) {
        unitObj = await prisma.unit.create({
          data: { code: unit || "ADET", nameTr: unit || "Adet", nameEn: unit || "Pieces" }
        });
      }
      const unitId = unitObj.id;

      // Brand bul veya oluştur
      let brandId = null;
      if (brand && brand.trim() !== "") {
        let brandObj = await prisma.brand.findUnique({ where: { name: brand.trim() } });
        if (!brandObj) {
          brandObj = await prisma.brand.create({ data: { name: brand.trim() } });
        }
        brandId = brandObj.id;
      }

      // Kategori ve Alt Kategori Çözümleme
      let resolvedCategoryId = categoryId;
      let resolvedSubCategoryId = null;

      if (categoryName && categoryName.trim() !== "") {
        let category = await prisma.category.findUnique({
          where: { name: categoryName.trim() }
        });
        if (!category) {
          category = await prisma.category.create({
            data: { name: categoryName.trim(), shopType: shop.type }
          });
        }
        resolvedCategoryId = category.id;
      } else if (categoryId && !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(categoryId)) {
        let category = await prisma.category.findUnique({
          where: { name: categoryId.trim() }
        });
        if (!category) {
          category = await prisma.category.create({
            data: { name: categoryId.trim(), shopType: shop.type }
          });
        }
        resolvedCategoryId = category.id;
      } else if (categoryId) {
        const sub = await prisma.subCategory.findUnique({ where: { id: categoryId } });
        if (sub) {
          resolvedSubCategoryId = sub.id;
          resolvedCategoryId = sub.categoryId;
        } else {
          const cat = await prisma.category.findUnique({ where: { id: categoryId } });
          if (cat) {
            resolvedCategoryId = cat.id;
          }
        }
      }

      if (!resolvedCategoryId) {
        let defaultCat = await prisma.category.findUnique({ where: { name: "Diğer" } });
        if (!defaultCat) {
          defaultCat = await prisma.category.create({ data: { name: "Diğer", shopType: shop.type } });
        }
        resolvedCategoryId = defaultCat.id;
      }

      // Eşleşen globalProduct var mı?
      let resolvedGlobalProductId = null;
      if (barcode && barcode.trim() !== "") {
        const gp = await prisma.globalProduct.findUnique({ where: { barcode: barcode.trim() } });
        if (gp) {
          resolvedGlobalProductId = gp.id;
          if (!resolvedSubCategoryId) resolvedSubCategoryId = gp.subCategoryId;
          if (!resolvedCategoryId) resolvedCategoryId = gp.categoryId;
          if (!brandId) brandId = gp.brandId;
        }
      }

      const parsedTrackStock = trackStock === true || trackStock === "true";
      const parsedStock = parsedTrackStock ? (stock !== null && stock !== undefined && stock !== "" ? parseInt(stock.toString()) : null) : null;
      const parsedStockQty = parsedTrackStock ? (stockQuantity !== null && stockQuantity !== undefined && stockQuantity !== "" ? parseInt(stockQuantity.toString()) : (parsedStock || 0)) : 0;
      const parsedPrepTime = preparationTime !== null && preparationTime !== undefined && preparationTime !== "" ? parseInt(preparationTime.toString()) : null;
      const parsedDepositPrice = depositPrice !== null && depositPrice !== undefined && depositPrice !== "" ? parseFloat(depositPrice.toString()) : null;
      const parsedHasDeposit = hasDeposit === true || hasDeposit === "true";
      const parsedMinQuantity = minQuantity !== null && minQuantity !== undefined && minQuantity !== "" ? parseFloat(minQuantity.toString()) : 1.0;
      const parsedStepSize = stepSize !== null && stepSize !== undefined && stepSize !== "" ? parseFloat(stepSize.toString()) : 1.0;

      if (parsedMinQuantity <= 0 || parsedStepSize <= 0) {
        return res.status(400).json({
          error: true,
          message: "Minimum miktar ve artış adımı sıfırdan büyük olmalıdır."
        });
      }

      const product = await prisma.product.create({
        data: {
          shopId: shop.id,
          name,
          description,
          price,
          discountPrice,
          stock: parsedStock,
          imageUrl,
          categoryId: resolvedCategoryId,
          subCategoryId: resolvedSubCategoryId,
          unitId,
          brandId,
          globalProductId: resolvedGlobalProductId,
          isActive: true,
          barcode: barcode || null,
          stockQuantity: parsedStockQty,
          weightOrVolume: weightOrVolume || null,
          preparationTime: parsedPrepTime,
          hasDeposit: parsedHasDeposit,
          depositPrice: parsedDepositPrice,
          minQuantity: parsedMinQuantity,
          stepSize: parsedStepSize,
          trackStock: parsedTrackStock
        },
        include: {
          category: true,
          subCategory: true,
          unit: true,
          brand: true,
          globalProduct: true
        }
      });

      return res.status(201).json({ error: false, data: formatProduct(product) });
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
        unit, minQuantity, stepSize, trackStock
      } = req.body;

      // Smart Validation: Eğer dükkan MARKET kategorisindeyse ve barcode boşsa 400 hatası dön
      if (shop.type === "MARKET" && (!barcode || barcode.trim() === "")) {
        return res.status(400).json({ error: true, message: "Market ürünleri için barkod zorunludur." });
      }

      // Unit Id bul veya oluştur
      let unitId = existingProduct.unitId;
      if (unit !== undefined) {
        let unitObj = await prisma.unit.findUnique({ where: { code: unit || "ADET" } });
        if (!unitObj) {
          unitObj = await prisma.unit.create({
            data: { code: unit || "ADET", nameTr: unit || "Adet", nameEn: unit || "Pieces" }
          });
        }
        unitId = unitObj.id;
      }

      // Brand bul veya oluştur
      let brandId = existingProduct.brandId;
      if (brand !== undefined) {
        if (brand && brand.trim() !== "") {
          let brandObj = await prisma.brand.findUnique({ where: { name: brand.trim() } });
          if (!brandObj) {
            brandObj = await prisma.brand.create({ data: { name: brand.trim() } });
          }
          brandId = brandObj.id;
        } else {
          brandId = null;
        }
      }

      // Kategori ve Alt Kategori Çözümleme
      let resolvedCategoryId = existingProduct.categoryId;
      let resolvedSubCategoryId = existingProduct.subCategoryId;

      if (categoryName !== undefined) {
        if (categoryName && categoryName.trim() !== "") {
          let category = await prisma.category.findUnique({
            where: { name: categoryName.trim() }
          });
          if (!category) {
            category = await prisma.category.create({
              data: { name: categoryName.trim(), shopType: shop.type }
            });
          }
          resolvedCategoryId = category.id;
          resolvedSubCategoryId = null;
        } else {
          // If explicitly set to empty categoryName, fallback to default
          let defaultCat = await prisma.category.findUnique({ where: { name: "Diğer" } });
          if (!defaultCat) {
            defaultCat = await prisma.category.create({ data: { name: "Diğer", shopType: shop.type } });
          }
          resolvedCategoryId = defaultCat.id;
          resolvedSubCategoryId = null;
        }
      } else if (categoryId !== undefined) {
        if (categoryId && !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(categoryId)) {
          let category = await prisma.category.findUnique({
            where: { name: categoryId.trim() }
          });
          if (!category) {
            category = await prisma.category.create({
              data: { name: categoryId.trim(), shopType: shop.type }
            });
          }
          resolvedCategoryId = category.id;
          resolvedSubCategoryId = null;
        } else if (categoryId) {
          const sub = await prisma.subCategory.findUnique({ where: { id: categoryId } });
          if (sub) {
            resolvedSubCategoryId = sub.id;
            resolvedCategoryId = sub.categoryId;
          } else {
            const cat = await prisma.category.findUnique({ where: { id: categoryId } });
            if (cat) {
              resolvedCategoryId = cat.id;
              resolvedSubCategoryId = null;
            }
          }
        }
      }

      // Eşleşen globalProduct var mı?
      let resolvedGlobalProductId = existingProduct.globalProductId;
      if (barcode !== undefined) {
        if (barcode && barcode.trim() !== "") {
          const gp = await prisma.globalProduct.findUnique({ where: { barcode: barcode.trim() } });
          if (gp) {
            resolvedGlobalProductId = gp.id;
            if (!resolvedSubCategoryId) resolvedSubCategoryId = gp.subCategoryId;
            resolvedCategoryId = gp.categoryId;
            if (!brandId) brandId = gp.brandId;
          } else {
            resolvedGlobalProductId = null;
          }
        } else {
          resolvedGlobalProductId = null;
        }
      }

      const parsedTrackStock = trackStock !== undefined ? (trackStock === true || trackStock === "true") : undefined;
      const parsedStock = parsedTrackStock !== undefined
        ? (parsedTrackStock ? (stock !== null && stock !== undefined && stock !== "" ? parseInt(stock.toString()) : null) : null)
        : (stock !== undefined ? (stock !== null && stock !== "" ? parseInt(stock.toString()) : null) : undefined);

      const parsedStockQty = parsedTrackStock !== undefined
        ? (parsedTrackStock ? (stockQuantity !== null && stockQuantity !== undefined && stockQuantity !== "" ? parseInt(stockQuantity.toString()) : (parsedStock || 0)) : 0)
        : (stockQuantity !== undefined ? (stockQuantity !== null && stockQuantity !== "" ? parseInt(stockQuantity.toString()) : undefined) : undefined);
      const parsedPrepTime = preparationTime !== null && preparationTime !== undefined && preparationTime !== "" ? parseInt(preparationTime.toString()) : null;
      const parsedDepositPrice = depositPrice !== null && depositPrice !== undefined && depositPrice !== "" ? parseFloat(depositPrice.toString()) : null;
      const parsedHasDeposit = hasDeposit === true || hasDeposit === "true";
      const parsedMinQuantity = minQuantity !== null && minQuantity !== undefined && minQuantity !== "" ? parseFloat(minQuantity.toString()) : undefined;
      const parsedStepSize = stepSize !== null && stepSize !== undefined && stepSize !== "" ? parseFloat(stepSize.toString()) : undefined;

      if ((parsedMinQuantity !== undefined && parsedMinQuantity <= 0) || (parsedStepSize !== undefined && parsedStepSize <= 0)) {
        return res.status(400).json({
          error: true,
          message: "Minimum miktar ve artış adımı sıfırdan büyük olmalıdır."
        });
      }

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
          categoryId: resolvedCategoryId,
          subCategoryId: resolvedSubCategoryId,
          unitId,
          brandId,
          globalProductId: resolvedGlobalProductId,
          barcode: barcode !== undefined ? (barcode || null) : undefined,
          stockQuantity: parsedStockQty,
          weightOrVolume: weightOrVolume !== undefined ? (weightOrVolume || null) : undefined,
          preparationTime: preparationTime !== undefined ? parsedPrepTime : undefined,
          hasDeposit: hasDeposit !== undefined ? parsedHasDeposit : undefined,
          depositPrice: depositPrice !== undefined ? parsedDepositPrice : undefined,
          minQuantity: parsedMinQuantity,
          stepSize: parsedStepSize,
          trackStock: parsedTrackStock
        },
        include: {
          category: true,
          subCategory: true,
          unit: true,
          brand: true,
          globalProduct: true
        }
      });

      return res.status(200).json({ error: false, data: formatProduct(updated) });
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
        data: { isActive: false },
        include: {
          category: true,
          subCategory: true,
          unit: true,
          brand: true,
          globalProduct: true
        }
      });

      return res.status(200).json({ error: false, message: "Ürün başarıyla pasife alındı (Soft delete)", data: formatProduct(deleted) });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Katalogdaki tüm benzersiz kategori ve markaları çeker
  async getCatalogFilters(req: Request, res: Response) {
    try {
      const categories = await prisma.category.findMany({ select: { name: true } });
      const brands = await prisma.brand.findMany({ select: { name: true } });

      return res.status(200).json({
        error: false,
        data: {
          categories: categories.map(c => c.name).sort(),
          brands: brands.map(b => b.name).sort()
        }
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
          { brand: { name: { contains: q, mode: "insensitive" } } },
          { barcode: { contains: q, mode: "insensitive" } },
          { category: { name: { contains: q, mode: "insensitive" } } }
        ];
      }

      if (category) {
        whereClause.category = { name: { equals: category, mode: "insensitive" } };
      }

      if (brand) {
        whereClause.brand = { name: { equals: brand, mode: "insensitive" } };
      }

      const skip = (page - 1) * limit;

      const results = await prisma.globalProduct.findMany({
        where: whereClause,
        include: {
          category: true,
          subCategory: true,
          unit: true,
          brand: true
        },
        orderBy: { name: "asc" },
        skip,
        take: limit,
      });

      const formatted = results.map(gp => ({
        ...gp,
        unit: gp.unit ? gp.unit.code : "ADET",
        brand: gp.brand ? gp.brand.name : "Yerli Üretim",
        category: gp.category ? gp.category.name : "",
        subCategory: gp.subCategory ? gp.subCategory.name : null
      }));

      return res.status(200).json({ error: false, data: formatted });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Katalogdan dükkan envanterine tekil ürün kopyalar
  async addFromCatalog(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Yetkisiz erişim" });

      const { barcode, price, stock, trackStock } = req.body;
      if (!barcode || price === undefined) {
        return res.status(400).json({ error: true, message: "Barkod ve fiyat alanları zorunludur." });
      }

      const shop = await prisma.shop.findUnique({ where: { merchantId } });
      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı" });

      const globalProduct = await prisma.globalProduct.findUnique({ where: { barcode } });
      if (!globalProduct) return res.status(404).json({ error: true, message: "Katalogda bu barkodlu ürün bulunamadı." });

      const parsedTrackStock = trackStock === true || trackStock === "true" ? true : false;
      const parsedStock = parsedTrackStock ? (stock !== null && stock !== undefined && stock !== "" ? parseInt(stock.toString()) : null) : null;
      const parsedStockQty = parsedTrackStock ? (parsedStock || 0) : 0;

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
            stockQuantity: parsedStockQty,
            trackStock: parsedTrackStock,
            isActive: true,
            imageUrl: globalProduct.imageUrl,
            globalProductId: globalProduct.id,
            categoryId: globalProduct.categoryId,
            subCategoryId: globalProduct.subCategoryId,
            unitId: globalProduct.unitId,
            brandId: globalProduct.brandId,
            minQuantity: globalProduct.minQuantity,
            stepSize: globalProduct.stepSize
          },
          include: {
            category: true,
            subCategory: true,
            unit: true,
            brand: true,
            globalProduct: true
          }
        });
      } else {
        savedProduct = await prisma.product.create({
          data: {
            shopId: shop.id,
            globalProductId: globalProduct.id,
            categoryId: globalProduct.categoryId,
            subCategoryId: globalProduct.subCategoryId,
            unitId: globalProduct.unitId,
            brandId: globalProduct.brandId,
            name: globalProduct.name,
            description: globalProduct.name,
            price,
            stock: parsedStock,
            stockQuantity: parsedStockQty,
            trackStock: parsedTrackStock,
            imageUrl: globalProduct.imageUrl,
            isActive: true,
            minQuantity: globalProduct.minQuantity,
            stepSize: globalProduct.stepSize
          },
          include: {
            category: true,
            subCategory: true,
            unit: true,
            brand: true,
            globalProduct: true
          }
        });
      }

      return res.status(200).json({ error: false, message: "Ürün başarıyla envanterinize eklendi.", data: formatProduct(savedProduct) });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  // Birden fazla ürünü katalogdan dükkan envanterine toplu ekler
  async bulkAddFromCatalog(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Yetkisiz erişim" });

      const { items } = req.body;
      if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ error: true, message: "Geçerli ürün listesi gönderilmelidir." });
      }

      const shop = await prisma.shop.findUnique({ where: { merchantId } });
      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı" });

      const results = [];

      for (const item of items) {
        const { barcode, price, stock, trackStock } = item;
        if (!barcode || price === undefined) continue;

        const globalProduct = await prisma.globalProduct.findUnique({ where: { barcode } });
        if (!globalProduct) continue;

        const parsedTrackStock = trackStock === true || trackStock === "true" ? true : false;
        const parsedStock = parsedTrackStock ? (stock !== null && stock !== undefined && stock !== "" ? parseInt(stock.toString()) : null) : null;
        const parsedStockQty = parsedTrackStock ? (parsedStock || 0) : 0;

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
              stockQuantity: parsedStockQty,
              trackStock: parsedTrackStock,
              isActive: true,
              imageUrl: globalProduct.imageUrl,
              globalProductId: globalProduct.id,
              categoryId: globalProduct.categoryId,
              subCategoryId: globalProduct.subCategoryId,
              unitId: globalProduct.unitId,
              brandId: globalProduct.brandId,
              minQuantity: globalProduct.minQuantity,
              stepSize: globalProduct.stepSize
            },
            include: {
              category: true,
              subCategory: true,
              unit: true,
              brand: true,
              globalProduct: true
            }
          });
        } else {
          savedProduct = await prisma.product.create({
            data: {
              shopId: shop.id,
              globalProductId: globalProduct.id,
              categoryId: globalProduct.categoryId,
              subCategoryId: globalProduct.subCategoryId,
              unitId: globalProduct.unitId,
              brandId: globalProduct.brandId,
              name: globalProduct.name,
              description: globalProduct.name,
              price,
              stock: parsedStock,
              stockQuantity: parsedStockQty,
              trackStock: parsedTrackStock,
              imageUrl: globalProduct.imageUrl,
              isActive: true,
              minQuantity: globalProduct.minQuantity,
              stepSize: globalProduct.stepSize
            },
            include: {
              category: true,
              subCategory: true,
              unit: true,
              brand: true,
              globalProduct: true
            }
          });
        }
        results.push(formatProduct(savedProduct));
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

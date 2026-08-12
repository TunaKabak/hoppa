import { Router } from "express";
import { authMiddleware } from "../middlewares/AuthMiddleware";
import { ShopController } from "../controllers/ShopController";
import { ProductController } from "../controllers/ProductController";
import { OrderController } from "../controllers/OrderController";
import { ShopCampaignController } from "../controllers/ShopCampaignController";
import { MerchantAIController } from "../controllers/MerchantAIController";

import { prisma } from "../config/db";

import { CategoryController } from "../controllers/CategoryController";

const router = Router();
const shopController = new ShopController();
const productController = new ProductController();
const categoryController = new CategoryController();
const orderController = new OrderController();
const shopCampaignController = new ShopCampaignController();
const merchantAIController = new MerchantAIController();

// Tüm merchant rotaları authMiddleware'den geçmeli
router.use(authMiddleware);

// Rol Doğrulama: Sadece 'merchant' veya 'super_admin' rolüne sahip olanlar erişebilir
router.use((req, res, next) => {
  if (req.user?.role !== "merchant" && req.user?.role !== "super_admin") {
    return res.status(403).json({ error: true, message: "Yetkisiz erişim. Sadece satıcı yetkisi gereklidir." });
  }
  next();
});

// Süper Admin için aktif dükkan bağlamını (Shop Context) ayarlayan ara yazılım
router.use(async (req, res, next) => {
  const isSuperAdmin = req.user?.role === "super_admin";
  const shopId = (req.query.shopId || req.headers["x-business-id"]) as string;

  if (isSuperAdmin && shopId) {
    try {
      const shop = await prisma.shop.findUnique({
        where: { id: shopId }
      });
      if (shop) {
        // Süper Admin seçilen dükkanın sahibi (merchant) rolünde hareket eder
        req.user = {
          ...req.user!,
          id: shop.merchantId,
          role: "merchant"
        };
      }
    } catch (err) {
      console.error("[MerchantRoutes.shopContextMiddleware] Hata:", err);
    }
  }
  next();
});

// Shop / Dükkan İşlemleri
router.get("/shop", (req, res) => shopController.getMyShop(req, res));
router.put("/shop", (req, res) => shopController.updateMyShop(req, res));
router.post("/shop/toggle-status", (req, res) => shopController.openCloseShop(req, res));

// Category / Kategori İşlemleri
router.get("/categories", (req, res) => categoryController.getMerchantCategories(req, res));

// Product / Ürün İşlemleri
router.get("/products", (req, res) => productController.getProductsByShop(req, res));
router.post("/products", (req, res) => productController.createProduct(req, res));
router.put("/products/bulk-stock", (req, res) => productController.bulkUpdateStock(req, res));
router.put("/products/bulk-price", (req, res) => productController.bulkUpdatePrice(req, res));
router.post("/products/:id/option-groups", (req, res) => productController.upsertOptionGroups(req, res));
router.get("/products/catalog", (req, res) => productController.searchCatalog(req, res));
router.get("/products/catalog/filters", (req, res) => productController.getCatalogFilters(req, res));
router.post("/products/catalog/add", (req, res) => productController.addFromCatalog(req, res));
router.post("/products/catalog/bulk-add", (req, res) => productController.bulkAddFromCatalog(req, res));
router.put("/products/:id", (req, res) => productController.updateProduct(req, res));
router.delete("/products/:id", (req, res) => productController.deleteProduct(req, res));

// Order / Sipariş İşlemleri
router.get("/orders", (req, res) => orderController.getMerchantOrders(req, res));
router.put("/orders/:id/status", (req, res) => orderController.updateOrderStatus(req, res));
router.post("/orders/:id/cancel", (req, res) => orderController.cancelOrder(req, res));

// Dashboard İşlemleri
router.get("/dashboard/stats", (req, res) => shopController.getDashboardStats(req, res));

// Öne Çıkarma / Sponsorluk İşlemleri
router.get("/promotions", (req, res) => shopController.getPromotions(req, res));
router.post("/promotions", (req, res) => shopController.createPromotion(req, res));
router.post("/promotions/cancel", (req, res) => shopController.cancelPromotion(req, res));

// Kampanya Yönetimi
router.post("/campaigns", (req, res) => shopCampaignController.createCampaign(req, res));
router.get("/campaigns", (req, res) => shopCampaignController.getMyCampaigns(req, res));

// Yapay Zeka (AI) ve Tahminleme İşlemleri
router.post("/ai/scan-menu", (req, res) => merchantAIController.scanMenu(req, res));
router.get("/ai/predictive-stock", (req, res) => merchantAIController.getPredictiveStock(req, res));

export default router;

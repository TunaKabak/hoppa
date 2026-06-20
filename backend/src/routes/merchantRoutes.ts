import { Router } from "express";
import { authMiddleware } from "../middlewares/AuthMiddleware";
import { ShopController } from "../controllers/ShopController";
import { ProductController } from "../controllers/ProductController";
import { OrderController } from "../controllers/OrderController";

const router = Router();
const shopController = new ShopController();
const productController = new ProductController();
const orderController = new OrderController();

// Tüm merchant rotaları authMiddleware'den geçmeli
router.use(authMiddleware);

// Rol Doğrulama: Sadece 'merchant' veya 'super_admin' rolüne sahip olanlar erişebilir
router.use((req, res, next) => {
  if (req.user?.role !== "merchant" && req.user?.role !== "super_admin") {
    return res.status(403).json({ error: true, message: "Yetkisiz erişim. Sadece satıcı yetkisi gereklidir." });
  }
  next();
});

// Shop / Dükkan İşlemleri
router.get("/shop", (req, res) => shopController.getMyShop(req, res));
router.put("/shop", (req, res) => shopController.updateMyShop(req, res));
router.post("/shop/toggle-status", (req, res) => shopController.openCloseShop(req, res));

// Product / Ürün İşlemleri
router.get("/products", (req, res) => productController.getProductsByShop(req, res));
router.post("/products", (req, res) => productController.createProduct(req, res));
router.get("/products/catalog", (req, res) => productController.searchCatalog(req, res));
router.get("/products/catalog/filters", (req, res) => productController.getCatalogFilters(req, res));
router.post("/products/catalog/add", (req, res) => productController.addFromCatalog(req, res));
router.post("/products/catalog/bulk-add", (req, res) => productController.bulkAddFromCatalog(req, res));
router.put("/products/:id", (req, res) => productController.updateProduct(req, res));
router.delete("/products/:id", (req, res) => productController.deleteProduct(req, res));

// Order / Sipariş İşlemleri
router.get("/orders", (req, res) => orderController.getMerchantOrders(req, res));
router.put("/orders/:id/status", (req, res) => orderController.updateOrderStatus(req, res));

export default router;

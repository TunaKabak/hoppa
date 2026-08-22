import { Router } from "express";
import { authMiddleware } from "../middlewares/AuthMiddleware";
import { SuperAdminController } from "../controllers/SuperAdminController";
import { BusinessCategoryController } from "../controllers/BusinessCategoryController";
import { ReviewController } from "../controllers/ReviewController";
import { ShopCampaignController } from "../controllers/ShopCampaignController";
import { FleetAIController } from "../controllers/FleetAIController";

const router = Router();
const superAdminController = new SuperAdminController();
const businessCategoryController = new BusinessCategoryController();
const shopCampaignController = new ShopCampaignController();
const fleetAIController = new FleetAIController();

// Auth Middleware: All admin routes are protected
router.use(authMiddleware);

// Role Guard: Only super_admin can access these routes
router.use((req, res, next) => {
  if (req.user?.role !== "super_admin") {
    return res.status(403).json({ error: true, message: "Yetkisiz erişim. Sadece sistem yöneticisi yetkisi gereklidir." });
  }
  next();
});

// Admin -> Merchant Management
router.get("/merchants/pending", (req, res) => superAdminController.getPendingMerchants(req, res));
router.put("/merchants/:id/status", (req, res) => superAdminController.updateMerchantStatus(req, res));

// Admin -> Courier Management
router.get("/couriers", (req, res) => superAdminController.getCouriers(req, res));
router.put("/couriers/:id/status", (req, res) => superAdminController.updateCourierStatus(req, res));
router.post("/couriers/:id/shops", (req, res) => superAdminController.assignCourierToShop(req, res));
router.delete("/couriers/:id/shops/:shopId", (req, res) => superAdminController.removeCourierFromShop(req, res));

// Admin -> Business Category Management
router.get("/business-categories", (req, res) => businessCategoryController.adminGetBusinessCategories(req, res));
router.post("/business-categories", (req, res) => businessCategoryController.adminCreateBusinessCategory(req, res));
router.put("/business-categories/reorder", (req, res) => businessCategoryController.adminReorderBusinessCategories(req, res));
router.put("/business-categories/:id", (req, res) => businessCategoryController.adminUpdateBusinessCategory(req, res));
router.delete("/business-categories/:id", (req, res) => businessCategoryController.adminDeleteBusinessCategory(req, res));

// Admin -> Review Management
router.put("/reviews/:reviewId/approve", (req, res) => ReviewController.approveReview(req, res));
router.put("/reviews/:reviewId/reject", (req, res) => ReviewController.rejectReview(req, res));

// Admin -> Campaign Management
router.put("/campaigns/:campaignId/approve", (req, res) => shopCampaignController.approveCampaign(req, res));

// Admin -> Fleet AI Management
router.post("/fleet/optimize", (req, res) => fleetAIController.optimizeRoutes(req, res));

// Admin -> KKTC Service Zones & Geofencing Management
router.get("/service-zones", (req, res) => superAdminController.getServiceZones(req, res));
router.put("/service-zones", (req, res) => superAdminController.updateServiceZones(req, res));

export default router;

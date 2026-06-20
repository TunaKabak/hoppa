import { Router } from "express";
import { authMiddleware } from "../middlewares/AuthMiddleware";
import { SuperAdminController } from "../controllers/SuperAdminController";

const router = Router();
const superAdminController = new SuperAdminController();

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

export default router;

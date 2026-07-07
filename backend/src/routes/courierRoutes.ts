import { Router } from "express";
import { CourierController } from "../controllers/CourierController";
import { authMiddleware } from "../middlewares/AuthMiddleware";

const router = Router();
const courierController = new CourierController();

// Kurye konum güncelleme (hem POST hem de PATCH isteklerini destekler)
router.post("/location", authMiddleware, (req, res) => courierController.updateLocation(req, res));
router.patch("/location", authMiddleware, (req, res) => courierController.updateLocation(req, res));

// Kuryeye atanmış aktif siparişleri getiren API
router.get("/orders", authMiddleware, (req, res) => courierController.getAssignedOrders(req, res));

// Kurye sipariş teslim onay API'si (hem PATCH hem de PUT desteklenir)
router.patch("/orders/:id/deliver", authMiddleware, (req, res) => courierController.deliverOrder(req, res));
router.put("/orders/:id/deliver", authMiddleware, (req, res) => courierController.deliverOrder(req, res));

export default router;

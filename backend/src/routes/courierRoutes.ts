import { Router } from "express";
import { CourierController } from "../controllers/CourierController";
import { authMiddleware } from "../middlewares/AuthMiddleware";

const router = Router();
const courierController = new CourierController();

// Kurye konum güncelleme (hem POST hem de PATCH isteklerini destekler)
router.post("/location", authMiddleware, (req, res) => courierController.updateLocation(req, res));
router.patch("/location", authMiddleware, (req, res) => courierController.updateLocation(req, res));

export default router;

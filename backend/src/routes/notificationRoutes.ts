import { Router } from "express";
import { authMiddleware } from "../middlewares/AuthMiddleware";
import { NotificationController } from "../controllers/NotificationController";

const router = Router();
const notificationController = new NotificationController();

// Korumalı rota
router.use(authMiddleware);

// Cihaz token kaydı
router.post("/register-token", (req, res) => notificationController.registerToken(req, res));

export default router;

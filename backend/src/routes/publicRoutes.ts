import { Router } from "express";
import { HealthController } from "../controllers/HealthController";

const router = Router();

router.get("/health", (req, res) => HealthController.checkHealth(req, res));

export default router;

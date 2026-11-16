import { Router } from "express";
import { HealthController } from "../controllers/HealthController";
import { PublicInquiryController } from "../controllers/PublicInquiryController";

const router = Router();

router.get("/health", (req, res) => HealthController.checkHealth(req, res));
router.post("/merchant-inquiry", (req, res) => PublicInquiryController.submitMerchantInquiry(req, res));
router.post("/contact", (req, res) => PublicInquiryController.submitContactMessage(req, res));

export default router;

import { Router } from "express";
import { authMiddleware } from "../middlewares/AuthMiddleware";
import { ReferralController } from "../controllers/ReferralController";

const router = Router();
const referralController = new ReferralController();

router.use(authMiddleware);

router.get("/", (req, res) => referralController.getReferralData(req, res));
router.get("/code", (req, res) => referralController.getReferralCode(req, res));
router.post("/apply", (req, res) => referralController.applyReferralCode(req, res));
router.get("/history", (req, res) => referralController.getReferrals(req, res));

export default router;

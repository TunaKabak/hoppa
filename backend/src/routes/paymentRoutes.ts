import { Router } from "express";
import { PaymentController } from "../controllers/PaymentController";

const router = Router();
const paymentController = new PaymentController();

router.get("/sandbox-3ds", (req, res) =>
  paymentController.renderSandbox3dsPage(req, res)
);
router.post("/3d-callback", (req, res) =>
  paymentController.handleThreeDCallback(req, res)
);
router.get("/3d-callback", (req, res) =>
  paymentController.handleThreeDCallback(req, res)
);
router.get("/3d-complete", (req, res) =>
  paymentController.renderThreeDCompletePage(req, res)
);

export default router;

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
router.post("/stripe/webhook", (req, res) =>
  paymentController.handleStripeWebhook(req, res)
);
router.get("/stripe/return", (req, res) =>
  paymentController.handleStripeReturn(req, res)
);
router.get("/paytr/pending", (req, res) =>
  paymentController.renderPaytrPendingPage(req, res)
);
router.get("/status/:txId", (req, res) =>
  paymentController.getPaymentStatus(req, res)
);

export default router;

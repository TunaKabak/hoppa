import { Router } from "express";
import { authMiddleware } from "../middlewares/AuthMiddleware";
import { WalletController } from "../controllers/WalletController";

const router = Router();
const walletController = new WalletController();

router.use(authMiddleware);

router.get("/", (req, res) => walletController.getWallet(req, res));
router.post("/deposit", (req, res) => walletController.deposit(req, res));
router.get("/transactions", (req, res) => walletController.getTransactions(req, res));

export default router;

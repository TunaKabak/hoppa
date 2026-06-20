import { Router } from "express";
import { authMiddleware } from "../middlewares/AuthMiddleware";
import { ConsumerShopController } from "../controllers/ConsumerShopController";
import { OrderController } from "../controllers/OrderController";
import { AddressController } from "../controllers/AddressController";

const router = Router();
const consumerShopController = new ConsumerShopController();
const orderController = new OrderController();
const addressController = new AddressController();

// Consumer endpoints: Kimliği doğrulanmış tüm kullanıcılar (user, merchant vs. fark etmez) bu bilgileri çekebilir
router.use(authMiddleware);

// Browse Shops and Products
router.get("/shops", (req, res) => consumerShopController.getActiveShops(req, res));
router.get("/shops/:shopId/products", (req, res) => consumerShopController.getShopProducts(req, res));

// Order Operations
router.post("/orders", (req, res) => orderController.createOrder(req, res));
router.get("/orders", (req, res) => orderController.getConsumerOrders(req, res));

// Address Operations
router.get("/addresses", (req, res) => addressController.getAddresses(req, res));
router.post("/addresses", (req, res) => addressController.createAddress(req, res));
router.put("/addresses/:id", (req, res) => addressController.updateAddress(req, res));
router.delete("/addresses/:id", (req, res) => addressController.deleteAddress(req, res));

export default router;


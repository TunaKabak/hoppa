import { Router, Request, Response } from "express";
import { authMiddleware, optionalAuthMiddleware } from "../middlewares/AuthMiddleware";
import { ConsumerShopController } from "../controllers/ConsumerShopController";
import { OrderController } from "../controllers/OrderController";
import { AddressController } from "../controllers/AddressController";
import { FavoritesController } from "../controllers/FavoritesController";
import { CategoryController } from "../controllers/CategoryController";
import { ReviewController } from "../controllers/ReviewController";
import { SupportController } from "../controllers/SupportController";
import { BusinessCategoryController } from "../controllers/BusinessCategoryController";

const router = Router();
const consumerShopController = new ConsumerShopController();
const orderController = new OrderController();
const addressController = new AddressController();
const favoritesController = new FavoritesController();
const categoryController = new CategoryController();
const businessCategoryController = new BusinessCategoryController();

// --- Public / Optional Auth Endpoints (Misafir Modu Gezinti) ---
router.get("/shops", optionalAuthMiddleware, (req: Request, res: Response) => consumerShopController.getActiveShops(req, res));
router.get("/shops/:shopId/products", optionalAuthMiddleware, (req: Request, res: Response) => consumerShopController.getShopProducts(req, res));
router.get("/shops/:shopId/categories", optionalAuthMiddleware, (req: Request, res: Response) => consumerShopController.getShopActiveCategories(req, res));
router.get("/campaigns", optionalAuthMiddleware, (req: Request, res: Response) => consumerShopController.getCampaigns(req, res));
router.get("/categories", optionalAuthMiddleware, (req: Request, res: Response) => categoryController.getCategories(req, res));
router.get("/business-categories", optionalAuthMiddleware, (req: Request, res: Response) => businessCategoryController.getBusinessCategories(req, res));
router.get("/search/global", optionalAuthMiddleware, (req: Request, res: Response) => consumerShopController.globalSearch(req, res));

// --- Authenticated Consumer Endpoints ---
router.use(authMiddleware);

// Favorites Operations
router.get("/favorites/products", (req: Request, res: Response) => favoritesController.getFavoriteProducts(req, res));
router.post("/favorites/products", (req: Request, res: Response) => favoritesController.getFavoriteProducts(req, res));
router.post("/favorites/products/toggle", (req: Request, res: Response) => favoritesController.toggleFavoriteProduct(req, res));

// Order Operations
router.post("/orders", (req: Request, res: Response) => orderController.createOrder(req, res));
router.get("/orders", (req: Request, res: Response) => orderController.getConsumerOrders(req, res));
router.post("/orders/:id/cancel", (req: Request, res: Response) => orderController.cancelOrder(req, res));

// Address Operations
router.get("/addresses", (req: Request, res: Response) => addressController.getAddresses(req, res));
router.post("/addresses", (req: Request, res: Response) => addressController.createAddress(req, res));
router.put("/addresses/:id", (req: Request, res: Response) => addressController.updateAddress(req, res));
router.delete("/addresses/:id", (req: Request, res: Response) => addressController.deleteAddress(req, res));

// Review Operations
router.post("/reviews", (req: Request, res: Response) => ReviewController.createReview(req, res));
router.get("/shops/:shopId/reviews", (req: Request, res: Response) => ReviewController.getShopReviews(req, res));

// Hoppa Assistant Chat
router.post("/support/chat", (req: Request, res: Response) => SupportController.chatWithAssistant(req, res));
router.post("/support/voice-command", (req: Request, res: Response) => SupportController.parseVoiceCommand(req, res));

export default router;

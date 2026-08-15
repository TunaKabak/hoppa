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
import { ProfileController } from "../controllers/ProfileController";
import { SavedCardController } from "../controllers/SavedCardController";
import { CouponController } from "../controllers/CouponController";
import { ShopCampaignController } from "../controllers/ShopCampaignController";
import { CourierController } from "../controllers/CourierController";
import walletRoutes from "./walletRoutes";
import referralRoutes from "./referralRoutes";

const router = Router();
const consumerShopController = new ConsumerShopController();
const orderController = new OrderController();
const addressController = new AddressController();
const favoritesController = new FavoritesController();
const categoryController = new CategoryController();
const businessCategoryController = new BusinessCategoryController();
const savedCardController = new SavedCardController();
const couponController = new CouponController();
const shopCampaignController = new ShopCampaignController();
const courierController = new CourierController();

// --- Public / Optional Auth Endpoints (Misafir Modu Gezinti) ---
router.get("/shops", optionalAuthMiddleware, (req: Request, res: Response) => consumerShopController.getActiveShops(req, res));
router.get("/shops/:shopId/products", optionalAuthMiddleware, (req: Request, res: Response) => consumerShopController.getShopProducts(req, res));
router.get("/shops/:shopId/categories", optionalAuthMiddleware, (req: Request, res: Response) => consumerShopController.getShopActiveCategories(req, res));
router.get("/campaigns", optionalAuthMiddleware, (req: Request, res: Response) => consumerShopController.getCampaigns(req, res));
router.get("/shop-campaigns/active", optionalAuthMiddleware, (req: Request, res: Response) => shopCampaignController.getActiveSliders(req, res));
router.get("/categories", optionalAuthMiddleware, (req: Request, res: Response) => categoryController.getCategories(req, res));
router.get("/business-categories", optionalAuthMiddleware, (req: Request, res: Response) => businessCategoryController.getBusinessCategories(req, res));
router.get("/search/global", optionalAuthMiddleware, (req: Request, res: Response) => consumerShopController.globalSearch(req, res));

// --- Authenticated Consumer Endpoints ---
router.use(authMiddleware);

// Wallet & Referral
router.use("/wallet", walletRoutes);
router.use("/referral", referralRoutes);

// Profile Operations
router.get("/profile", (req: Request, res: Response) => ProfileController.getProfile(req, res));
router.put("/profile", (req: Request, res: Response) => ProfileController.updateProfile(req, res));

// Saved Cards Operations
router.get("/cards", (req: Request, res: Response) => savedCardController.getCards(req, res));
router.post("/cards", (req: Request, res: Response) => savedCardController.createCard(req, res));
router.delete("/cards/:id", (req: Request, res: Response) => savedCardController.deleteCard(req, res));
router.put("/cards/:id/default", (req: Request, res: Response) => savedCardController.setDefaultCard(req, res));

// Coupon Operations
router.get("/coupons", (req: Request, res: Response) => couponController.getCoupons(req, res));
router.post("/coupons/apply", (req: Request, res: Response) => couponController.applyCoupon(req, res));

// Favorites Operations
router.get("/favorites/products", (req: Request, res: Response) => favoritesController.getFavoriteProducts(req, res));
router.post("/favorites/products", (req: Request, res: Response) => favoritesController.getFavoriteProducts(req, res));
router.post("/favorites/products/toggle", (req: Request, res: Response) => favoritesController.toggleFavoriteProduct(req, res));

// Order Operations
router.post("/orders", (req: Request, res: Response) => orderController.createOrder(req, res));
router.get("/orders", (req: Request, res: Response) => orderController.getConsumerOrders(req, res));
router.get("/orders/:id/tracking", (req: Request, res: Response) => orderController.getOrderTracking(req, res));
router.post("/orders/:id/cancel", (req: Request, res: Response) => orderController.cancelOrder(req, res));

// Courier Location Tracking
router.get("/couriers/:id/location", (req: Request, res: Response) => courierController.getCourierLocation(req, res));

// Address Operations
router.get("/addresses", (req: Request, res: Response) => addressController.getAddresses(req, res));
router.post("/addresses", (req: Request, res: Response) => addressController.createAddress(req, res));
router.put("/addresses/:id", (req: Request, res: Response) => addressController.updateAddress(req, res));
router.delete("/addresses/:id", (req: Request, res: Response) => addressController.deleteAddress(req, res));

// Review Operations
router.post("/reviews", (req: Request, res: Response) => ReviewController.createReview(req, res));
router.get("/reviews/my", (req: Request, res: Response) => ReviewController.getMyReviews(req, res));
router.get("/shops/:shopId/reviews", (req: Request, res: Response) => ReviewController.getShopReviews(req, res));

// Hoppa Assistant Chat
router.post("/support/chat", (req: Request, res: Response) => SupportController.chatWithAssistant(req, res));
router.post("/support/voice-command", (req: Request, res: Response) => SupportController.parseVoiceCommand(req, res));

export default router;

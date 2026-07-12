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
router.get("/shops", optionalAuthMiddleware, (req, res) => consumerShopController.getActiveShops(req, res));
router.get("/shops/:shopId/products", optionalAuthMiddleware, (req, res) => consumerShopController.getShopProducts(req, res));
router.get("/shops/:shopId/categories", optionalAuthMiddleware, (req, res) => consumerShopController.getShopActiveCategories(req, res));
router.get("/campaigns", optionalAuthMiddleware, (req, res) => consumerShopController.getCampaigns(req, res));
router.get("/categories", optionalAuthMiddleware, (req, res) => categoryController.getCategories(req, res));
router.get("/business-categories", optionalAuthMiddleware, (req, res) => businessCategoryController.getBusinessCategories(req, res));
router.get("/search/global", optionalAuthMiddleware, (req, res) => consumerShopController.globalSearch(req, res));

// --- Authenticated Consumer Endpoints ---
router.use(authMiddleware);

// Favorites Operations
router.get("/favorites/products", (req, res) => favoritesController.getFavoriteProducts(req, res));
router.post("/favorites/products", (req, res) => favoritesController.getFavoriteProducts(req, res));
router.post("/favorites/products/toggle", (req, res) => favoritesController.toggleFavoriteProduct(req, res));

// Order Operations
router.post("/orders", (req, res) => orderController.createOrder(req, res));
router.get("/orders", (req, res) => orderController.getConsumerOrders(req, res));
router.post("/orders/:id/cancel", (req, res) => orderController.cancelOrder(req, res));

// Address Operations
router.get("/addresses", (req, res) => addressController.getAddresses(req, res));
router.post("/addresses", (req, res) => addressController.createAddress(req, res));
router.put("/addresses/:id", (req, res) => addressController.updateAddress(req, res));
router.delete("/addresses/:id", (req, res) => addressController.deleteAddress(req, res));

// Review Operations
router.post("/reviews", (req, res) => ReviewController.createReview(req, res));
router.get("/shops/:shopId/reviews", (req, res) => ReviewController.getShopReviews(req, res));

// Hoppa Assistant Chat
router.post("/support/chat", (req, res) => SupportController.chatWithAssistant(req, res));
router.post("/support/voice-command", (req, res) => SupportController.parseVoiceCommand(req, res));

export default router;


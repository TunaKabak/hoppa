"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const AuthMiddleware_1 = require("../middlewares/AuthMiddleware");
const NotificationController_1 = require("../controllers/NotificationController");
const router = (0, express_1.Router)();
const notificationController = new NotificationController_1.NotificationController();
// Korumalı rota
router.use(AuthMiddleware_1.authMiddleware);
// Cihaz token kaydı
router.post("/register-token", (req, res) => notificationController.registerToken(req, res));
exports.default = router;

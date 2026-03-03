"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const admin = __importStar(require("firebase-admin"));
const bcrypt = __importStar(require("bcryptjs"));
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
const router = (0, express_1.Router)();
const db = admin.firestore();
/**
 * POST /api/business/auth/login
 * Body: { username: "mavi_market_1", password: "password123" }
 */
router.post("/login", async (req, res) => {
    try {
        const { username, password } = req.body;
        if (!username || !password) {
            // Jenerik 401 hatası (User Enumeration koruması)
            return res.status(401).json({
                success: false,
                message: "Kullanıcı adı veya şifre hatalı",
            });
        }
        // `business_users` koleksiyonundan username'i ara
        const snapshot = await db
            .collection("business_users")
            .where("username", "==", username)
            .limit(1)
            .get();
        if (snapshot.empty) {
            return res.status(401).json({
                success: false,
                message: "Kullanıcı adı veya şifre hatalı",
            });
        }
        const userDoc = snapshot.docs[0];
        const userData = userDoc.data();
        // Bcrypt ile şifre doğrulaması yap
        const isMatch = await bcrypt.compare(password, userData.passwordHash);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: "Kullanıcı adı veya şifre hatalı",
            });
        }
        // Basarili giris: Firebase Custom Token olustur (Role Claim'i eklenebilir)
        const customToken = await admin.auth().createCustomToken(userDoc.id, {
            role: "merchant",
            businessId: userData.businessId,
        });
        return res.status(200).json({
            success: true,
            token: customToken,
            businessId: userData.businessId,
            message: "Giriş başarılı",
        });
    }
    catch (error) {
        console.error("Login Error:", error);
        // Ic hatalarda spesifik bilgi donme
        return res.status(500).json({
            success: false,
            message: "Sunucu hatası oluştu. Lütfen tekrar deneyiniz.",
        });
    }
});
exports.default = router;
//# sourceMappingURL=auth.js.map
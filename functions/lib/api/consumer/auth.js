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
if (!admin.apps.length) {
    admin.initializeApp();
}
const router = (0, express_1.Router)();
const db = admin.firestore();
// Optional: Rate Limiting in Memory or simple DB since user uses Google testing
// We'll add a simple Firestore-based rate-limit.
const checkRateLimit = async (ip, phone) => {
    const windowMs = 3 * 60 * 1000; // 3 minutes
    const now = Date.now();
    const limitRef = db.collection("rate_limits").doc(phone);
    // We can run a transaction or just simple get/set
    const doc = await limitRef.get();
    if (doc.exists) {
        const data = doc.data();
        if (data && now - data.timestamp < windowMs) {
            if (data.count >= 3) {
                return false; // Exceeded 3 requests per 3 minutes
            }
            await limitRef.update({ count: data.count + 1 });
        }
        else {
            // Reset window
            await limitRef.set({ timestamp: now, count: 1, ip });
        }
    }
    else {
        await limitRef.set({ timestamp: now, count: 1, ip });
    }
    return true;
};
/**
 * POST /api/consumer/auth/firebase-login
 * Body: { firebaseToken: "JWT..." }
 *
 * Called by the app AFTER native Firebase SMS verification succeeds.
 * The app gets the Firebase User, gets their token, and sends it here.
 * We decode the token, check if the user profile exists in Firestore.
 * If not, we create the user profile to act as a seamless registration.
 */
router.post("/firebase-login", async (req, res) => {
    try {
        const { firebaseToken } = req.body;
        if (!firebaseToken) {
            return res.status(400).json({ success: false, message: "Token eksik" });
        }
        // Verify token
        const decodedToken = await admin.auth().verifyIdToken(firebaseToken);
        const uid = decodedToken.uid;
        const phone = decodedToken.phone_number;
        if (!phone) {
            return res.status(400).json({ success: false, message: "Telefon numarası bulunamadı" });
        }
        const ip = req.ip || req.connection.remoteAddress || "unknown_ip";
        // Apply Rate Limiting
        const allowed = await checkRateLimit(ip, phone);
        if (!allowed) {
            return res.status(429).json({ success: false, message: "Çok fazla deneme yaptınız. Lütfen 3 dakika bekleyin." });
        }
        // Check if user exists in Firestore
        const userRef = db.collection("users").doc(uid);
        const userDoc = await userRef.get();
        let isNewUser = false;
        if (!userDoc.exists) {
            // Background profile creation (Passwordless Auth)
            isNewUser = true;
            await userRef.set({
                uid: uid,
                phone: phone,
                email: null,
                name: "Misafir",
                surname: "Kullanıcı",
                role: "user",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                lastLogin: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        else {
            // Update last login
            await userRef.update({
                lastLogin: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        return res.status(200).json({
            success: true,
            isNewUser: isNewUser,
            message: "Giriş/Kayıt başarılı",
        });
    }
    catch (e) {
        console.error("verify-and-register error:", e);
        return res.status(500).json({ success: false, message: "Sunucu hatası" });
    }
});
exports.default = router;
//# sourceMappingURL=auth.js.map
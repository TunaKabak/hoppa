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
const firestore_1 = require("firebase-admin/firestore");
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
const router = (0, express_1.Router)();
const db = admin.firestore();
/**
 * POST /api/business/admin/approve
 * Super-Admin'in, kayıtlı bir "pending" işletmeyi onaylayıp ona gerçek bir "business" ID tahsis etmesi
 * Body: { targetUserId: string }
 */
router.post("/approve", async (req, res) => {
    try {
        const { targetUserId } = req.body;
        if (!targetUserId) {
            return res.status(400).json({
                success: false,
                message: "Hedef kullanıcı ID'si eksik.",
            });
        }
        const userRef = db.collection("business_users").doc(targetUserId);
        const userDoc = await userRef.get();
        if (!userDoc.exists) {
            return res.status(404).json({
                success: false,
                message: "Böyle bir kullanıcı bulunamadı.",
            });
        }
        const userData = userDoc.data();
        if ((userData === null || userData === void 0 ? void 0 : userData.status) !== "pending") {
            return res.status(400).json({
                success: false,
                message: `Bu kullanıcının durumu 'pending' değil. (Mevcut: ${userData === null || userData === void 0 ? void 0 : userData.status})`,
            });
        }
        // 1. Yeni bir "business" oluştur
        const businessRef = db.collection("businesses").doc();
        const businessId = businessRef.id;
        // Varsayılan işletme şablonu
        await businessRef.set({
            name: userData.businessName || "Yeni İşletme",
            address: userData.fullAddress || "",
            district: userData.district || "",
            phone: userData.phone || "",
            taxNumber: userData.taxNumber || "",
            msNumber: userData.msNumber || "",
            isOpen: false,
            rating: 0.0,
            reviewCount: 0,
            type: "market",
            categories: ["Market"],
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
        // 2. Kullanıcının statüsünü ve rolünü güncelle (Mağazaya Bağla)
        await userRef.update({
            status: "active",
            businessId: businessId,
            storeRole: "store_manager" // Ana işletme yöneticisi yetkisi
        });
        return res.status(200).json({
            success: true,
            message: "Kullanıcı başarıyla onaylandı ve mağazası oluşturuldu.",
            businessId: businessId,
        });
    }
    catch (error) {
        console.error("Admin Approve Error:", error);
        return res.status(500).json({
            success: false,
            message: "Sunucu hatası oluştu. Lütfen tekrar deneyiniz.",
        });
    }
});
router.post("/reject", async (req, res) => {
    try {
        const { targetUserId, reason } = req.body;
        if (!targetUserId)
            return res.status(400).json({ success: false, message: "Hedef kullanıcı ID'si eksik." });
        const userRef = db.collection("business_users").doc(targetUserId);
        const userDoc = await userRef.get();
        if (!userDoc.exists)
            return res.status(404).json({ success: false, message: "Kullanıcı bulunamadı." });
        await userRef.update({
            status: "rejected",
            rejectionReason: reason || "Belirtilmedi",
        });
        return res.status(200).json({ success: true, message: "Başvuru reddedildi." });
    }
    catch (error) {
        console.error("Admin Reject Error:", error);
        return res.status(500).json({ success: false, message: "Sunucu hatası." });
    }
});
router.post("/request-revision", async (req, res) => {
    try {
        const { targetUserId, message } = req.body;
        if (!targetUserId)
            return res.status(400).json({ success: false, message: "Hedef kullanıcı ID'si eksik." });
        if (!message)
            return res.status(400).json({ success: false, message: "Revizyon mesajı zorunludur." });
        const userRef = db.collection("business_users").doc(targetUserId);
        const userDoc = await userRef.get();
        if (!userDoc.exists)
            return res.status(404).json({ success: false, message: "Kullanıcı bulunamadı." });
        await userRef.update({
            status: "revision_requested",
            revisionMessage: message,
        });
        return res.status(200).json({ success: true, message: "Revizyon talebi gönderildi." });
    }
    catch (error) {
        console.error("Admin Revizyon Error:", error);
        return res.status(500).json({ success: false, message: "Sunucu hatası." });
    }
});
router.post("/hold", async (req, res) => {
    try {
        const { targetUserId } = req.body;
        if (!targetUserId)
            return res.status(400).json({ success: false, message: "Hedef kullanıcı ID'si eksik." });
        const userRef = db.collection("business_users").doc(targetUserId);
        const userDoc = await userRef.get();
        if (!userDoc.exists)
            return res.status(404).json({ success: false, message: "Kullanıcı bulunamadı." });
        await userRef.update({
            status: "on_hold",
        });
        return res.status(200).json({ success: true, message: "Başvuru beklemeye alındı." });
    }
    catch (error) {
        console.error("Admin Hold Error:", error);
        return res.status(500).json({ success: false, message: "Sunucu hatası." });
    }
});
router.post("/delete", async (req, res) => {
    try {
        const { targetUserId } = req.body;
        if (!targetUserId)
            return res.status(400).json({ success: false, message: "Hedef kullanıcı ID'si eksik." });
        const userRef = db.collection("business_users").doc(targetUserId);
        const userDoc = await userRef.get();
        if (!userDoc.exists)
            return res.status(404).json({ success: false, message: "Kullanıcı bulunamadı." });
        // Sadece Firestore doc silinir, dilerse Auth kısmını da silmek gerekir ancak genelde yetersiz
        await userRef.delete();
        return res.status(200).json({ success: true, message: "Kullanıcı kaydı başarıyla silindi." });
    }
    catch (error) {
        console.error("Admin Delete Error:", error);
        return res.status(500).json({ success: false, message: "Sunucu hatası." });
    }
});
exports.default = router;
//# sourceMappingURL=admin.js.map
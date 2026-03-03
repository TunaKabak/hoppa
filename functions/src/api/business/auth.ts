import { Router, Request, Response } from "express";
import * as admin from "firebase-admin";
import * as bcrypt from "bcryptjs";

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

const router = Router();
const db = admin.firestore();

/**
 * POST /api/business/auth/login
 * Body: { username: "mavi_market_1", password: "password123" }
 */
router.post("/login", async (req: Request, res: Response) => {
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

    } catch (error) {
        console.error("Login Error:", error);
        // Ic hatalarda spesifik bilgi donme
        return res.status(500).json({
            success: false,
            message: "Sunucu hatası oluştu. Lütfen tekrar deneyiniz.",
        });
    }
});

export default router;

import { Router, Request, Response } from "express";
import * as admin from "firebase-admin";
import * as bcrypt from "bcryptjs";
import { FieldValue } from "firebase-admin/firestore";
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

        // Email veya Kullanıcı Adı (username) ile arama yap
        let snapshot;
        if (username.includes("@")) {
            snapshot = await db
                .collection("business_users")
                .where("email", "==", username)
                .limit(1)
                .get();
        } else {
            snapshot = await db
                .collection("business_users")
                .where("username", "==", username)
                .limit(1)
                .get();
        }

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

        const userRole = userData.role || "merchant";
        const userBusinessId = userData.businessId || null;

        // Basarili giris: Firebase Custom Token olustur (Role Claim'i eklenebilir)
        const customToken = await admin.auth().createCustomToken(userDoc.id, {
            role: userRole,
            businessId: userBusinessId,
        });

        return res.status(200).json({
            success: true,
            token: customToken,
            businessId: userBusinessId,
            role: userRole,
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

/**
 * POST /api/business/auth/register
 * Body: { email, password, businessName, msNumber, taxNumber, phone, district, fullAddress }
 */
router.post("/register", async (req: Request, res: Response) => {
    try {
        const {
            email,
            password,
            businessName,
            msNumber,
            taxNumber,
            phone,
            district,
            fullAddress,
        } = req.body;

        // 1. Validasyon
        if (
            !email ||
            !password ||
            !businessName ||
            !msNumber ||
            !taxNumber ||
            !phone ||
            !district ||
            !fullAddress
        ) {
            return res.status(400).json({
                success: false,
                message: "Lütfen tüm zorunlu alanları eksiksiz doldurunuz.",
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                message: "Şifreniz en az 6 karakterden oluşmalıdır.",
            });
        }

        // İşletme adının benzersizliğini kontrol et (Case-insensitive yaklaşım)
        const normalizedBusinessName = businessName.trim().toLowerCase();
        const businessCheckSnapshot = await db
            .collection("business_users")
            .where("businessNameLower", "==", normalizedBusinessName)
            .limit(1)
            .get();

        if (!businessCheckSnapshot.empty) {
            return res.status(400).json({
                success: false,
                message: "Bu işletme adıyla sistemde zaten bir kayıt bulunmaktadır. Lütfen marka adınızı kontrol ediniz.",
            });
        }

        // 2. Firebase Auth Kaydı
        let userRecord;
        try {
            userRecord = await admin.auth().createUser({
                email,
                password,
                displayName: businessName,
            });
        } catch (authError: any) {
            if (authError.code === "auth/email-already-exists") {
                return res.status(400).json({
                    success: false,
                    message: "Bu e-posta adresi sistemde zaten kayıtlıdır.",
                });
            }
            throw authError; // Diğer beklenmeyen hatalar ana catch bloğuna düşsün
        }

        // 3. Kullanıcı adı (username) ve Şifre Hash'i (passwordHash) oluştur
        // Login ekranı username ve passwordHash ile çalıştığı için bu alanlar şart.
        const username = businessName
            .toLowerCase()
            .replace(/\s+/g, '')
            .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u')
            .replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c')
            + Math.floor(10 + Math.random() * 90); // Benzersiz yapmak için 2 hane ekliyoruz

        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        // 4. Firestore Kaydı
        const uid = userRecord.uid;
        await db.collection("business_users").doc(uid).set({
            email,
            username,
            passwordHash,
            businessName,
            businessNameLower: normalizedBusinessName,
            msNumber,
            taxNumber,
            phone,
            district,
            fullAddress,
            role: "merchant", // Güvenlik: backend'de hardcode
            status: "pending", // Onay süreci yönetimi
            createdAt: FieldValue.serverTimestamp(),
        });

        // 5. Başarılı Yanıt
        return res.status(201).json({
            success: true,
            message: "İşletme kaydınız başarıyla alındı, onay sürecindedir.",
        });
    } catch (error) {
        console.error("Register Error:", error);
        return res.status(500).json({
            success: false,
            message: "Kayıt sırasında sunucu hatası oluştu. Lütfen daha sonra tekrar deneyiniz.",
        });
    }
});

/**
 * POST /api/business/auth/submit-revision
 * Body: { uid, businessName, msNumber, taxNumber, phone, district, fullAddress }
 */
router.post("/submit-revision", async (req: Request, res: Response) => {
    try {
        const {
            uid,
            businessName,
            msNumber,
            taxNumber,
            phone,
            district,
            fullAddress,
        } = req.body;

        if (!uid || !businessName || !msNumber || !taxNumber || !phone || !district || !fullAddress) {
            return res.status(400).json({
                success: false,
                message: "Lütfen tüm zorunlu alanları eksiksiz doldurunuz.",
            });
        }

        const userRef = db.collection("business_users").doc(uid);
        const userDoc = await userRef.get();

        if (!userDoc.exists) {
            return res.status(404).json({ success: false, message: "Kullanıcı bulunamadı." });
        }

        const userData = userDoc.data();
        if (userData?.status !== "revision_requested") {
            return res.status(400).json({
                success: false,
                message: "Sadece revizyon istenen başvurular güncellenebilir.",
            });
        }

        const normalizedBusinessName = businessName.trim().toLowerCase();

        // Aynı isimde başka işletme var mı (kendi uid hariç)?
        const businessCheckSnapshot = await db
            .collection("business_users")
            .where("businessNameLower", "==", normalizedBusinessName)
            .get();

        const existsForOtherUser = businessCheckSnapshot.docs.some(doc => doc.id !== uid);
        if (existsForOtherUser) {
            return res.status(400).json({
                success: false,
                message: "Bu işletme adıyla sistemde zaten bir kayıt bulunmaktadır.",
            });
        }

        await userRef.update({
            businessName,
            businessNameLower: normalizedBusinessName,
            msNumber,
            taxNumber,
            phone,
            district,
            fullAddress,
            status: "pending",
            revisionMessage: FieldValue.delete(), // Mesajı kaldırıyoruz
        });

        return res.status(200).json({
            success: true,
            message: "Başvurunuz başarıyla güncellendi ve tekrar incelemeye alındı.",
        });
    } catch (error) {
        console.error("Submit Revision Error:", error);
        return res.status(500).json({
            success: false,
            message: "Sunucu hatası oluştu.",
        });
    }
});

export default router;

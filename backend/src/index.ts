import path from "path";
import dotenv from "dotenv";
dotenv.config({ path: path.join(__dirname, "../.env") });

import express, { Request, Response } from "express";
import cors from "cors";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

// Clean up environment variables (strip quotes) before importing controllers/services
if (process.env.DATABASE_URL) {
  process.env.DATABASE_URL = process.env.DATABASE_URL.replace(/^["']|["']$/g, "");
}
if (process.env.DIRECT_URL) {
  process.env.DIRECT_URL = process.env.DIRECT_URL.replace(/^["']|["']$/g, "");
}
if (process.env.JWT_SECRET) {
  process.env.JWT_SECRET = process.env.JWT_SECRET.replace(/^["']|["']$/g, "");
}
if (process.env.SMS_PROVIDER_MODE) {
  process.env.SMS_PROVIDER_MODE = process.env.SMS_PROVIDER_MODE.replace(/^["']|["']$/g, "");
}
if (process.env.TEST_PHONE_NUMBERS) {
  process.env.TEST_PHONE_NUMBERS = process.env.TEST_PHONE_NUMBERS.replace(/^["']|["']$/g, "");
}
if (process.env.TEST_OTP_CODE) {
  process.env.TEST_OTP_CODE = process.env.TEST_OTP_CODE.replace(/^["']|["']$/g, "");
}
if (process.env.TWILIO_ACCOUNT_SID) {
  process.env.TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID.replace(/^["']|["']$/g, "");
}
if (process.env.TWILIO_AUTH_TOKEN) {
  process.env.TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN.replace(/^["']|["']$/g, "");
}
if (process.env.TWILIO_FROM_NUMBER) {
  process.env.TWILIO_FROM_NUMBER = process.env.TWILIO_FROM_NUMBER.replace(/^["']|["']$/g, "");
}

import { AuthController } from "./controllers/AuthController";
import { MerchantAuthController } from "./controllers/MerchantAuthController";
import merchantRoutes from "./routes/merchantRoutes";
import consumerRoutes from "./routes/consumerRoutes";
import adminRoutes from "./routes/adminRoutes";
import mediaRoutes from "./routes/media.routes";
import notificationRoutes from "./routes/notificationRoutes";
import courierRoutes from "./routes/courierRoutes";
import { otpRateLimiter } from "./middlewares/RateLimiter";

const app = express();
const port = process.env.PORT || 3000;

// Statically serve the local uploads directory for development fallback
app.use("/uploads", express.static(path.join(__dirname, "../public/uploads")));

// Middleware
const allowedOrigins = [
  'http://localhost:3000',                  // Lokal testler için
  'https://www.hoppanow.com',               // Canlı Web UI ana adresi
  'https://hoppanow.com'                    // www olmadan yönlendirme adresi
];

app.use(cors({
  origin: (origin, callback) => {
    // Mobil uygulamalar (origin null/undefined gönderebilir) veya izin verilen domainler
    if (!origin || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('CORS Policy: Bu kök dizinden istek gönderilemez.'));
    }
  },
  credentials: true
}));
app.use(express.json());

// Controller Instances
const authController = new AuthController();
const merchantAuthController = new MerchantAuthController();

// --- Consumer Auth Routes (OTP tabanlı) ---
app.post("/api/auth/request-otp", otpRateLimiter, (req, res) => authController.requestOtp(req, res));
app.post("/api/auth/verify-otp", (req, res) => authController.verifyOtp(req, res));
app.get("/api/auth/check-phone/:phone", (req, res) => authController.checkPhoneExists(req, res));

// --- Merchant Auth Routes (E-posta + Şifre tabanlı) ---
app.post("/api/merchant/auth/login", (req, res) => merchantAuthController.login(req, res));
app.post("/api/merchant/auth/register", (req, res) => merchantAuthController.register(req, res));
app.post("/api/merchant/auth/submit-revision", (req, res) => merchantAuthController.submitRevision(req, res));

// --- API Domain Routes ---
app.use("/api/merchant", merchantRoutes);
app.use("/api/consumer", consumerRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/media", mediaRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/couriers", courierRoutes);

app.get('/health', (req: Request, res: Response) => {
    res.status(200).json({ status: "OK", timestamp: new Date() });
});

// --- Mock 3D Secure Routes ---
app.get('/mock-3d-secure', (req: Request, res: Response) => {
    const txId = req.query.txId || 'unknown';
    res.send(`
        <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <meta charset="utf-8">
                <style>
                    body { font-family: sans-serif; padding: 20px; text-align: center; }
                    .card { border: 1px solid #ccc; padding: 20px; border-radius: 8px; max-width: 400px; margin: 0 auto; }
                    button { background: #00A651; color: white; border: none; padding: 12px 20px; border-radius: 4px; font-size: 16px; cursor: pointer; width: 100%; }
                </style>
            </head>
            <body>
                <div class="card">
                    <h2>3D Secure Doğrulama</h2>
                    <p>İşlem No: <b>${txId}</b></p>
                    <p>Lütfen bankanızdan gelen şifreyi giriniz.</p>
                    <input type="text" placeholder="SMS Şifresi" value="123456" style="padding: 10px; width: 90%; margin-bottom: 20px; text-align: center; letter-spacing: 5px;" />
                    <button onclick="window.location.href='/mock-3d-secure/callback?success=true&txId=${txId}'">Şifreyi Onayla</button>
                </div>
            </body>
        </html>
    `);
});

app.get('/mock-3d-secure/callback', async (req: Request, res: Response) => {
    const txId = req.query.txId as string;
    if (txId) {
        try {
            const tx = await prisma.paymentTransaction.findFirst({ where: { providerTxId: txId } });
            if (tx) {
                await prisma.paymentTransaction.update({
                    where: { id: tx.id },
                    data: { status: 'SUCCESS' }
                });
                await prisma.order.update({
                    where: { id: tx.orderId },
                    data: { paymentStatus: 'SUCCESS' }
                });
            }
        } catch (error) {
            console.error("Mock 3D Callback Error:", error);
        }
    }
    res.send("<h1>Ödeme Başarılı</h1><p>Uygulamaya dönülüyor...</p>");
});

// Sunucuyu Başlat
app.listen(port, () => {
  console.log(`[Server] Hoppa Backend API listening at http://localhost:${port}`);
});

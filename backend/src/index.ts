import path from "path";
import dotenv from "dotenv";
dotenv.config({ path: path.join(__dirname, "../.env") });

import express from "express";
import cors from "cors";

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

import { AuthController } from "./controllers/AuthController";
import { MerchantAuthController } from "./controllers/MerchantAuthController";
import merchantRoutes from "./routes/merchantRoutes";
import consumerRoutes from "./routes/consumerRoutes";
import adminRoutes from "./routes/adminRoutes";
import mediaRoutes from "./routes/media.routes";

const app = express();
const port = process.env.PORT || 3000;

// Statically serve the local uploads directory for development fallback
app.use("/uploads", express.static(path.join(__dirname, "../public/uploads")));

// Middleware
app.use(cors());
app.use(express.json());

// Controller Instances
const authController = new AuthController();
const merchantAuthController = new MerchantAuthController();

// --- Consumer Auth Routes (OTP tabanlı) ---
app.post("/api/auth/request-otp", (req, res) => authController.requestOtp(req, res));
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

import fs from "fs";

// Health Check
app.get("/", (req, res) => {
  const envPath = path.join(__dirname, "../.env");
  const envExists = fs.existsSync(envPath);
  
  let dbUrl = process.env.DATABASE_URL || "undefined";
  if (dbUrl !== "undefined") {
    dbUrl = dbUrl.replace(/:([^@:]+)@/, ":****@");
  }

  res.status(200).json({
    error: false,
    data: {
      message: "Hoppa Backend API is running. (Version prisma-shared-v1)",
      envExists,
      envPath,
      dbUrl,
      cwd: process.cwd()
    }
  });
});

// Sunucuyu Başlat
app.listen(port, () => {
  console.log(`[Server] Hoppa Backend API listening at http://localhost:${port}`);
});

import path from "path";
import dotenv from "dotenv";
dotenv.config({ path: path.join(__dirname, "../.env") });

import express, { Request, Response } from "express";
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
import publicRoutes from "./routes/publicRoutes";
import paymentRoutes from "./routes/paymentRoutes";
import eventRoutes from "./routes/eventRoutes";
import helmet from "helmet";
import { authMiddleware } from "./middlewares/AuthMiddleware";
import {
  otpRateLimiter,
  otpVerifyRateLimiter,
  authLoginRateLimiter,
  globalRateLimiter,
  handshakeRateLimiter,
} from "./middlewares/RateLimiter";
import { validateBody } from "./middlewares/ValidateMiddleware";
import { handshakeMiddleware } from "./middlewares/HandshakeMiddleware";
import { requestOtpSchema, verifyOtpSchema } from "./types/schemas";
import { initCronJobs } from "./utils/cronJobs";

const app = express();
app.set("trust proxy", 1);
const port = process.env.PORT || 3000;

app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
}));
app.use(globalRateLimiter);

// Statically serve the local uploads directory strictly outside production with nosniff + sandbox
if (process.env.NODE_ENV !== "production") {
  app.use(
    "/uploads",
    express.static(path.join(__dirname, "../public/uploads"), {
      setHeaders: (res) => {
        res.setHeader("X-Content-Type-Options", "nosniff");
        res.setHeader("Content-Security-Policy", "default-src 'none'; sandbox");
      },
    })
  );
}

const isProduction = process.env.NODE_ENV === "production";
const envOrigins = [
  process.env.CORS_ALLOWED_ORIGINS,
  process.env.WEB_APP_URL,
  process.env.PUBLIC_WEB_URL,
]
  .filter(Boolean)
  .flatMap((v) => v!.split(","))
  .map((s) => s.trim())
  .filter(Boolean);

const allowedOrigins = Array.from(
  new Set([
    ...(isProduction
      ? []
      : [
          "http://localhost:3000",
          "http://localhost:3001",
          "http://localhost:3002",
          "http://localhost:5173",
          "http://127.0.0.1:3000",
          "http://127.0.0.1:3001",
          "http://127.0.0.1:3002",
          "http://127.0.0.1:5173",
        ]),
    "https://www.hoppanow.com",
    "https://hoppanow.com",
    ...envOrigins,
  ])
);

function isOriginAllowed(origin: string | undefined): boolean {
  if (!origin) return true;
  if (allowedOrigins.includes(origin)) return true;

  try {
    const parsed = new URL(origin);
    if (!isProduction && (parsed.hostname === "localhost" || parsed.hostname === "127.0.0.1")) {
      return parsed.protocol === "http:" || parsed.protocol === "https:";
    }
    if (
      parsed.protocol === "https:" &&
      (parsed.hostname === "hoppanow.com" || parsed.hostname.endsWith(".hoppanow.com"))
    ) {
      return true;
    }
  } catch {
    return false;
  }
  return false;
}

app.use(cors({
  origin: (origin, callback) => {
    if (isOriginAllowed(origin)) {
      callback(null, true);
    } else {
      callback(new Error("CORS policy: origin not allowed"));
    }
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
  allowedHeaders: ["Content-Type", "Authorization", "x-business-id", "x-forwarded-proto"],
}));

const defaultJsonParser = express.json({
  limit: "2mb",
  verify: (req: any, _res, buf) => {
    if (req.originalUrl && req.originalUrl.startsWith("/api/payments/")) {
      req.rawBody = buf;
    }
  },
});

const largeUploadPaths = new Set([
  "/api/media/upload",
  "/api/merchant/media/upload",
  "/api/merchant/ai/scan-menu",
]);

app.use((req, res, next) => {
  if (largeUploadPaths.has(req.path)) {
    return next();
  }
  return defaultJsonParser(req, res, next);
});
app.use(express.urlencoded({ extended: true, limit: "2mb" }));

// Controller Instances
const authController = new AuthController();
const merchantAuthController = new MerchantAuthController();

// --- Consumer Auth Routes (OTP tabanlı) ---
app.post("/api/auth/handshake", handshakeRateLimiter, (req, res) => authController.handshake(req, res));
app.post("/api/auth/request-otp", handshakeMiddleware, otpRateLimiter, validateBody(requestOtpSchema), (req, res) => authController.requestOtp(req, res));
app.post("/api/auth/verify-otp", otpVerifyRateLimiter, validateBody(verifyOtpSchema), (req, res) => authController.verifyOtp(req, res));
app.post("/api/auth/refresh", (req, res) => authController.refreshToken(req, res));
app.post("/api/auth/logout", (req, res) => authController.logout(req, res));
app.get("/api/auth/check-phone/:phone", (req, res) => authController.checkPhoneExists(req, res));

// --- Merchant Auth Routes (E-posta + Şifre tabanlı) ---
app.post("/api/merchant/auth/login", authLoginRateLimiter, (req, res) => merchantAuthController.login(req, res));
app.post("/api/merchant/auth/register", (req, res) => merchantAuthController.register(req, res));
app.post("/api/merchant/auth/submit-revision", authMiddleware, (req, res) => merchantAuthController.submitRevision(req, res));
app.post("/api/merchant/auth/refresh", (req, res) => merchantAuthController.refreshToken(req, res));
app.post("/api/merchant/auth/logout", (req, res) => merchantAuthController.logout(req, res));

// --- API Domain Routes ---
app.use("/api/merchant", merchantRoutes);
app.use("/api/consumer", consumerRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/media", mediaRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/couriers", courierRoutes);
app.use("/api/public", publicRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/events", eventRoutes);

app.get('/health', (req: Request, res: Response) => {
    res.status(200).json({ status: "OK", timestamp: new Date() });
});

// --- Legacy Mock 3D Secure Redirect ---
app.get('/mock-3d-secure', (req: Request, res: Response) => {
    const queryIndex = req.originalUrl.indexOf('?');
    const querySuffix = queryIndex !== -1 ? req.originalUrl.slice(queryIndex) : '';
    res.redirect(302, `/api/payments/sandbox-3ds${querySuffix}`);
});

// Sunucuyu Başlat
app.listen(port, () => {
  console.log(`[Server] Hoppa Backend API listening at http://localhost:${port}`);
  initCronJobs();
});

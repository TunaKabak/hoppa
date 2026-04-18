import express from "express";
import cors from "cors";
import { AuthController } from "./controllers/AuthController";

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Controller Instances
const authController = new AuthController();

// Routes
// Not: metotların express'e düzgün bind edilmesi için ok (arrow) fonksiyon veya .bind(authController) kullanılır
app.post("/api/auth/request-otp", (req, res) => authController.requestOtp(req, res));
app.post("/api/auth/verify-otp", (req, res) => authController.verifyOtp(req, res));

// Health Check
app.get("/", (req, res) => {
  res.status(200).json({ error: false, data: { message: "Hoppa Backend API is running." } });
});

// Sunucuyu Başlat
app.listen(port, () => {
  console.log(`[Server] Hoppa Backend API listening at http://localhost:${port}`);
});

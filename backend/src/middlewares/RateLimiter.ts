import rateLimit from "express-rate-limit";

// 15 dakikada en fazla 5 kez OTP talep edilebilir
export const otpRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 5,
  message: {
    error: true,
    message: "Çok fazla doğrulama kodu talep ettiniz. Lütfen 15 dakika sonra tekrar deneyiniz.",
  },
  standardHeaders: true,
  legacyHeaders: false,
});

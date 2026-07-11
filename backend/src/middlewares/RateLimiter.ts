import rateLimit from "express-rate-limit";

// Global Rate Limiter: IP başına 15 dakikada maksimum 300 istek
export const globalRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 300,
  message: {
    error: true,
    message: "Çok fazla istek gönderdiniz. Lütfen daha sonra tekrar deneyiniz.",
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Handshake Rate Limiter: IP başına 15 dakikada maksimum 10 handshake isteği
export const handshakeRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 10,
  message: {
    error: true,
    message: "Çok fazla güvenlik anahtarı (handshake) talep ettiniz. Lütfen daha sonra tekrar deneyiniz.",
  },
  standardHeaders: true,
  legacyHeaders: false,
});

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


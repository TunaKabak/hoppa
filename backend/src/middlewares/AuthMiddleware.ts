import { Request, Response, NextFunction } from "express";
import { JwtUtils } from "../utils/JwtUtils";

// Express Request tipini güncelleyerek user objesini ekliyoruz
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        role: string;
      };
    }
  }
}

export const authMiddleware = (req: Request, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({ error: true, message: "Yetkilendirme token'ı bulunamadı." });
    return;
  }

  const token = authHeader.split(" ")[1];
  const decodedToken = JwtUtils.verifyToken(token);

  if (!decodedToken) {
    res.status(401).json({ error: true, message: "Geçersiz veya süresi dolmuş token." });
    return;
  }

  // Doğrulanmış veriyi Request nesnesine ata
  req.user = {
    id: decodedToken.id,
    role: decodedToken.role,
  };

  next();
};

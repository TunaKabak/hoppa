import { Request, Response, NextFunction } from "express";
import { JwtUtils } from "../utils/JwtUtils";

export const handshakeMiddleware = (req: Request, res: Response, next: NextFunction): void => {
  const token = req.headers["x-handshake-token"] as string;

  if (!token) {
    res.status(400).json({ error: true, message: "Handshake token eksik veya hatalı." });
    return;
  }

  const decoded = JwtUtils.verifyToken(token);
  if (!decoded || decoded.type !== "handshake") {
    res.status(400).json({ error: true, message: "Geçersiz veya süresi dolmuş handshake token." });
    return;
  }

  next();
};

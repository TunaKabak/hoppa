import { Router, Request, Response } from "express";
import { prisma } from "../config/db";
import { JwtUtils } from "../utils/JwtUtils";
import { realtimeEventService } from "../services/RealtimeEventService";

const router = Router();

function extractHeaderValue(value: string | string[] | undefined): string {
  if (Array.isArray(value)) {
    return (value[0] || "").trim();
  }
  return typeof value === "string" ? value.trim() : "";
}

router.get("/stream", async (req: Request, res: Response): Promise<void> => {
  try {
    const queryToken = typeof req.query.token === "string" ? req.query.token.trim() : "";
    const authHeader = extractHeaderValue(req.headers.authorization);
    const bearerToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7).trim() : "";
    const token = queryToken || bearerToken;

    if (!token) {
      res.status(401).json({ error: true, message: "Yetkilendirme token'ı bulunamadı." });
      return;
    }

    const decoded = JwtUtils.verifyAccessToken(token);
    if (
      !decoded ||
      !decoded.id ||
      decoded.type === "handshake" ||
      decoded.type === "refresh"
    ) {
      res.status(401).json({ error: true, message: "Geçersiz veya süresi dolmuş token." });
      return;
    }

    const channels: string[] = [`user:${decoded.id}`];
    const role = (decoded.role || "").toLowerCase();
    const headerShopId = extractHeaderValue(req.headers["x-business-id"]);
    const queryShopId = typeof req.query.shopId === "string" ? req.query.shopId.trim() : "";
    const requestedShopRef = headerShopId || queryShopId;

    if (role === "super_admin" || role === "admin") {
      channels.push("admin:global");

      if (requestedShopRef) {
        const shop = await prisma.shop.findFirst({
          where: {
            OR: [{ id: requestedShopRef }, { merchantId: requestedShopRef }],
          },
          select: { id: true },
        });
        if (shop) {
          channels.push(`shop:${shop.id}`);
        }
      }
    } else if (role === "merchant") {
      const shop = await prisma.shop.findUnique({
        where: { merchantId: decoded.id },
        select: { id: true },
      });
      if (shop) {
        channels.push(`shop:${shop.id}`);
      }
    }

    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache, no-transform");
    res.setHeader("Connection", "keep-alive");
    res.setHeader("X-Accel-Buffering", "no");

    req.socket?.setTimeout?.(0);
    res.flushHeaders();

    const cleanup = realtimeEventService.subscribe(channels, res);
    req.on("close", cleanup);
    res.on("close", cleanup);
  } catch (error) {
    console.error("[eventRoutes.stream] SSE bağlantı hatası:", error);
    if (!res.headersSent) {
      res.status(500).json({ error: true, message: "Canlı olay akışı başlatılamadı." });
    } else if (!res.writableEnded) {
      res.end();
    }
  }
});

export default router;

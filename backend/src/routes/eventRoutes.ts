import { Router, Request, Response } from "express";
import { prisma } from "../config/db";
import { authMiddleware } from "../middlewares/AuthMiddleware";
import { JwtUtils } from "../utils/JwtUtils";
import { realtimeEventService } from "../services/RealtimeEventService";

const router = Router();

function extractHeaderValue(value: string | string[] | undefined): string {
  if (Array.isArray(value)) {
    return (value[0] || "").trim();
  }
  return typeof value === "string" ? value.trim() : "";
}

router.post("/ticket", authMiddleware, (req: Request, res: Response): void => {
  const userId = req.user?.id;
  const role = req.user?.role || "";
  if (!userId) {
    res.status(401).json({ error: true, message: "Yetkilendirme token'ı geçersiz." });
    return;
  }
  const ticket = realtimeEventService.issueSseTicket(userId, role);
  res.status(200).json({
    error: false,
    data: { ticket, expiresIn: 60 },
  });
});

router.get("/stream", async (req: Request, res: Response): Promise<void> => {
  try {
    if (typeof req.query.token === "string" && req.query.token.trim().length > 0) {
      res.status(401).json({
        error: true,
        message: "URL query token devre dışı bırakıldı. Tek kullanımlık /api/events/ticket kullanın.",
      });
      return;
    }

    const queryTicket = typeof req.query.ticket === "string" ? req.query.ticket.trim() : "";
    const authHeader = extractHeaderValue(req.headers.authorization);
    const bearerToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7).trim() : "";

    let authUserId = "";
    let authRole = "";

    if (queryTicket) {
      const consumed = realtimeEventService.consumeSseTicket(queryTicket);
      if (!consumed) {
        res.status(401).json({ error: true, message: "Geçersiz veya süresi dolmuş SSE bileti." });
        return;
      }
      authUserId = consumed.userId;
      authRole = consumed.role;
    } else if (bearerToken) {
      const decoded = JwtUtils.verifyAccessToken(bearerToken);
      if (
        !decoded ||
        !decoded.id ||
        decoded.type === "handshake" ||
        decoded.type === "refresh"
      ) {
        res.status(401).json({ error: true, message: "Geçersiz veya süresi dolmuş token." });
        return;
      }
      authUserId = decoded.id;
      authRole = decoded.role || "";
    } else {
      res.status(401).json({ error: true, message: "Yetkilendirme bileti veya token'ı bulunamadı." });
      return;
    }

    const channels: string[] = [`user:${authUserId}`];
    const role = authRole.toLowerCase();
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
        where: { merchantId: authUserId },
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

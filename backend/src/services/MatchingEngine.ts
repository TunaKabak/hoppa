import { PrismaClient } from "@prisma/client";
import { DistanceUtils } from "../utils/DistanceUtils";
import { notificationService } from "./NotificationService";

const prisma = new PrismaClient();

export class MatchingEngine {
  /**
   * Kuryesiz ve 10 dakikadan eski siparişleri tarar ve en yakın aktif kuryeye otomatik atar.
   */
  public static async autoAssignOrders(): Promise<void> {
    try {
      const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);

      // 1. Kurye atanmamış ve 10 dakikadan eski aktif siparişleri çek (durumu PENDING veya PREPARING)
      const unassignedOrders = await prisma.order.findMany({
        where: {
          courierId: null,
          status: { in: ["PENDING", "PREPARING"] },
          createdAt: { lte: tenMinutesAgo }
        },
        include: {
          shop: true
        }
      });

      if (unassignedOrders.length === 0) {
        return;
      }

      console.log(`[MatchingEngine] ${unassignedOrders.length} adet kuryesiz sipariş otomatik atama bekliyor.`);

      // 2. O an aktif, nöbetteki (isActive = true) ve onaylı (status = APPROVED) kuryeleri son konumlarıyla birlikte çek
      const activeCouriers = await prisma.courier.findMany({
        where: {
          isActive: true,
          status: "APPROVED"
        },
        include: {
          locations: {
            orderBy: { updatedAt: "desc" },
            take: 1
          }
        }
      });

      if (activeCouriers.length === 0) {
        console.log("[MatchingEngine] Nöbette veya aktif kurye bulunamadı. Atamalar atlanıyor.");
        return;
      }

      for (const order of unassignedOrders) {
        const shop = order.shop;
        if (!shop.latitude || !shop.longitude) {
          console.warn(`[MatchingEngine] Sipariş ${order.id} dükkanının (${shop.name}) koordinatları eksik. Atanamıyor.`);
          continue;
        }

        let nearestCourier: any = null;
        let minDistance = Infinity;

        // Her kuryenin bu dükkana olan mesafesini hesapla
        for (const courier of activeCouriers) {
          const lastLocation = courier.locations[0];
          if (!lastLocation) {
            continue;
          }

          const distance = DistanceUtils.calculateDistance(
            shop.latitude,
            shop.longitude,
            lastLocation.latitude,
            lastLocation.longitude
          );

          // Kuryenin hizmet yarıçapı sınırları içinde mi?
          const maxDistance = courier.maxServiceDistanceKm || 5.0;
          if (distance <= maxDistance && distance < minDistance) {
            minDistance = distance;
            nearestCourier = courier;
          }
        }

        if (nearestCourier) {
          // Siparişi en yakın kuryeye otomatik ata
          await prisma.order.update({
            where: { id: order.id },
            data: {
              courierId: nearestCourier.id,
              status: "PREPARING" // Otomatik hazırlama/atama durumuna çekiyoruz
            }
          });

          console.log(`[MatchingEngine] Sipariş ${order.id} otomatik olarak Kurye ${nearestCourier.name} (${minDistance.toFixed(2)} km) atandı.`);

          // Kuryeye FCM bildirimi gönder
          await notificationService.sendToUser(
            nearestCourier.userId,
            "Sipariş Atandı",
            `Sipariş #${order.id.slice(0, 8)} otomatik olarak size atandı.`,
            { orderId: order.id, type: "NEW_ORDER_ASSIGNED" }
          );
        } else {
          console.log(`[MatchingEngine] Sipariş ${order.id} için hizmet yarıçapında uygun aktif kurye bulunamadı.`);
        }
      }
    } catch (error) {
      console.error("[MatchingEngine] Hata:", error);
    }
  }
}

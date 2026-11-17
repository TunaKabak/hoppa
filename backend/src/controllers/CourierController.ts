import { Request, Response } from "express";
import { prisma } from "../config/db";
import { notificationService } from "../services/NotificationService";
import { realtimeEventService } from "../services/RealtimeEventService";

export class CourierController {
  
  /**
   * Kurye Anlık Konumunu Günceller
   * POST veya PATCH /api/couriers/location
   */
  public async updateLocation(req: Request, res: Response): Promise<void> {
    try {
      const courierUserId = req.user!.id; // JWT'den çözülen kurye kullanıcı ID'si
      const { latitude, longitude, bearing } = req.body;

      if (latitude === undefined || longitude === undefined) {
        res.status(400).json({ error: true, message: "latitude ve longitude zorunludur." });
        return;
      }

      // 1. Kurye profilini bul
      const courier = await prisma.courier.findUnique({ where: { userId: courierUserId } });
      if (!courier) {
        res.status(404).json({ error: true, message: "Kurye profili bulunamadı." });
        return;
      }

      // 2. Konum kaydını Upsert (varsa güncelle yoksa ekle) et
      const location = await prisma.courierLocation.upsert({
        where: { courierId: courier.id }, // courierId @unique kısıtı üzerinden kilit
        update: {
          latitude: parseFloat(latitude.toString()),
          longitude: parseFloat(longitude.toString()),
          bearing: parseFloat((bearing || 0.0).toString()),
          updatedAt: new Date()
        },
        create: {
          courierId: courier.id, // id, schema'nın @default(uuid()) tarafından üretilir
          latitude: parseFloat(latitude.toString()),
          longitude: parseFloat(longitude.toString()),
          bearing: parseFloat((bearing || 0.0).toString())
        }
      });

      try {
        const activeOrders = await prisma.order.findMany({
          where: {
            courierId: courier.id,
            status: { in: ["PREPARING", "READY_FOR_PICKUP", "ON_THE_WAY"] },
          },
          select: { id: true, shopId: true, consumerId: true },
        });

        const locationPayload = {
          courierId: courier.id,
          courierName: courier.name,
          latitude: location.latitude,
          longitude: location.longitude,
          bearing: location.bearing,
          orderIds: activeOrders.map((o) => o.id),
          updatedAt: location.updatedAt.toISOString(),
        };

        const uniqueShopIds = Array.from(new Set(activeOrders.map((o) => o.shopId)));
        const uniqueConsumerIds = Array.from(new Set(activeOrders.map((o) => o.consumerId)));

        for (const shopId of uniqueShopIds) {
          realtimeEventService.publishToShop(shopId, "COURIER_LOCATION_UPDATED", locationPayload);
        }
        for (const consumerId of uniqueConsumerIds) {
          realtimeEventService.publishToUser(consumerId, "COURIER_LOCATION_UPDATED", locationPayload);
        }
        realtimeEventService.publishToAdmin("COURIER_LOCATION_UPDATED", locationPayload);
      } catch (sseError) {
        console.error("[CourierController.updateLocation] SSE COURIER_LOCATION_UPDATED yayın hatası:", sseError);
      }

      res.status(200).json({ error: false, data: location });
    } catch (error: any) {
      console.error("Kurye konum güncelleme hatası:", error);
      res.status(500).json({ error: true, message: "Konum kaydedilemedi." });
    }
  }

  /**
   * Kuryenin Anlık Konumunu Getir
   * GET /api/consumer/couriers/:id/location
   */
  public async getCourierLocation(req: Request, res: Response): Promise<void> {
    try {
      const id = String(req.params.id);
      const userId = req.user?.id;
      const role = (req.user?.role || "").toLowerCase();

      if (!userId) {
        res.status(401).json({ error: true, message: "Yetkilendirme gereklidir." });
        return;
      }

      const isAdmin = role === "super_admin" || role === "admin";
      if (!isAdmin) {
        const ownCourier = await prisma.courier.findFirst({
          where: { id, userId },
          select: { id: true },
        });
        if (!ownCourier) {
          const activeOrder = await prisma.order.findFirst({
            where: {
              courierId: id,
              status: { in: ["PENDING", "PREPARING", "READY_FOR_PICKUP", "ON_THE_WAY"] },
              OR: [
                { consumerId: userId },
                { shop: { merchantId: userId } },
              ],
            },
            select: { id: true },
          });
          if (!activeOrder) {
            res.status(403).json({
              error: true,
              message: "Bu kuryenin canlı konumunu görüntüleme yetkiniz bulunmuyor.",
            });
            return;
          }
        }
      }

      const location = await prisma.courierLocation.findUnique({
        where: { courierId: id },
      });

      if (!location) {
        res.status(404).json({ error: true, message: "Kurye konumu bulunamadı." });
        return;
      }

      res.status(200).json({ error: false, data: location });
    } catch (error: any) {
      console.error("Kurye konum getirme hatası:", error);
      res.status(500).json({ error: true, message: "Konum alınamadı." });
    }
  }

  /**
   * Kuryeye Atanmış Aktif Siparişleri Getir
   * GET /api/couriers/orders
   */
  /**
   * Kurye profilini, onay durumunu (status), nöbet durumunu (isActive) ve günlük istatistiğini döndürür.
   */
  public async getMyProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: true, message: "Yetkisiz erişim." });
        return;
      }

      const [user, courier] = await Promise.all([
        prisma.user.findUnique({
          where: { id: userId },
          select: { id: true, name: true, surname: true, phone: true },
        }),
        prisma.courier.findUnique({
          where: { userId },
          include: {
            shops: {
              include: {
                shop: {
                  select: {
                    id: true,
                    name: true,
                    type: true,
                    address: true,
                    latitude: true,
                    longitude: true,
                    merchant: {
                      select: {
                        businessPhone: true,
                        phone: true,
                      },
                    },
                  },
                },
              },
            },
          },
        }),
      ]);

      if (!courier) {
        res.status(200).json({
          error: false,
          data: {
            hasProfile: false,
            status: "NOT_APPLIED",
            isActive: false,
            todayDeliveriesCount: 0,
            totalDeliveriesCount: 0,
            shops: [],
            user,
          },
        });
        return;
      }

      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);

      const [todayDeliveriesCount, totalDeliveriesCount] = await Promise.all([
        prisma.order.count({
          where: {
            courierId: courier.id,
            status: "DELIVERED",
            updatedAt: { gte: todayStart },
          },
        }),
        prisma.order.count({
          where: {
            courierId: courier.id,
            status: "DELIVERED",
          },
        }),
      ]);

      const mappedShops = courier.shops.map((cs) => ({
        id: cs.id,
        courierId: cs.courierId,
        shopId: cs.shopId,
        createdAt: cs.createdAt,
        shop: {
          id: cs.shop.id,
          name: cs.shop.name,
          type: cs.shop.type,
          address: cs.shop.address,
          latitude: cs.shop.latitude,
          longitude: cs.shop.longitude,
          phone: cs.shop.merchant?.businessPhone || cs.shop.merchant?.phone || null,
        },
      }));

      res.status(200).json({
        error: false,
        data: {
          hasProfile: true,
          id: courier.id,
          userId: courier.userId,
          name: courier.name,
          phoneNumber: courier.phoneNumber,
          vehicleType: courier.vehicleType,
          vehiclePlate: courier.vehiclePlate,
          status: courier.status,
          isActive: courier.isActive,
          maxServiceDistanceKm: courier.maxServiceDistanceKm,
          shops: mappedShops,
          todayDeliveriesCount,
          totalDeliveriesCount,
          user,
        },
      });
    } catch (error) {
      console.error("[CourierController.getMyProfile] Hata:", error);
      res.status(500).json({ error: true, message: "Kurye profili alınırken hata oluştu." });
    }
  }

  /**
   * Giriş yapmış kullanıcının kurye başvurusu yapmasını (veya reddedildiyse yeniden başvurmasını) sağlar.
   */
  public async applyAuthenticated(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: true, message: "Yetkisiz erişim." });
        return;
      }

      const { name, vehicleType, vehiclePlate, maxServiceDistanceKm } = req.body as {
        name?: string;
        vehicleType?: string;
        vehiclePlate?: string;
        maxServiceDistanceKm?: number;
      };

      const validVehicles = ["MOTORCYCLE", "CAR", "BICYCLE", "FOOT"] as const;
      if (!vehicleType || !validVehicles.includes(vehicleType as (typeof validVehicles)[number])) {
        res.status(400).json({ error: true, message: "Geçerli bir araç tipi seçmelisiniz (MOTORCYCLE, CAR, BICYCLE, FOOT)." });
        return;
      }

      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, name: true, surname: true, phone: true },
      });

      if (!user) {
        res.status(404).json({ error: true, message: "Kullanıcı bulunamadı." });
        return;
      }

      const resolvedName =
        (name && name.trim()) ||
        `${user.name || ""} ${user.surname || ""}`.trim() ||
        user.phone;
      const resolvedPlate = vehiclePlate ? vehiclePlate.trim().toUpperCase() : null;
      const resolvedDistance =
        typeof maxServiceDistanceKm === "number" && maxServiceDistanceKm > 0
          ? maxServiceDistanceKm
          : 15;

      const existing = await prisma.courier.findUnique({ where: { userId } });
      if (existing) {
        if (existing.status !== "REJECTED") {
          res.status(409).json({
            error: true,
            message: "Zaten aktif veya incelemede olan bir kurye başvurunuz bulunmaktadır.",
            data: existing,
          });
          return;
        }

        const updated = await prisma.courier.update({
          where: { id: existing.id },
          data: {
            name: resolvedName,
            phoneNumber: user.phone,
            vehicleType: vehicleType as (typeof validVehicles)[number],
            vehiclePlate: resolvedPlate,
            maxServiceDistanceKm: resolvedDistance,
            status: "APPLIED",
            isActive: false,
          },
        });

        try {
          realtimeEventService.publishToAdmin("ADMIN_ALERT", {
            alertType: "COURIER_APPLIED",
            courierId: updated.id,
            name: updated.name,
            phoneNumber: updated.phoneNumber,
            vehicleType: updated.vehicleType,
            status: updated.status,
          });
        } catch (sseError) {
          console.error("[CourierController.applyAuthenticated] SSE ADMIN_ALERT yayın hatası:", sseError);
        }

        res.status(200).json({ error: false, message: "Kurye başvurunuz yeniden gönderildi.", data: updated });
        return;
      }

      const created = await prisma.courier.create({
        data: {
          userId,
          name: resolvedName,
          phoneNumber: user.phone,
          vehicleType: vehicleType as (typeof validVehicles)[number],
          vehiclePlate: resolvedPlate,
          maxServiceDistanceKm: resolvedDistance,
          status: "APPLIED",
          isActive: false,
        },
      });

      try {
        realtimeEventService.publishToAdmin("ADMIN_ALERT", {
          alertType: "COURIER_APPLIED",
          courierId: created.id,
          name: created.name,
          phoneNumber: created.phoneNumber,
          vehicleType: created.vehicleType,
          status: created.status,
        });
      } catch (sseError) {
        console.error("[CourierController.applyAuthenticated] SSE ADMIN_ALERT yayın hatası:", sseError);
      }

      res.status(201).json({ error: false, message: "Kurye başvurunuz alındı.", data: created });
    } catch (error) {
      console.error("[CourierController.applyAuthenticated] Hata:", error);
      res.status(500).json({ error: true, message: "Kurye başvurusu kaydedilemedi." });
    }
  }

  public async getAssignedOrders(req: Request, res: Response): Promise<void> {
    try {
      const courierUserId = req.user!.id;
      const courier = await prisma.courier.findUnique({ where: { userId: courierUserId } });
      if (!courier) {
        res.status(404).json({ error: true, message: "Kurye profili bulunamadı." });
        return;
      }

      const activeOrders = await prisma.order.findMany({
        where: {
          courierId: courier.id,
          status: { in: ["PREPARING", "READY_FOR_PICKUP", "ON_THE_WAY"] }
        },
        include: {
          shop: true,
          consumer: {
            select: {
              id: true,
              name: true,
              surname: true,
              phone: true,
            },
          },
          address: true,
          items: {
            include: {
              product: true,
              options: true,
            }
          }
        },
        orderBy: { createdAt: "desc" },
      });

      res.status(200).json({ error: false, data: activeOrders });
    } catch (error: any) {
      console.error("Kurye atanmış sipariş hatası:", error);
      res.status(500).json({ error: true, message: "Siparişler getirilemedi." });
    }
  }

  /**
   * Siparişi Teslim Edildi Olarak İşaretle
   * PATCH /api/couriers/orders/:id/deliver
   */
  public async deliverOrder(req: Request, res: Response): Promise<void> {
    try {
      const courierUserId = req.user!.id;
      const orderId = req.params.id as string;

      const courier = await prisma.courier.findUnique({ where: { userId: courierUserId } });
      if (!courier) {
        res.status(404).json({ error: true, message: "Kurye profili bulunamadı." });
        return;
      }

      const order = await prisma.order.findUnique({ where: { id: orderId } });
      if (!order) {
        res.status(404).json({ error: true, message: "Sipariş bulunamadı." });
        return;
      }

      if (order.courierId !== courier.id) {
        res.status(403).json({ error: true, message: "Bu sipariş size atanmamış." });
        return;
      }

      let updatedPaymentStatus = undefined;
      if (order.paymentMethod !== "ONLINE_PAYMENT") {
        updatedPaymentStatus = "SUCCESS";
      }

      const updatedOrder = await prisma.order.update({
        where: { id: orderId },
        data: {
          status: "DELIVERED",
          ...(updatedPaymentStatus ? { paymentStatus: updatedPaymentStatus as any } : {})
        }
      });

      try {
        await notificationService.sendToUser(
          updatedOrder.consumerId,
          "Siparişiniz Teslim Edildi! 🎉",
          "Siparişiniz başarıyla teslim edildi. Afiyet olsun!",
          { orderId: updatedOrder.id, status: "DELIVERED" }
        );
      } catch (notifyError) {
        console.error("[CourierController.deliverOrder] Push bildirimi gönderilemedi:", notifyError);
      }

      try {
        const deliverPayload = {
          orderId: updatedOrder.id,
          shopId: updatedOrder.shopId,
          consumerId: updatedOrder.consumerId,
          status: updatedOrder.status,
          paymentStatus: updatedOrder.paymentStatus,
          courierId: courier.id,
        };
        realtimeEventService.publishToShop(updatedOrder.shopId, "ORDER_STATUS_UPDATED", deliverPayload);
        realtimeEventService.publishToUser(updatedOrder.consumerId, "ORDER_STATUS_UPDATED", deliverPayload);
      } catch (sseError) {
        console.error("[CourierController.deliverOrder] SSE ORDER_STATUS_UPDATED yayın hatası:", sseError);
      }

      res.status(200).json({ error: false, message: "Sipariş başarıyla teslim edildi.", data: updatedOrder });
    } catch (error: any) {
      console.error("Kurye teslim hatası:", error);
      res.status(500).json({ error: true, message: "Sipariş güncellenemedi." });
    }
  }

  /**
   * Kuryenin siparişi mağazadan teslim alıp yola çıktığını işaretler (ON_THE_WAY).
   */
  public async pickupOrder(req: Request, res: Response): Promise<void> {
    try {
      const courierUserId = req.user!.id;
      const orderId = String(req.params.id);

      const courier = await prisma.courier.findUnique({ where: { userId: courierUserId } });
      if (!courier) {
        res.status(404).json({ error: true, message: "Kurye profili bulunamadı." });
        return;
      }

      if (courier.status !== "APPROVED") {
        res.status(403).json({ error: true, message: "Kurye hesabınız henüz onaylanmamış." });
        return;
      }

      const order = await prisma.order.findUnique({
        where: { id: orderId },
        include: { shop: { select: { id: true, name: true } } },
      });

      if (!order || order.courierId !== courier.id) {
        res.status(404).json({ error: true, message: "Size atanmış böyle bir sipariş bulunamadı." });
        return;
      }

      if (order.status !== "PREPARING" && order.status !== "READY_FOR_PICKUP") {
        res.status(400).json({
          error: true,
          message: `Bu sipariş (${order.status}) teslim alınmaya uygun aşamada değil.`,
        });
        return;
      }

      const updatedOrder = await prisma.order.update({
        where: { id: orderId },
        data: { status: "ON_THE_WAY" },
      });

      try {
        await notificationService.sendToUser(
          order.consumerId,
          "Kurye Yola Çıktı! 🛵",
          `${order.shop?.name || "Mağaza"} siparişiniz kuryemiz tarafından teslim alındı ve size doğru yola çıktı.`,
          { orderId: updatedOrder.id, status: "ON_THE_WAY" }
        );
      } catch (notifyError) {
        console.error("[CourierController.pickupOrder] Push bildirimi gönderilemedi:", notifyError);
      }

      try {
        const pickupPayload = {
          orderId: updatedOrder.id,
          shopId: updatedOrder.shopId,
          consumerId: updatedOrder.consumerId,
          status: updatedOrder.status,
          paymentStatus: updatedOrder.paymentStatus,
          courierId: courier.id,
        };
        realtimeEventService.publishToShop(updatedOrder.shopId, "ORDER_STATUS_UPDATED", pickupPayload);
        realtimeEventService.publishToUser(updatedOrder.consumerId, "ORDER_STATUS_UPDATED", pickupPayload);
      } catch (sseError) {
        console.error("[CourierController.pickupOrder] SSE ORDER_STATUS_UPDATED yayın hatası:", sseError);
      }

      res.status(200).json({
        error: false,
        message: "Sipariş mağazadan teslim alındı ve yola çıkıldı.",
        data: updatedOrder,
      });
    } catch (error) {
      console.error("[CourierController.pickupOrder] Hata:", error);
      res.status(500).json({ error: true, message: "Sipariş teslim alma işlemi tamamlanamadı." });
    }
  }

  /**
   * Kuryenin tamamladığı (DELIVERED) sipariş geçmişini ve özet metrikleri döndürür.
   */
  public async getOrderHistory(req: Request, res: Response): Promise<void> {
    try {
      const courierUserId = req.user!.id;
      const courier = await prisma.courier.findUnique({ where: { userId: courierUserId } });
      if (!courier) {
        res.status(404).json({ error: true, message: "Kurye profili bulunamadı." });
        return;
      }

      const page = Math.max(1, Number(req.query.page) || 1);
      const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 20));
      const skip = (page - 1) * limit;

      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);

      const weekStart = new Date(todayStart);
      weekStart.setDate(weekStart.getDate() - 7);

      const [orders, totalSummary, todaySummary, weekSummary] = await Promise.all([
        prisma.order.findMany({
          where: { courierId: courier.id, status: "DELIVERED" },
          include: {
            shop: { select: { id: true, name: true, address: true } },
            address: true,
            items: {
              include: {
                product: { select: { id: true, name: true } },
              },
            },
          },
          orderBy: { updatedAt: "desc" },
          skip,
          take: limit,
        }),
        prisma.order.aggregate({
          where: { courierId: courier.id, status: "DELIVERED" },
          _count: { id: true },
          _sum: { deliveryFee: true, totalAmount: true },
        }),
        prisma.order.aggregate({
          where: {
            courierId: courier.id,
            status: "DELIVERED",
            updatedAt: { gte: todayStart },
          },
          _count: { id: true },
          _sum: { deliveryFee: true },
        }),
        prisma.order.aggregate({
          where: {
            courierId: courier.id,
            status: "DELIVERED",
            updatedAt: { gte: weekStart },
          },
          _count: { id: true },
          _sum: { deliveryFee: true },
        }),
      ]);

      const totalCount = totalSummary._count.id;
      res.status(200).json({
        error: false,
        data: {
          orders,
          summary: {
            todayCount: todaySummary._count.id,
            todayDeliveryFeeTotal: Number(todaySummary._sum.deliveryFee || 0),
            weekCount: weekSummary._count.id,
            weekDeliveryFeeTotal: Number(weekSummary._sum.deliveryFee || 0),
            totalCount,
            totalDeliveryFeeTotal: Number(totalSummary._sum.deliveryFee || 0),
          },
          pagination: {
            page,
            limit,
            totalCount,
            totalPages: Math.max(1, Math.ceil(totalCount / limit)),
          },
        },
      });
    } catch (error) {
      console.error("[CourierController.getOrderHistory] Hata:", error);
      res.status(500).json({ error: true, message: "Teslimat geçmişi alınırken hata oluştu." });
    }
  }

  /**
   * Kurye Başvurusu Alır
   * POST /api/couriers/apply
   */
  public async apply(req: Request, res: Response): Promise<void> {
    try {
      const { name, phoneNumber, vehiclePlate, vehicleType, workingHours, maxServiceDistanceKm } = req.body;

      if (!name || !phoneNumber) {
        res.status(400).json({ error: true, message: "İsim ve telefon numarası zorunludur." });
        return;
      }

      // 1. Kullanıcı kaydı kontrol et/yarat
      let user = await prisma.user.findUnique({ where: { phone: phoneNumber } });
      if (user) {
        // Eğer zaten kurye ise hata ver
        const existingCourier = await prisma.courier.findUnique({ where: { userId: user.id } });
        if (existingCourier) {
          res.status(400).json({ error: true, message: "Bu telefon numarasıyla kayıtlı bir kurye zaten mevcut." });
          return;
        }
      } else {
        user = await prisma.user.create({
          data: {
            phone: phoneNumber,
            role: "user",
            name: name
          }
        });
      }

      // 2. Kurye profilini oluştur (durumu APPLIED olarak başlar)
      const courier = await prisma.courier.create({
        data: {
          userId: user.id,
          name,
          phoneNumber,
          vehiclePlate,
          vehicleType: (vehicleType || "MOTORCYCLE") as any,
          workingHours: workingHours || null,
          maxServiceDistanceKm: maxServiceDistanceKm ? parseFloat(maxServiceDistanceKm.toString()) : 5.0,
          status: "APPLIED"
        }
      });

      try {
        realtimeEventService.publishToAdmin("ADMIN_ALERT", {
          alertType: "COURIER_APPLIED",
          courierId: courier.id,
          name: courier.name,
          phoneNumber: courier.phoneNumber,
          vehicleType: courier.vehicleType,
          status: courier.status,
        });
      } catch (sseError) {
        console.error("[CourierController.apply] SSE ADMIN_ALERT yayın hatası:", sseError);
      }

      res.status(201).json({ error: false, message: "Kurye başvurusu başarıyla alındı.", data: courier });
    } catch (error: any) {
      console.error("Kurye başvuru hatası:", error);
      res.status(500).json({ error: true, message: "Başvuru kaydedilemedi." });
    }
  }

  /**
   * Kurye Nöbet Durumunu Değiştirir (On/Off Duty)
   * PATCH /api/couriers/toggle-duty
   */
  public async toggleDuty(req: Request, res: Response): Promise<void> {
    try {
      const courierUserId = req.user!.id;
      const { isActive } = req.body;

      if (isActive === undefined) {
        res.status(400).json({ error: true, message: "isActive alanı zorunludur." });
        return;
      }

      // 1. Kuryeyi bul
      const courier = await prisma.courier.findUnique({ where: { userId: courierUserId } });
      if (!courier) {
        res.status(404).json({ error: true, message: "Kurye profili bulunamadı." });
        return;
      }

      // 2. Onay durumunu kontrol et
      if (isActive && courier.status !== "APPROVED") {
        res.status(403).json({
          error: true,
          message: `Nöbete çıkmak için hesabınızın onaylanması gerekmektedir. Mevcut durumunuz: ${courier.status}`
        });
        return;
      }

      // 3. Durumu güncelle
      const updatedCourier = await prisma.courier.update({
        where: { id: courier.id },
        data: { isActive: !!isActive }
      });

      res.status(200).json({
        error: false,
        message: isActive ? "Nöbet başladı. 🟢" : "Nöbet bitti. 🔴",
        data: updatedCourier
      });
    } catch (error: any) {
      console.error("Nöbet durumu güncelleme hatası:", error);
      res.status(500).json({ error: true, message: "Nöbet durumu güncellenemedi." });
    }
  }

  /**
   * Kurye araç seçeneklerini getirir
   * GET /api/couriers/vehicle-options
   */
  public async getVehicleOptions(req: Request, res: Response): Promise<void> {
    try {
      const options = await prisma.vehicleOption.findMany({
        orderBy: { createdAt: "asc" }
      });
      res.status(200).json({ error: false, data: options });
    } catch (error: any) {
      console.error("Araç seçenekleri getirme hatası:", error);
      res.status(500).json({ error: true, message: "Araç seçenekleri getirilemedi." });
    }
  }
}


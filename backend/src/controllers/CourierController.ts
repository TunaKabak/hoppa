import { Request, Response } from "express";
import { prisma } from "../config/db";

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
        where: { id: courier.id }, // Courier ID ile birebir kilitliyoruz (Mükerrer satır kirliliğini önler)
        update: {
          latitude: parseFloat(latitude.toString()),
          longitude: parseFloat(longitude.toString()),
          bearing: parseFloat((bearing || 0.0).toString()),
          updatedAt: new Date()
        },
        create: {
          id: courier.id,
          courierId: courier.id,
          latitude: parseFloat(latitude.toString()),
          longitude: parseFloat(longitude.toString()),
          bearing: parseFloat((bearing || 0.0).toString())
        }
      });

      res.status(200).json({ error: false, data: location });
    } catch (error: any) {
      console.error("Kurye konum güncelleme hatası:", error);
      res.status(500).json({ error: true, message: error.message || "Konum kaydedilemedi." });
    }
  }

  /**
   * Kuryeye Atanmış Aktif Siparişleri Getir
   * GET /api/couriers/orders
   */
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
          status: { in: ["PREPARING", "ON_THE_WAY"] } // Sadece teslimat aşamasındakiler
        },
        include: {
          shop: true,
          address: true,
          items: {
            include: {
              product: true
            }
          }
        }
      });

      res.status(200).json({ error: false, data: activeOrders });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message || "Siparişler getirilemedi." });
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

      res.status(200).json({ error: false, message: "Sipariş başarıyla teslim edildi.", data: updatedOrder });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message || "Sipariş güncellenemedi." });
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

      res.status(201).json({ error: false, message: "Kurye başvurusu başarıyla alındı.", data: courier });
    } catch (error: any) {
      console.error("Kurye başvuru hatası:", error);
      res.status(500).json({ error: true, message: error.message || "Başvuru kaydedilemedi." });
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
      res.status(500).json({ error: true, message: error.message || "Nöbet durumu güncellenemedi." });
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
      res.status(500).json({ error: true, message: error.message || "Araç seçenekleri getirilemedi." });
    }
  }
}


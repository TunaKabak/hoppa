import { Request, Response } from "express";
import { prisma } from "../config/db";

export class CourierController {
  /**
   * Kuryenin anlık konumunu günceller/kaydeder (Upsert).
   * POST veya PATCH /api/couriers/location
   */
  public async updateLocation(req: Request, res: Response): Promise<void> {
    try {
      const { latitude, longitude, bearing, courierId: bodyCourierId } = req.body;

      // Kurye kimliğini belirle: Giriş yapmış kullanıcının ID'si veya body'deki courierId
      let courierId = req.user?.id || bodyCourierId;

      if (!courierId) {
        // Eğer hiçbir ID bulunamadıysa veritabanındaki varsayılan kuryeyi bul veya oluştur
        const defaultCourier = await prisma.courier.findFirst();
        if (defaultCourier) {
          courierId = defaultCourier.id;
        } else {
          const newCourier = await prisma.courier.create({
            data: {
              name: "Süleyman Kurye",
              phoneNumber: "+905555555555",
              vehiclePlate: "34 HO 9999",
              isActive: true,
            },
          });
          courierId = newCourier.id;
        }
      } else {
        // Kuryenin DB'de olup olmadığını doğrula, yoksa otomatik oluştur
        const courier = await prisma.courier.findUnique({
          where: { id: courierId },
        });

        if (!courier) {
          await prisma.courier.create({
            data: {
              id: courierId,
              name: "Simülasyon Kuryesi",
              phoneNumber: `+90-${courierId.substring(0, 8)}`,
              vehiclePlate: "34 HO 9999",
              isActive: true,
            },
          });
        }
      }

      if (latitude === undefined || longitude === undefined) {
        res.status(400).json({ error: true, message: "latitude ve longitude zorunludur." });
        return;
      }

      // Kurye konumunu güncelle veya oluştur (Upsert)
      const latVal = parseFloat(latitude.toString());
      const lngVal = parseFloat(longitude.toString());
      const bearingVal = parseFloat((bearing ?? 0).toString());

      const locationRecord = await prisma.courierLocation.upsert({
        where: { courierId: courierId },
        update: {
          latitude: latVal,
          longitude: lngVal,
          bearing: bearingVal,
          updatedAt: new Date(),
        },
        create: {
          courierId: courierId,
          latitude: latVal,
          longitude: lngVal,
          bearing: bearingVal,
        },
      });

      res.status(200).json({
        error: false,
        message: "Konum başarıyla güncellendi.",
        data: locationRecord,
      });
    } catch (error: any) {
      console.error("[CourierController] Konum güncellenirken hata:", error);
      res.status(500).json({ error: true, message: error.message });
    }
  }
}

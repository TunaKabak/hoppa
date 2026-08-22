import { Request, Response } from "express";
import { PrismaClient, MerchantStatus, CourierStatus, VehicleType } from "@prisma/client";

const prisma = new PrismaClient();

export class SuperAdminController {
  /**
   * GET /api/admin/merchants/pending
   * Sadece PENDING veya REVISION statüsünde olan ve onay bekleyen satıcı başvurularını listeler.
   */
  async getPendingMerchants(req: Request, res: Response) {
    try {
      const pendingMerchants = await prisma.merchant.findMany({
        where: {
          status: {
            in: ["PENDING", "REVISION", "ON_HOLD"],
          },
        },
        orderBy: {
          createdAt: "desc",
        },
      });

      return res.status(200).json({ error: false, data: pendingMerchants });
    } catch (error: any) {
      console.error("[SuperAdminController.getPendingMerchants] Error:", error);
      return res.status(500).json({ error: true, message: "Sunucu hatası oluştu." });
    }
  }

  /**
   * PUT /api/admin/merchants/:id/status
   * Body: { status: "ACTIVE" | "REJECTED" | "REVISION" | "ON_HOLD", revisionMessage?: string }
   * Satıcı başvuru durumunu günceller. Eğer ACTIVE yapılıyorsa otomatik düzgün bir boş Shop açar.
   */
  async updateMerchantStatus(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const { status, revisionMessage } = req.body;

      if (!id || !status) {
        return res.status(400).json({ error: true, message: "Eksik parametre." });
      }

      // Check if merchant exists
      const merchant = await prisma.merchant.findUnique({ where: { id } });
      if (!merchant) {
        return res.status(404).json({ error: true, message: "Satıcı bulunamadı." });
      }

      // Update basic details
      const updateData: any = {
        status: status as MerchantStatus,
      };

      if (revisionMessage !== undefined) {
        updateData.revisionMessage = revisionMessage;
      }

      // Transaction ile hem merchant güncellenip hem shop oluşturulması garanti altına alınır
      const result = await prisma.$transaction(async (tx) => {
        const updatedMerchant = await tx.merchant.update({
          where: { id },
          data: updateData,
        });

        // Eğer ACTIVE'e çekildiyse ve henüz dükkanı yoksa boş bir dükkan aç
        if (status === "ACTIVE") {
          const existingShop = await tx.shop.findUnique({
            where: { merchantId: id },
          });

          if (!existingShop) {
            await tx.shop.create({
              data: {
                merchantId: id,
                name: merchant.businessName || "Yeni Dükkan",
                address: merchant.fullAddress,
                taxNumber: merchant.taxNumber,
                isActive: false, // İlk açılışta kapalı başlasın
                type: merchant.merchantType, // Eklendi
              },
            });
          }
        }

        return updatedMerchant;
      });

      return res.status(200).json({ error: false, data: result, message: "Satıcı durumu başarıyla güncellendi." });
    } catch (error: any) {
      console.error("[SuperAdminController.updateMerchantStatus] Error:", error);
      return res.status(500).json({ error: true, message: "Sunucu hatası oluştu." });
    }
  }

  /**
   * GET /api/admin/couriers
   * Bütün kuryeleri listeler. İsteğe bağlı olarak status ve isActive filtreleri alabilir.
   */
  async getCouriers(req: Request, res: Response) {
    try {
      const { status, isActive } = req.query;
      const where: any = {};
      if (status) {
        where.status = status as any;
      }
      if (isActive !== undefined) {
        where.isActive = isActive === "true";
      }

      const couriers = await prisma.courier.findMany({
        where,
        include: {
          shops: {
            include: {
              shop: true
            }
          }
        },
        orderBy: {
          createdAt: "desc"
        }
      });

      return res.status(200).json({ error: false, data: couriers });
    } catch (error: any) {
      console.error("[SuperAdminController.getCouriers] Error:", error);
      return res.status(500).json({ error: true, message: "Sunucu hatası oluştu." });
    }
  }

  /**
   * PUT /api/admin/couriers/:id/status
   * Body: { status: CourierStatus, vehiclePlate?: string, vehicleType?: VehicleType, maxServiceDistanceKm?: number }
   * Kuryenin durumunu ve temel özelliklerini günceller.
   */
  async updateCourierStatus(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const { status, vehiclePlate, vehicleType, maxServiceDistanceKm } = req.body;

      if (!id || !status) {
        return res.status(400).json({ error: true, message: "Eksik parametre." });
      }

      const courier = await prisma.courier.findUnique({ where: { id } });
      if (!courier) {
        return res.status(404).json({ error: true, message: "Kurye bulunamadı." });
      }

      const updatedCourier = await prisma.$transaction(async (tx) => {
        const uCourier = await tx.courier.update({
          where: { id },
          data: {
            status: status as CourierStatus,
            ...(vehiclePlate !== undefined ? { vehiclePlate } : {}),
            ...(vehicleType !== undefined ? { vehicleType } : {}),
            ...(maxServiceDistanceKm !== undefined ? { maxServiceDistanceKm: parseFloat(maxServiceDistanceKm.toString()) } : {})
          }
        });

        if (status === "APPROVED") {
          await tx.user.update({
            where: { id: courier.userId },
            data: { role: "courier" }
          });
        }

        return uCourier;
      });

      return res.status(200).json({ error: false, data: updatedCourier, message: "Kurye durumu başarıyla güncellendi." });
    } catch (error: any) {
      console.error("[SuperAdminController.updateCourierStatus] Error:", error);
      return res.status(500).json({ error: true, message: "Sunucu hatası oluştu." });
    }
  }

  /**
   * POST /api/admin/couriers/:id/shops
   * Body: { shopId: string }
   * Kuryeyi belirli bir dükkana tanımlar (Dedicated courier).
   */
  async assignCourierToShop(req: Request, res: Response) {
    try {
      const courierId = req.params.id as string;
      const { shopId } = req.body;

      if (!courierId || !shopId) {
        return res.status(400).json({ error: true, message: "Eksik parametre." });
      }

      // Kurye ve dükkanın varlığını kontrol et
      const courier = await prisma.courier.findUnique({ where: { id: courierId } });
      if (!courier) {
        return res.status(404).json({ error: true, message: "Kurye bulunamadı." });
      }

      const shop = await prisma.shop.findUnique({ where: { id: shopId } });
      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const assignment = await prisma.courierShop.upsert({
        where: {
          courierId_shopId: { courierId, shopId }
        },
        create: {
          courierId,
          shopId
        },
        update: {}
      });

      return res.status(200).json({ error: false, data: assignment, message: "Kurye dükkana başarıyla atandı." });
    } catch (error: any) {
      console.error("[SuperAdminController.assignCourierToShop] Error:", error);
      return res.status(500).json({ error: true, message: "Sunucu hatası oluştu." });
    }
  }

  /**
   * DELETE /api/admin/couriers/:id/shops/:shopId
   * Kuryenin dükkan atamasını kaldırır.
   */
  async removeCourierFromShop(req: Request, res: Response) {
    try {
      const courierId = req.params.id as string;
      const shopId = req.params.shopId as string;

      if (!courierId || !shopId) {
        return res.status(400).json({ error: true, message: "Eksik parametre." });
      }

      await prisma.courierShop.deleteMany({
        where: { courierId, shopId }
      });

      return res.status(200).json({ error: false, message: "Kurye dükkan ataması kaldırıldı." });
    } catch (error: any) {
      console.error("[SuperAdminController.removeCourierFromShop] Error:", error);
      return res.status(500).json({ error: true, message: "Sunucu hatası oluştu." });
    }
  }

  /**
   * GET /api/admin/service-zones
   * KKTC Genel Platform Hizmet Alanları ve Poligon Sınırlarını döner.
   */
  async getServiceZones(req: Request, res: Response) {
    try {
      const config = await prisma.systemConfig.findUnique({
        where: { key: "KKTC_SERVICE_ZONES" }
      });

      if (!config || !config.value) {
        return res.status(200).json({ error: false, data: [] });
      }

      try {
        const zones = JSON.parse(config.value);
        return res.status(200).json({ error: false, data: Array.isArray(zones) ? zones : [] });
      } catch (parseErr) {
        return res.status(200).json({ error: false, data: [] });
      }
    } catch (error: any) {
      console.error("[SuperAdminController.getServiceZones] Error:", error);
      return res.status(500).json({ error: true, message: "Hizmet bölgeleri getirilemedi." });
    }
  }

  /**
   * PUT /api/admin/service-zones
   * Body: { zones: Array<ServiceZone> }
   * KKTC Genel Platform Hizmet Alanlarını ve Poligon Sınırlarını kaydeder.
   */
  async updateServiceZones(req: Request, res: Response) {
    try {
      const { zones } = req.body;

      if (!Array.isArray(zones)) {
        return res.status(400).json({ error: true, message: "Geçersiz veri formatı. 'zones' dizisi beklenmektedir." });
      }

      const updated = await prisma.systemConfig.upsert({
        where: { key: "KKTC_SERVICE_ZONES" },
        create: {
          key: "KKTC_SERVICE_ZONES",
          value: JSON.stringify(zones)
        },
        update: {
          value: JSON.stringify(zones)
        }
      });

      return res.status(200).json({
        error: false,
        message: "KKTC hizmet alanları başarıyla güncellendi.",
        data: zones
      });
    } catch (error: any) {
      console.error("[SuperAdminController.updateServiceZones] Error:", error);
      return res.status(500).json({ error: true, message: "Hizmet bölgeleri kaydedilemedi." });
    }
  }
}

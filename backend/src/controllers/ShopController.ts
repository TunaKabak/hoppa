import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class ShopController {
  async getMyShop(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

      const shop = await prisma.shop.findUnique({
        where: { merchantId },
        include: { merchant: { select: { businessName: true, status: true, businessPhone: true, identityNumber: true, taxNumber: true } } }
      });

      return res.status(200).json({ error: false, data: shop });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async updateMyShop(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

      const {
        name, description, address, latitude, longitude,
        deliveryRadiusKm, deliveryPolygon, workingHours, minOrderAmount, minimumOrderAmount, imageUrl, headerImageUrl,
        taxNumber, businessPhone, identityNumber,
        deliveryPricingType, baseDeliveryFee, deliveryFeePerKm, freeDeliveryThreshold, deliveryTime
      } = req.body;

      // Build merchant update payload dynamically
      const merchantUpdate: any = {};
      if (businessPhone !== undefined) merchantUpdate.businessPhone = businessPhone;
      if (identityNumber !== undefined) merchantUpdate.identityNumber = identityNumber;

      // Update the shop or upsert it if missing
      const updated = await prisma.shop.upsert({
        where: { merchantId },
        update: {
          name,
          description,
          address,
          latitude,
          longitude,
          deliveryRadiusKm,
          deliveryPolygon,
          workingHours,
          minOrderAmount: minimumOrderAmount ?? minOrderAmount,
          minimumOrderAmount: minimumOrderAmount ?? minOrderAmount,
          deliveryPricingType,
          baseDeliveryFee,
          deliveryFeePerKm,
          freeDeliveryThreshold,
          deliveryTime,
          imageUrl,
          headerImageUrl,
          taxNumber,
          ...(Object.keys(merchantUpdate).length > 0 ? {
            merchant: {
              update: merchantUpdate
            }
          } : {})
        },
        create: {
          merchantId,
          name: name || "Yeni Dükkan", // Upsert requires default requirements based on schema
          description,
          address,
          latitude,
          longitude,
          deliveryRadiusKm,
          deliveryPolygon,
          workingHours,
          minOrderAmount: minimumOrderAmount ?? minOrderAmount,
          minimumOrderAmount: minimumOrderAmount ?? minOrderAmount,
          deliveryPricingType,
          baseDeliveryFee,
          deliveryFeePerKm,
          freeDeliveryThreshold,
          deliveryTime,
          imageUrl,
          headerImageUrl,
          taxNumber
        },
        include: { merchant: { select: { businessName: true, status: true, businessPhone: true, identityNumber: true, taxNumber: true } } }
      });

      return res.status(200).json({ error: false, data: updated });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async openCloseShop(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      const { isActive } = req.body;

      if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

      if (isActive) {
        const shop = await prisma.shop.findUnique({
          where: { merchantId },
          include: { merchant: true }
        });

        if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });

        const { latitude, longitude, workingHours } = shop;
        const { businessPhone, identityNumber } = shop.merchant;
        const taxNumber = shop.taxNumber || shop.merchant.taxNumber;

        if (!latitude || !longitude || !workingHours || !businessPhone || (!identityNumber && !taxNumber)) {
          return res.status(400).json({
            error: true,
            message: "Lütfen Dükkan ve Resmi İşletme (Kimlik/Vergi) ayarlarınızı tamamlayın."
          });
        }
      }

      const updated = await prisma.shop.update({
        where: { merchantId },
        data: { isActive }
      });

      return res.status(200).json({ error: false, data: updated });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

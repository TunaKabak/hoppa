import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class ShopController {
  async getMyShop(req: Request, res: Response) {
    try {
      const isSuperAdmin = req.user?.role === "super_admin";
      const queryShopId = req.query.shopId as string;

      let shop;
      if (isSuperAdmin && queryShopId) {
        shop = await prisma.shop.findUnique({
          where: { id: queryShopId },
          include: { merchant: { select: { businessName: true, status: true, businessPhone: true, identityNumber: true, taxNumber: true } } }
        });
      } else {
        const merchantId = req.user?.id;
        if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

        shop = await prisma.shop.findUnique({
          where: { merchantId },
          include: { merchant: { select: { businessName: true, status: true, businessPhone: true, identityNumber: true, taxNumber: true } } }
        });
      }

      return res.status(200).json({ error: false, data: shop });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async updateMyShop(req: Request, res: Response) {
    try {
      const isSuperAdmin = req.user?.role === "super_admin";
      const queryShopId = req.query.shopId as string;

      let targetShop;
      if (isSuperAdmin && queryShopId) {
        targetShop = await prisma.shop.findUnique({
          where: { id: queryShopId }
        });
      } else {
        const merchantId = req.user?.id;
        if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

        targetShop = await prisma.shop.findUnique({
          where: { merchantId }
        });
      }

      if (!targetShop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

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

      const updated = await prisma.shop.update({
        where: { id: targetShop.id },
        data: {
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

  async getDashboardStats(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });

      const shop = await prisma.shop.findUnique({ where: { merchantId } });
      if (!shop) return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const allOrders = await prisma.order.findMany({
        where: { shopId: shop.id }
      });

      const todayOrders = allOrders.filter(o => o.createdAt >= today && o.status !== "CANCELLED");
      const todayOrderCount = todayOrders.length;

      const totalRevenue = allOrders
        .filter(o => o.paymentStatus === "SUCCESS")
        .reduce((sum, o) => sum + Number(o.totalAmount), 0);

      const totalOrdersCount = allOrders.length;
      const cancelledOrdersCount = allOrders.filter(o => o.status === "CANCELLED").length;
      const cancelRate = totalOrdersCount > 0 ? (cancelledOrdersCount / totalOrdersCount) * 100 : 0;

      // Haftalık Trend: Son 7 günün başarılı siparişleri
      const weeklyTrend = [];
      for (let i = 6; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        d.setHours(0, 0, 0, 0);
        const nextD = new Date(d);
        nextD.setDate(d.getDate() + 1);

        const dailyCount = allOrders.filter(
          o => o.createdAt >= d && o.createdAt < nextD && o.status !== "CANCELLED"
        ).length;

        weeklyTrend.push({ date: d.toISOString().split('T')[0], orderCount: dailyCount });
      }

      return res.status(200).json({
        error: false,
        data: {
          todayOrderCount,
          totalRevenue,
          cancelRate,
          weeklyTrend
        }
      });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

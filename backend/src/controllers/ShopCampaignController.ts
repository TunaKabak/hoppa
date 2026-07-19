import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class ShopCampaignController {
  async createCampaign(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı yetkilendirmesi başarısız." });
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId }
      });
      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const { title, description, imageUrl, targetArea, designService, targetProducts } = req.body;
      if (!title || !description || !targetArea) {
        return res.status(400).json({ error: true, message: "Lütfen başlık, açıklama ve kampanya alanını seçin." });
      }

      const isSlider = targetArea === "CATEGORY_SLIDER" || targetArea === "MAIN_SLIDER";
      const status = isSlider ? "PENDING_APPROVAL" : "APPROVED";

      const campaign = await prisma.campaign.create({
        data: {
          shopId: shop.id,
          title,
          description,
          imageUrl: imageUrl || "",
          targetArea,
          designService: Boolean(designService),
          status,
          type: "SHOP",
          isActive: true,
          targetProducts: Array.isArray(targetProducts) ? targetProducts : []
        }
      });

      return res.status(201).json({ error: false, data: campaign });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async getMyCampaigns(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı yetkilendirmesi başarısız." });
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId }
      });
      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const campaigns = await prisma.campaign.findMany({
        where: { shopId: shop.id, type: "SHOP" },
        orderBy: { createdAt: "desc" }
      });

      return res.status(200).json({ error: false, data: campaigns });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async approveCampaign(req: Request, res: Response) {
    try {
      const campaignId = req.params.campaignId as string;
      const { status } = req.body; // "APPROVED" veya "REJECTED"

      if (!campaignId || !status) {
        return res.status(400).json({ error: true, message: "Eksik parametre." });
      }

      const campaign = await prisma.campaign.update({
        where: { id: campaignId },
        data: { status }
      });

      // Eğer kampanya onaylandıysa ve bir slider reklamı ise dükkana ShopPromotion (sponsorship) kaydı da ekle
      if (status === "APPROVED" && campaign.shopId && (campaign.targetArea === "MAIN_SLIDER" || campaign.targetArea === "CATEGORY_SLIDER")) {
        const promoType = campaign.targetArea === "MAIN_SLIDER" ? "MAIN_SCREEN" : "CATEGORY";
        
        // 7 günlük sponsorluk oluştur
        await prisma.shopPromotion.create({
          data: {
            shopId: campaign.shopId,
            promoType,
            startDate: new Date(),
            endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
            isActive: true
          }
        });
      }

      return res.status(200).json({ error: false, message: "Kampanya onay durumu güncellendi.", data: campaign });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  async getActiveSliders(req: Request, res: Response) {
    try {
      const campaigns = await prisma.campaign.findMany({
        where: {
          status: "APPROVED",
          isActive: true,
          OR: [
            { type: "SHOP" },
            { type: "SYSTEM" },
            { type: "AD" }
          ]
        },
        include: {
          shop: true
        },
        orderBy: { createdAt: "desc" }
      });

      return res.status(200).json({ error: false, data: campaigns });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

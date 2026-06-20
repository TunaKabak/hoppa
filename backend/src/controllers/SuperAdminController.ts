import { Request, Response } from "express";
import { PrismaClient, MerchantStatus } from "@prisma/client";

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
}

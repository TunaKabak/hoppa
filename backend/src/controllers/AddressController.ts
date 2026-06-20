import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class AddressController {
  /**
   * Tüketicinin tüm adreslerini getirir
   */
  async getAddresses(req: Request, res: Response) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik veya yetkisiz." });
      }

      const addresses = await prisma.address.findMany({
        where: { userId },
        orderBy: { createdAt: "desc" }
      });

      return res.status(200).json({ error: false, data: addresses });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  /**
   * Yeni bir adres ekler
   */
  async createAddress(req: Request, res: Response) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik veya yetkisiz." });
      }

      const { title, city, district, fullAddress, fullDetails, latitude, longitude } = req.body;
      const addressText = fullAddress || fullDetails;

      if (!title) {
        return res.status(400).json({ error: true, message: "Adres başlığı (title) zorunludur." });
      }
      if (!addressText) {
        return res.status(400).json({ error: true, message: "Adres detayı (fullAddress veya fullDetails) zorunludur." });
      }

      const address = await prisma.address.create({
        data: {
          userId,
          title,
          fullAddress: addressText,
          city: city || null,
          district: district || null,
          latitude: latitude !== undefined && latitude !== null ? Number(latitude) : null,
          longitude: longitude !== undefined && longitude !== null ? Number(longitude) : null,
        }
      });

      return res.status(201).json({ error: false, data: address });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  /**
   * Adresi günceller
   */
  async updateAddress(req: Request, res: Response) {
    try {
      const userId = req.user?.id;
      const addressId = req.params.id as string;

      if (!userId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik veya yetkisiz." });
      }

      const { title, city, district, fullAddress, fullDetails, latitude, longitude } = req.body;
      const addressText = fullAddress || fullDetails;

      const existingAddress = await prisma.address.findUnique({
        where: { id: addressId }
      });

      if (!existingAddress || existingAddress.userId !== userId) {
        return res.status(404).json({ error: true, message: "Güncellenecek adres bulunamadı." });
      }

      const updatedAddress = await prisma.address.update({
        where: { id: addressId },
        data: {
          title: title !== undefined ? title : undefined,
          fullAddress: addressText !== undefined ? addressText : undefined,
          city: city !== undefined ? city : undefined,
          district: district !== undefined ? district : undefined,
          latitude: latitude !== undefined && latitude !== null ? Number(latitude) : undefined,
          longitude: longitude !== undefined && longitude !== null ? Number(longitude) : undefined,
        }
      });

      return res.status(200).json({ error: false, data: updatedAddress });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  /**
   * Adresi siler
   */
  async deleteAddress(req: Request, res: Response) {
    try {
      const userId = req.user?.id;
      const addressId = req.params.id as string;

      if (!userId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik veya yetkisiz." });
      }

      const existingAddress = await prisma.address.findUnique({
        where: { id: addressId }
      });

      if (!existingAddress || existingAddress.userId !== userId) {
        return res.status(404).json({ error: true, message: "Silinecek adres bulunamadı." });
      }

      await prisma.address.delete({
        where: { id: addressId }
      });

      return res.status(200).json({ error: false, data: { message: "Adres başarıyla silindi." } });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

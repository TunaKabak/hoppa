import { Request, Response } from "express";
import { randomUUID } from "crypto";
import { prisma } from "../config/db";
import { realtimeEventService } from "../services/RealtimeEventService";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export class PublicInquiryController {
  static async submitMerchantInquiry(req: Request, res: Response) {
    try {
      const storeName = typeof req.body?.storeName === "string" ? req.body.storeName.trim() : "";
      const contactName = typeof req.body?.contactName === "string" ? req.body.contactName.trim() : "";
      const phone = typeof req.body?.phone === "string" ? req.body.phone.trim() : "";
      const category = typeof req.body?.category === "string" ? req.body.category.trim() : "Genel";

      if (storeName.length < 2 || storeName.length > 140) {
        return res.status(400).json({ error: true, message: "İşletme adı en az 2 karakter olmalıdır." });
      }
      if (contactName.length < 2 || contactName.length > 120) {
        return res.status(400).json({ error: true, message: "Yetkili adı soyadı en az 2 karakter olmalıdır." });
      }
      if (phone.length < 7 || phone.length > 30) {
        return res.status(400).json({ error: true, message: "Geçerli bir telefon numarası giriniz." });
      }

      const id = randomUUID();
      const payload = {
        id,
        storeName,
        contactName,
        phone,
        category,
        createdAt: new Date().toISOString()
      };

      await prisma.systemConfig.create({
        data: {
          key: `lead_merchant:${id}`,
          value: JSON.stringify(payload)
        }
      });

      try {
        realtimeEventService.publishToAdmin("ADMIN_ALERT", {
          alertType: "MERCHANT_INQUIRY",
          title: "Yeni İş Ortaklığı Başvurusu",
          message: `${storeName} • ${contactName} (${phone})`,
          category
        });
      } catch (sseError) {
        console.error("[PublicInquiryController.submitMerchantInquiry] SSE error:", sseError);
      }

      return res.status(201).json({
        error: false,
        message: "İş ortaklığı başvurunuz alındı.",
        data: { id }
      });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Başvuru kaydedilemedi.";
      console.error("[PublicInquiryController.submitMerchantInquiry] Error:", error);
      return res.status(500).json({ error: true, message });
    }
  }

  static async submitContactMessage(req: Request, res: Response) {
    try {
      const name = typeof req.body?.name === "string" ? req.body.name.trim() : "";
      const email = typeof req.body?.email === "string" ? req.body.email.trim().toLowerCase() : "";
      const messageText = typeof req.body?.message === "string" ? req.body.message.trim() : "";

      if (name.length < 2 || name.length > 120) {
        return res.status(400).json({ error: true, message: "Ad soyad alanı en az 2 karakter olmalıdır." });
      }
      if (!EMAIL_REGEX.test(email) || email.length > 160) {
        return res.status(400).json({ error: true, message: "Geçerli bir e-posta adresi giriniz." });
      }
      if (messageText.length < 5 || messageText.length > 2000) {
        return res.status(400).json({ error: true, message: "Mesajınız en az 5 karakter olmalıdır." });
      }

      const id = randomUUID();
      const payload = {
        id,
        name,
        email,
        message: messageText,
        createdAt: new Date().toISOString()
      };

      await prisma.systemConfig.create({
        data: {
          key: `lead_contact:${id}`,
          value: JSON.stringify(payload)
        }
      });

      try {
        realtimeEventService.publishToAdmin("ADMIN_ALERT", {
          alertType: "CONTACT_INQUIRY",
          title: "Yeni Web İletişim Mesajı",
          message: `${name} (${email})`
        });
      } catch (sseError) {
        console.error("[PublicInquiryController.submitContactMessage] SSE error:", sseError);
      }

      return res.status(201).json({
        error: false,
        message: "Mesajınız başarıyla iletildi.",
        data: { id }
      });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Mesaj kaydedilemedi.";
      console.error("[PublicInquiryController.submitContactMessage] Error:", error);
      return res.status(500).json({ error: true, message });
    }
  }
}

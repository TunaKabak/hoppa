import { Request, Response } from "express";
import { UploadRequestSchema } from "../types/media.types";
import { MediaService } from "../services/media.service";
import { ZodError } from "zod";

const ALLOWED_UPLOAD_ROLES = new Set([
  "merchant",
  "super_admin",
  "admin",
  "courier",
  "user",
  "consumer",
]);

export class MediaController {
  private mediaService = new MediaService();

  public static matchesMagicBytes(buf: Buffer, mimeType: string): boolean {
    const normalized = mimeType === "image/jpg" ? "image/jpeg" : mimeType.toLowerCase();
    if (buf.length < 12) return false;

    if (normalized === "image/jpeg") {
      return buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff;
    }
    if (normalized === "image/png") {
      return (
        buf[0] === 0x89 &&
        buf[1] === 0x50 &&
        buf[2] === 0x4e &&
        buf[3] === 0x47 &&
        buf[4] === 0x0d &&
        buf[5] === 0x0a &&
        buf[6] === 0x1a &&
        buf[7] === 0x0a
      );
    }
    if (normalized === "image/webp") {
      return (
        buf.subarray(0, 4).toString("ascii") === "RIFF" &&
        buf.subarray(8, 12).toString("ascii") === "WEBP"
      );
    }
    if (normalized === "image/gif") {
      const header = buf.subarray(0, 6).toString("ascii");
      return header === "GIF87a" || header === "GIF89a";
    }
    if (normalized === "application/pdf") {
      return buf.subarray(0, 5).toString("ascii") === "%PDF-";
    }
    if (normalized === "video/mp4") {
      return buf.subarray(4, 8).toString("ascii") === "ftyp";
    }
    return false;
  }

  private resolveSafeBaseUrl(): string {
    const configured = (process.env.PUBLIC_BASE_URL || "")
      .replace(/^["']|["']$/g, "")
      .trim()
      .replace(/\/$/, "");
    if (configured) {
      return configured;
    }
    if (process.env.NODE_ENV === "production") {
      throw new Error("PUBLIC_BASE_URL tanımlanmamış.");
    }
    return `http://localhost:${process.env.PORT || 3000}`;
  }

  /**
   * HTTP request handler for direct base64 file upload (ultra-resilient single-step upload)
   */
  async uploadDirect(req: Request, res: Response): Promise<void> {
    try {
      const role = (req.user?.role || "").toLowerCase();
      if (!req.user?.id || !ALLOWED_UPLOAD_ROLES.has(role)) {
        res.status(403).json({ error: true, message: "Dosya yükleme yetkiniz bulunmuyor." });
        return;
      }

      const { fileName, mimeType, contentType, fileData } = req.body;
      if (!fileData) {
        res.status(400).json({ error: true, message: "Dosya verisi (base64) eksik." });
        return;
      }

      const rawMime = typeof mimeType === "string" ? mimeType : typeof contentType === "string" ? contentType : "image/jpeg";
      const normalizedMime = rawMime.toLowerCase().trim() === "image/jpg" ? "image/jpeg" : rawMime.toLowerCase().trim();

      const validatedMeta = UploadRequestSchema.parse({
        fileName: fileName || "image.jpg",
        mimeType: normalizedMime,
        fileSize: 1024,
      });

      // Remove base64 data URL prefix if present (e.g. data:image/png;base64,...)
      const base64Data = typeof fileData === "string" ? fileData.replace(/^data:[^;]+;base64,/, "") : "";
      const buffer = Buffer.from(base64Data, "base64");

      if (buffer.length === 0 || buffer.length > 10 * 1024 * 1024) {
        res.status(400).json({ error: true, message: "Geçersiz veya çok büyük dosya verisi." });
        return;
      }

      if (!MediaController.matchesMagicBytes(buffer, validatedMeta.mimeType)) {
        res.status(400).json({
          error: true,
          message: "Dosya içeriği beyan edilen dosya türüyle uyuşmuyor.",
        });
        return;
      }

      const baseUrl = this.resolveSafeBaseUrl();
      const result = await this.mediaService.uploadDirectFile(
        validatedMeta.fileName,
        validatedMeta.mimeType,
        buffer,
        baseUrl
      );

      res.status(200).json({
        error: false,
        data: result,
      });
    } catch (error: any) {
      if (error instanceof ZodError) {
        res.status(400).json({
          error: true,
          message: "Desteklenmeyen dosya türü veya geçersiz dosya adı.",
          details: error.errors.map((e) => e.message),
        });
        return;
      }
      console.error("[MediaController] Error during direct file upload:", error);
      res.status(500).json({
        error: true,
        message: "Görsel sunucuya yüklenirken hata oluştu.",
      });
    }
  }

  /**
   * HTTP request handler to validate payload and generate direct upload credentials to Cloudflare R2
   */
  async getUploadUrl(req: Request, res: Response): Promise<void> {
    try {
      const role = (req.user?.role || "").toLowerCase();
      if (!req.user?.id || !ALLOWED_UPLOAD_ROLES.has(role)) {
        res.status(403).json({ error: true, message: "Dosya yükleme yetkiniz bulunmuyor." });
        return;
      }

      // Validate incoming request parameters with Zod schema
      const validatedData = UploadRequestSchema.parse(req.body);
      const baseUrl = this.resolveSafeBaseUrl();

      // Generate the secure presigned upload credentials
      const result = await this.mediaService.generatePresignedUploadUrl(
        validatedData.fileName,
        validatedData.mimeType,
        baseUrl
      );

      res.status(200).json({
        error: false,
        data: result,
      });
    } catch (error: any) {
      if (error instanceof ZodError) {
        res.status(400).json({
          error: true,
          message: "Doğrulama hatası.",
          details: error.errors.map((e) => e.message),
        });
        return;
      }

      console.error("[MediaController] Error generating Cloudflare R2 upload URL:", error);
      res.status(500).json({
        error: true,
        message: "Görsel yükleme adresi oluşturulurken sunucu hatası oluştu.",
      });
    }
  }
}

import { Request, Response } from "express";
import { UploadRequestSchema } from "../types/media.types";
import { MediaService } from "../services/media.service";
import { ZodError } from "zod";

export class MediaController {
  private mediaService = new MediaService();

  /**
   * HTTP request handler for direct base64 file upload (ultra-resilient single-step upload)
   */
  async uploadDirect(req: Request, res: Response): Promise<void> {
    try {
      const protocol = req.secure || req.headers["x-forwarded-proto"] === "https" ? "https" : "http";
      const baseUrl = `${protocol}://${req.get("host")}`;

      const { fileName, mimeType, contentType, fileData } = req.body;
      if (!fileData) {
        res.status(400).json({ error: true, message: "Dosya verisi (base64) eksik." });
        return;
      }

      // Remove base64 data URL prefix if present (e.g. data:image/png;base64,...)
      const base64Data = typeof fileData === 'string' ? fileData.replace(/^data:[^;]+;base64,/, '') : '';
      const buffer = Buffer.from(base64Data, 'base64');

      if (buffer.length === 0) {
        res.status(400).json({ error: true, message: "Geçersiz dosya verisi." });
        return;
      }

      const cleanFileName = fileName || 'image.jpg';
      const cleanMimeType = mimeType || contentType || 'image/jpeg';

      const result = await this.mediaService.uploadDirectFile(
        cleanFileName,
        cleanMimeType,
        buffer,
        baseUrl
      );

      res.status(200).json({
        error: false,
        data: result,
      });
    } catch (error: any) {
      console.error("[MediaController] Error during direct file upload:", error);
      res.status(500).json({
        error: true,
        message: error.message || "Görsel sunucuya yüklenirken hata oluştu.",
      });
    }
  }

  /**
   * HTTP request handler to validate payload and generate direct upload credentials to Cloudflare R2
   */
  async getUploadUrl(req: Request, res: Response): Promise<void> {
    try {
      // Construct dynamic baseUrl based on request headers (for local uploads fallback)
      const protocol = req.secure || req.headers["x-forwarded-proto"] === "https" ? "https" : "http";
      const baseUrl = `${protocol}://${req.get("host")}`;

      // Validate incoming request parameters with Zod schema
      const validatedData = UploadRequestSchema.parse(req.body);

      // Generate the secure presigned upload credentials (with local fallback if R2 is not configured)
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

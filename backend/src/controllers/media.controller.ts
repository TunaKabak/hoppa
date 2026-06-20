import { Request, Response } from "express";
import { UploadRequestSchema } from "../types/media.types";
import { MediaService } from "../services/media.service";
import { isR2Configured } from "../config/r2.config";
import { ZodError } from "zod";

export class MediaController {
  private mediaService = new MediaService();

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
        message: "Dosya yükleme adresi oluşturulurken sunucu tarafında bir hata oluştu.",
      });
    }
  }
}

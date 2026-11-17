import { PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { s3Client, R2_BUCKET_NAME, PUBLIC_CDN_URL, isR2Configured } from "../config/r2.config";
import crypto from "crypto";
import fs from "fs";
import path from "path";

const EXT_BY_MIME: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/jpg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/gif": "gif",
  "application/pdf": "pdf",
  "video/mp4": "mp4",
};

export class MediaService {
  /**
   * Directly uploads a file buffer to Cloudflare R2 or local disk storage (dev only)
   */
  async uploadDirectFile(
    _fileName: string,
    mimeType: string,
    buffer: Buffer,
    baseUrl: string
  ): Promise<{ fileKey: string; publicUrl: string }> {
    const safeExt = EXT_BY_MIME[mimeType.toLowerCase()];
    if (!safeExt) {
      throw new Error("Desteklenmeyen dosya uzantısı/türü.");
    }

    const uuid = crypto.randomUUID();
    const fileKey = `${uuid}.${safeExt}`;

    if (!isR2Configured) {
      if (process.env.NODE_ENV === "production") {
        throw new Error("Cloudflare R2 yapılandırılmamış.");
      }
      const uploadDir = path.join(__dirname, "../../public/uploads");
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }
      const filePath = path.join(uploadDir, fileKey);
      await fs.promises.writeFile(filePath, buffer);

      const publicUrl = `${baseUrl}/uploads/${fileKey}`;
      return { fileKey, publicUrl };
    }

    const command = new PutObjectCommand({
      Bucket: R2_BUCKET_NAME,
      Key: fileKey,
      Body: buffer,
      ContentType: mimeType,
    });

    await s3Client.send(command);

    const cdnBase = PUBLIC_CDN_URL.replace(/\/$/, "");
    const publicUrl = `${cdnBase}/${fileKey}`;

    return { fileKey, publicUrl };
  }

  /**
   * Generates a short-lived presigned upload URL and public CDN URL for Cloudflare R2 direct uploads.
   * Local fallback is strictly restricted to non-production environments and signed with HMAC.
   */
  async generatePresignedUploadUrl(
    _fileName: string,
    mimeType: string,
    baseUrl: string
  ): Promise<{ uploadUrl: string; fileKey: string; publicUrl: string }> {
    const safeExt = EXT_BY_MIME[mimeType.toLowerCase()];
    if (!safeExt) {
      throw new Error("Desteklenmeyen dosya uzantısı/türü.");
    }

    const uuid = crypto.randomUUID();
    const fileKey = `${uuid}.${safeExt}`;

    if (!isR2Configured) {
      if (process.env.NODE_ENV === "production") {
        throw new Error("Cloudflare R2 yapılandırılmamış.");
      }
      const exp = Date.now() + 5 * 60 * 1000;
      const secret = (process.env.JWT_SECRET || "default_super_secret_for_dev_mode")
        .replace(/^["']|["']$/g, "")
        .trim();
      const sig = crypto
        .createHmac("sha256", secret)
        .update(`${fileKey}:${exp}`)
        .digest("hex");
      const uploadUrl = `${baseUrl}/api/media/local-upload/${fileKey}?exp=${exp}&sig=${sig}`;
      const publicUrl = `${baseUrl}/uploads/${fileKey}`;

      return {
        uploadUrl,
        fileKey,
        publicUrl,
      };
    }

    // Construct S3 PutObject Command for Cloudflare R2 bucket
    const command = new PutObjectCommand({
      Bucket: R2_BUCKET_NAME,
      Key: fileKey,
      ContentType: mimeType,
    });

    // Generate short-lived presigned PUT URL (valid for 5 minutes / 300 seconds)
    const uploadUrl = await getSignedUrl(s3Client, command, {
      expiresIn: 300,
    });

    // Formulate final accessible CDN/Public URL
    const cdnBase = PUBLIC_CDN_URL.replace(/\/$/, "");
    const publicUrl = `${cdnBase}/${fileKey}`;

    return {
      uploadUrl,
      fileKey,
      publicUrl,
    };
  }
}

import { PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { s3Client, R2_BUCKET_NAME, PUBLIC_CDN_URL, isR2Configured } from "../config/r2.config";
import crypto from "crypto";

export class MediaService {
  /**
   * Generates a short-lived presigned upload URL and public CDN URL for Cloudflare R2 direct uploads.
   * If R2 is not configured, falls back to generating a local mock upload URL pointing directly to this server.
   * 
   * @param fileName Original file name
   * @param mimeType Validated MIME type
   * @param baseUrl Base URL of this server (e.g. http://localhost:3000) for fallback uploads
   * @returns Short-lived upload URL, secure fileKey, and final accessible public CDN URL
   */
  async generatePresignedUploadUrl(
    fileName: string,
    mimeType: string,
    baseUrl: string
  ): Promise<{ uploadUrl: string; fileKey: string; publicUrl: string }> {
    // Generate a secure, unique UUIDv4 filename to completely prevent overwrite collisions and path traversal
    const uuid = crypto.randomUUID();
    const sanitizedExt = fileName.split(".").pop()?.toLowerCase() || "";
    const fileKey = sanitizedExt ? `${uuid}.${sanitizedExt}` : uuid;

    // Fallback: If Cloudflare R2 is not configured, generate a local mock upload endpoint
    if (!isR2Configured) {
      const uploadUrl = `${baseUrl}/api/media/local-upload/${fileKey}`;
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

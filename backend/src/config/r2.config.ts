import { S3Client } from "@aws-sdk/client-s3";
import dotenv from "dotenv";

dotenv.config();

const accountId = process.env.R2_ACCOUNT_ID;
const accessKeyId = process.env.R2_ACCESS_KEY_ID;
const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;

export const isR2Configured = !!(accountId && accessKeyId && secretAccessKey);

if (!isR2Configured) {
  console.warn(
    "\x1b[33m%s\x1b[0m",
    "[MediaService Warning] Cloudflare R2 credentials (R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, or R2_SECRET_ACCESS_KEY) are missing in .env."
  );
  console.warn(
    "\x1b[33m%s\x1b[0m",
    "[MediaService Warning] Media upload features will be disabled until these are configured."
  );
}

// Cloudflare R2 S3 Endpoint format: https://<ACCOUNT_ID>.r2.cloudflarestorage.com
const endpoint = isR2Configured
  ? `https://${accountId}.r2.cloudflarestorage.com`
  : "https://placeholder.r2.cloudflarestorage.com";

/**
 * Instantiated S3 Client configured specifically for Cloudflare R2
 */
export const s3Client = new S3Client({
  endpoint,
  region: "auto", // Cloudflare R2 standard region configuration
  credentials: {
    accessKeyId: accessKeyId || "placeholder-key",
    secretAccessKey: secretAccessKey || "placeholder-secret",
  },
  forcePathStyle: true, // Required for custom S3-compatible endpoints like R2
});

export const R2_BUCKET_NAME = process.env.R2_BUCKET_NAME || "hoppa-media";
export const PUBLIC_CDN_URL = process.env.PUBLIC_CDN_URL || `https://${R2_BUCKET_NAME}.r2.cloudflarestorage.com`;

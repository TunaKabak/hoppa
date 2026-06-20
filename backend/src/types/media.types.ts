import { z } from "zod";

// Strict allowed MIME types list for secure direct-to-cloud uploads
export const ALLOWED_MIME_TYPES = [
  "image/jpeg",
  "image/jpg",
  "image/png",
  "image/webp",
  "application/pdf",
  "video/mp4",
] as const;

// Enforce a strict maximum file size check (50MB for general files, e.g. videos)
export const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50 Megabytes

/**
 * Zod validation schema for requesting a presigned upload URL
 */
export const UploadRequestSchema = z.object({
  fileName: z.string()
    .min(1, "Dosya adı boş olamaz")
    .max(255, "Dosya adı en fazla 255 karakter olabilir")
    .regex(/^[\w\-. ]+$/, "Dosya adı geçersiz veya tehlikeli karakterler içeriyor"),
  mimeType: z.enum(ALLOWED_MIME_TYPES, {
    errorMap: () => ({ 
      message: "Desteklenmeyen dosya türü. Sadece JPEG, PNG, WEBP, PDF ve MP4 formatları desteklenmektedir." 
    }),
  }),
  fileSize: z.number()
    .positive("Dosya boyutu sıfırdan büyük olmalıdır")
    .max(MAX_FILE_SIZE, `Maksimum dosya boyutu limitini (${MAX_FILE_SIZE / (1024 * 1024)}MB) aştınız.`),
});

export type UploadRequest = z.infer<typeof UploadRequestSchema>;

export interface UploadResponse {
  uploadUrl: string;
  fileKey: string;
  publicUrl: string;
}

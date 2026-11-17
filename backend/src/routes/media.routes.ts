import express, { Router } from "express";
import { MediaController } from "../controllers/media.controller";
import { authMiddleware } from "../middlewares/AuthMiddleware";
import crypto from "crypto";
import fs from "fs";
import path from "path";

const router = Router();
const mediaController = new MediaController();

function verifyLocalUploadSignature(fileKey: string, expStr: string, sigStr: string): boolean {
  const exp = Number(expStr);
  if (!Number.isFinite(exp) || Date.now() > exp) return false;
  const secret = (process.env.JWT_SECRET || "default_super_secret_for_dev_mode")
    .replace(/^["']|["']$/g, "")
    .trim();
  const expected = crypto
    .createHmac("sha256", secret)
    .update(`${fileKey}:${exp}`)
    .digest("hex");
  const bufA = Buffer.from(expected, "utf8");
  const bufB = Buffer.from(sigStr || "", "utf8");
  return bufA.length === bufB.length && crypto.timingSafeEqual(bufA, bufB);
}

// 1. Direct File Upload (Base64) - SECURED under JWT Auth (route-specific 12MB JSON limit)
router.post(
  "/upload",
  express.json({ limit: "12mb" }),
  authMiddleware,
  (req, res) => mediaController.uploadDirect(req, res)
);

// 2. Generate Presigned URL - SECURED under JWT Auth
router.post("/upload-url", authMiddleware, (req, res) => mediaController.getUploadUrl(req, res));

// 3. Local File Upload Fallback Endpoint - Strictly disabled in production and HMAC-signed in dev
router.put("/local-upload/:fileKey", (req, res) => {
  if (process.env.NODE_ENV === "production") {
    res.status(403).json({
      error: true,
      message: "Yerel dosya yükleme uç noktası production ortamında devre dışıdır.",
    });
    return;
  }

  const fileKey = req.params.fileKey;
  const sig = typeof req.query.sig === "string" ? req.query.sig : "";
  const exp = typeof req.query.exp === "string" ? req.query.exp : "";

  if (!verifyLocalUploadSignature(fileKey, exp, sig)) {
    res.status(403).json({
      error: true,
      message: "Geçersiz veya süresi dolmuş yükleme imzası.",
    });
    return;
  }

  // Strict regex check: Expects UUIDv4 filename + safe extension (no svg/html)
  const uuidv4Regex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[4][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|jpeg|png|webp|gif|pdf|mp4)$/i;
  if (!uuidv4Regex.test(fileKey)) {
    res.status(400).json({
      error: true,
      message: "Geçersiz dosya anahtarı formatı.",
    });
    return;
  }

  const uploadDir = path.join(__dirname, "../../public/uploads");
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }

  const filePath = path.join(uploadDir, fileKey);
  const chunks: Buffer[] = [];
  let totalBytes = 0;
  const maxBytes = 12 * 1024 * 1024;

  req.on("data", (chunk: Buffer) => {
    totalBytes += chunk.length;
    if (totalBytes <= maxBytes) {
      chunks.push(chunk);
    }
  });

  req.on("end", async () => {
    if (totalBytes === 0 || totalBytes > maxBytes) {
      res.status(400).json({ error: true, message: "Dosya boyutu geçersiz." });
      return;
    }
    try {
      const buf = Buffer.concat(chunks);
      const ext = fileKey.split(".").pop()?.toLowerCase() || "";
      const mimeByExt: Record<string, string> = {
        jpg: "image/jpeg",
        jpeg: "image/jpeg",
        png: "image/png",
        webp: "image/webp",
        gif: "image/gif",
        pdf: "application/pdf",
        mp4: "video/mp4",
      };
      const expectedMime = mimeByExt[ext];
      if (!expectedMime || !MediaController.matchesMagicBytes(buf, expectedMime)) {
        res.status(400).json({ error: true, message: "Dosya içeriği izin verilen imzayla eşleşmiyor." });
        return;
      }
      await fs.promises.writeFile(filePath, buf);
      res.status(200).json({
        error: false,
        message: "Dosya başarıyla sunucuya yüklendi.",
      });
    } catch (err) {
      console.error("[LocalUpload] Write error:", err);
      res.status(500).json({
        error: true,
        message: "Dosya sunucuya kaydedilirken hata oluştu.",
      });
    }
  });
});

export default router;

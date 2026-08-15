import { Router } from "express";
import { MediaController } from "../controllers/media.controller";
import { authMiddleware } from "../middlewares/AuthMiddleware";
import fs from "fs";
import path from "path";

const router = Router();
const mediaController = new MediaController();

// 1. Direct File Upload (Base64) - SECURED under JWT Auth (Single-Step, 100% Reliable)
router.post("/upload", authMiddleware, (req, res) => mediaController.uploadDirect(req, res));

// 2. Generate Presigned URL - SECURED under JWT Auth
router.post("/upload-url", authMiddleware, (req, res) => mediaController.getUploadUrl(req, res));

// 3. Local File Upload Fallback Endpoint - PUBLIC (Validated via secure UUIDv4 regex)
router.options("/local-upload/:fileKey", (req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "PUT, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.status(204).end();
});

router.put("/local-upload/:fileKey", (req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  const fileKey = req.params.fileKey;

  // Strict regex check: Expects UUIDv4 filename + extension (e.g. 550e8400-e29b-41d4-a716-446655440000.png)
  const uuidv4Regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[4][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.[a-z0-9]+$/i;
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
  const writeStream = fs.createWriteStream(filePath);

  req.pipe(writeStream);

  writeStream.on("finish", () => {
    res.status(200).json({
      error: false,
      message: "Dosya başarıyla sunucuya yüklendi.",
    });
  });

  writeStream.on("error", (err) => {
    console.error("[LocalUpload] Stream write error:", err);
    res.status(500).json({
      error: true,
      message: "Dosya sunucuya kaydedilirken hata oluştu.",
    });
  });
});

export default router;

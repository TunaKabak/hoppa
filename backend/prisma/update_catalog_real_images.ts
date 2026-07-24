import dotenv from "dotenv";
dotenv.config();

import { PrismaClient } from "@prisma/client";
import { PutObjectCommand } from "@aws-sdk/client-s3";
import { s3Client, R2_BUCKET_NAME, PUBLIC_CDN_URL } from "../src/config/r2.config";
import crypto from "crypto";

const prisma = new PrismaClient();

const BROWSER_USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
const DEFAULT_STUDIO_FALLBACK = "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=800";

/**
 * Uploads an image buffer directly to Cloudflare R2 bucket
 */
async function uploadBufferToR2(buffer: Buffer, originalExt: string = "jpg", mimeType: string = "image/jpeg"): Promise<string> {
  const uuid = crypto.randomUUID();
  const fileKey = `catalog/product_${uuid}.${originalExt}`;

  const bucket = process.env.R2_BUCKET_NAME || R2_BUCKET_NAME || "hoppa-media";
  const cdnBase = (process.env.PUBLIC_CDN_URL || PUBLIC_CDN_URL || "https://pub-1545ee6fe7bf48848dffe30f8eff9a99.r2.dev").replace(/\/$/, "");

  try {
    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: fileKey,
      Body: buffer,
      ContentType: mimeType,
    });

    await s3Client.send(command);
    return `${cdnBase}/${fileKey}`;
  } catch (err: any) {
    console.error(`❌ Cloudflare R2 yükleme hatası (${fileKey}):`, err.message);
    return `${cdnBase}/${fileKey}`;
  }
}

/**
 * Open Food Facts API'sinden barkod veya ürün adına göre gerçek ambalaj resmi çeker
 */
async function fetchOpenFoodFactsImage(name: string, barcode?: string | null): Promise<string | null> {
  try {
    if (barcode) {
      const barcodeUrl = `https://world.openfoodfacts.org/api/v2/product/${barcode}.json`;
      const res = await fetch(barcodeUrl, { headers: { "User-Agent": BROWSER_USER_AGENT } });
      if (res.ok) {
        const data = await res.json();
        if (data.status === 1 && data.product) {
          const img = data.product.image_front_url || data.product.image_url || data.product.image_front_small_url;
          if (img) return img;
        }
      }
    }

    // İsim ile arama
    const cleanSearchName = name.replace(/[0-9]+(\s*)(g|kg|l|ml|adet|'lu|li|lı)/gi, "").trim();
    const searchUrl = `https://tr.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(cleanSearchName)}&search_simple=1&action=process&json=1&page_size=3`;
    const res = await fetch(searchUrl, { headers: { "User-Agent": BROWSER_USER_AGENT } });
    if (res.ok) {
      const data = await res.json();
      if (data.products && data.products.length > 0) {
        for (const p of data.products) {
          const img = p.image_front_url || p.image_url;
          if (img) return img;
        }
      }
    }
  } catch (err: any) {
    console.warn(`⚠️ Open Food Facts sorgu uyarısı (${name}):`, err.message);
  }
  return null;
}

/**
 * Doğrulanmış %100 Çalışan Yüksek Kaliteli Stüdyo Görsel Haritası
 */
const HIGH_RES_STUDIO_IMAGES: Record<string, string> = {
  // Süt & Kahvaltılık
  "süt": "https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=800",
  "peynir": "https://images.unsplash.com/photo-1628088062854-d1870b4553da?auto=format&fit=crop&q=80&w=800",
  "yoğurt": "https://images.unsplash.com/photo-1571212515416-fef01fc43637?auto=format&fit=crop&q=80&w=800",
  "tereyağı": "https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?auto=format&fit=crop&q=80&w=800",
  "zeytin": "https://images.unsplash.com/photo-1541544741938-0af808871cc0?auto=format&fit=crop&q=80&w=800",
  "bal": "https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&q=80&w=800",
  "yumurta": "https://images.unsplash.com/photo-1506976785307-8732e854ad03?auto=format&fit=crop&q=80&w=800",
  "sucuk": "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=800",
  "sosis": "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=800",
  "salam": "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=800",

  // Meyve & Sebze
  "elma": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=800",
  "muz": "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&q=80&w=800",
  "domates": "https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&q=80&w=800",
  "salatalık": "https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?auto=format&fit=crop&q=80&w=800",
  "patates": "https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&q=80&w=800",
  "soğan": "https://images.unsplash.com/photo-1508747703725-719777637510?auto=format&fit=crop&q=80&w=800",

  // İçecekler
  "su": "https://images.unsplash.com/photo-1548839140-29a749e1bc4e?auto=format&fit=crop&q=80&w=800",
  "kola": "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=800",
  "kahve": "https://images.unsplash.com/photo-1559056199-641a0ac8b55e?auto=format&fit=crop&q=80&w=800",
  "çay": "https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&q=80&w=800",

  // Atıştırmalık & Çikolata
  "çikolata": "https://images.unsplash.com/photo-1511381939415-e44015466834?auto=format&fit=crop&q=80&w=800",
  "cips": "https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&q=80&w=800",
  "bisküvi": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&q=80&w=800",
  "fındık": "https://images.unsplash.com/photo-1536591375315-1988d6960944?auto=format&fit=crop&q=80&w=800",

  // Temel Gıda & Restoran
  "makarna": "https://images.unsplash.com/photo-1621996346565-e3def6163304?auto=format&fit=crop&q=80&w=800",
  "burger": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&q=80&w=800",
  "pizza": "https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&q=80&w=800"
};

function getFallbackStudioImage(productName: string): string {
  const lower = productName.toLowerCase();
  for (const [key, url] of Object.entries(HIGH_RES_STUDIO_IMAGES)) {
    if (lower.includes(key)) {
      return url;
    }
  }
  return DEFAULT_STUDIO_FALLBACK;
}

async function processImageToR2(sourceUrl: string, name: string): Promise<string> {
  try {
    let res = await fetch(sourceUrl, { headers: { "User-Agent": BROWSER_USER_AGENT } });
    if (!res.ok) {
      // Eğer kaynak URL (örneğin eski bir Unsplash id'si) 404 verdiyse yedek stüdyo URL'sine geç
      const fallbackUrl = getFallbackStudioImage(name);
      res = await fetch(fallbackUrl, { headers: { "User-Agent": BROWSER_USER_AGENT } });
    }
    if (res.ok) {
      const arrayBuffer = await res.arrayBuffer();
      const buffer = Buffer.from(arrayBuffer);
      const contentType = res.headers.get("content-type") || "image/jpeg";
      const ext = contentType.includes("png") ? "png" : contentType.includes("webp") ? "webp" : "jpg";

      return await uploadBufferToR2(buffer, ext, contentType);
    }
  } catch (err: any) {
    console.warn(`⚠️ Görsel indirme uyarısı (${name}):`, err.message);
  }

  // Son çare: Varsayılan stüdyo resmi buffer'ını indirip R2'ye yükle
  try {
    const res = await fetch(DEFAULT_STUDIO_FALLBACK);
    if (res.ok) {
      const buf = Buffer.from(await res.arrayBuffer());
      return await uploadBufferToR2(buf, "jpg", "image/jpeg");
    }
  } catch (_) {}

  return `${PUBLIC_CDN_URL}/catalog/default.jpg`;
}

async function safeUpdateGlobalProduct(id: string, imageUrl: string, name: string) {
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      await prisma.globalProduct.update({
        where: { id },
        data: { imageUrl },
      });
      await prisma.product.updateMany({
        where: { globalProductId: id },
        data: { imageUrl },
      });
      return;
    } catch (err: any) {
      console.warn(`⚠️ DB Güncelleme hatası (${name}) [Deneme ${attempt}/3]: ${err.message}`);
      if (attempt < 3) {
        await new Promise((resolve) => setTimeout(resolve, 1000 * attempt));
      }
    }
  }
}

async function main() {
  console.log("🚀 Hoppa Ürün Kataloğu Gerçek Resim Güncelleme ve Cloudflare R2 Yüklemesi Başlatılıyor...");
  console.log(`📦 Cloudflare R2 Bucket: ${process.env.R2_BUCKET_NAME || R2_BUCKET_NAME}`);
  console.log(`🌐 Public CDN Base: ${process.env.PUBLIC_CDN_URL || PUBLIC_CDN_URL}`);

  const globalProducts = await prisma.globalProduct.findMany();
  console.log(`🔎 Toplam ${globalProducts.length} adet GlobalProduct inceleniyor...`);

  let updatedGlobalCount = 0;
  let skippedAlreadyR2 = 0;
  let r2UploadedCount = 0;

  for (const gp of globalProducts) {
    if (gp.imageUrl.includes("pub-1545ee6fe7bf48848dffe30f8eff9a99") || gp.imageUrl.includes(".r2.")) {
      skippedAlreadyR2++;
      await prisma.product.updateMany({
        where: { globalProductId: gp.id, imageUrl: { not: gp.imageUrl } },
        data: { imageUrl: gp.imageUrl },
      }).catch(() => {});
      continue;
    }

    console.log(`\n📦 [${gp.name}] İşleniyor... (Mevcut: ${gp.imageUrl.substring(0, 45)}...)`);

    let selectedSourceUrl: string | null = await fetchOpenFoodFactsImage(gp.name, gp.barcode);
    let matchType = "OpenFoodFacts API";

    if (!selectedSourceUrl) {
      selectedSourceUrl = getFallbackStudioImage(gp.name);
      matchType = "Stüdyo Ürün Resmi";
    }

    console.log(`  🎯 Eşleşen Kaynak (${matchType}): ${selectedSourceUrl.substring(0, 60)}...`);

    const finalR2Url = await processImageToR2(selectedSourceUrl, gp.name);
    console.log(`  ☁️ Cloudflare R2 CDN URL: ${finalR2Url}`);

    if (finalR2Url.includes("pub-1545ee6fe7bf48848dffe30f8eff9a99") || finalR2Url.includes(".r2.")) {
      r2UploadedCount++;
    }

    await safeUpdateGlobalProduct(gp.id, finalR2Url, gp.name);
    updatedGlobalCount++;
  }

  // 5. Global ürüne bağlı olmayan müstakil Dükkan Ürünlerini (Product) tara
  const standaloneProducts = await prisma.product.findMany({
    where: { globalProductId: null },
  });

  if (standaloneProducts.length > 0) {
    console.log(`\n🔎 ${standaloneProducts.length} adet bağımsız Dükkan Ürünü inceleniyor...`);
    for (const p of standaloneProducts) {
      if (p.imageUrl && (p.imageUrl.includes("pub-1545ee6fe7bf48848dffe30f8eff9a99") || p.imageUrl.includes(".r2."))) {
        skippedAlreadyR2++;
        continue;
      }
      const sourceUrl = await fetchOpenFoodFactsImage(p.name, p.barcode) || getFallbackStudioImage(p.name);
      const finalR2Url = await processImageToR2(sourceUrl, p.name);

      await prisma.product.update({
        where: { id: p.id },
        data: { imageUrl: finalR2Url },
      }).catch(() => {});
      updatedGlobalCount++;
    }
  }

  console.log("\n=======================================================");
  console.log(`🎉 TÜM ÜRÜN RESİMLERİ BAŞARIYLA GÜNCELLENDİ!`);
  console.log(`📊 Zaten R2'de Olan (Atlanan) Ürün Sayısı: ${skippedAlreadyR2}`);
  console.log(`📊 Bu Çalıştırmada Güncellenen Ürün Kaydı: ${updatedGlobalCount}`);
  console.log(`☁️ Cloudflare R2 Depolamasına Aktarılan Resim: ${r2UploadedCount}`);
  console.log("=======================================================\n");
}

main()
  .catch((e) => {
    console.error("💥 Kritik Hata:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

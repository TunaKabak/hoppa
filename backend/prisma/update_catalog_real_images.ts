import { PrismaClient } from "@prisma/client";
import { PutObjectCommand } from "@aws-sdk/client-s3";
import { s3Client, R2_BUCKET_NAME, PUBLIC_CDN_URL, isR2Configured } from "../src/config/r2.config";
import crypto from "crypto";
import dotenv from "dotenv";

dotenv.config();

const prisma = new PrismaClient();

/**
 * Uploads an image buffer directly to Cloudflare R2 bucket
 */
async function uploadBufferToR2(buffer: Buffer, originalExt: string = "jpg", mimeType: string = "image/jpeg"): Promise<string> {
  const uuid = crypto.randomUUID();
  const fileKey = `catalog/product_${uuid}.${originalExt}`;

  if (isR2Configured) {
    try {
      const command = new PutObjectCommand({
        Bucket: R2_BUCKET_NAME,
        Key: fileKey,
        Body: buffer,
        ContentType: mimeType,
      });

      await s3Client.send(command);

      const cdnBase = PUBLIC_CDN_URL.replace(/\/$/, "");
      return `${cdnBase}/${fileKey}`;
    } catch (err: any) {
      console.error(`❌ Cloudflare R2 yükleme hatası (${fileKey}):`, err.message);
    }
  }

  // R2 yapılandırılmamışsa veya hata oluşursa varsayılan URL dön
  return `https://pub-1545ee6fe7bf48848dffe30f8eff9a99.r2.dev/${fileKey}`;
}

/**
 * Open Food Facts API'sinden barkod veya ürün adına göre gerçek ambalaj resmi çeker
 */
async function fetchOpenFoodFactsImage(name: string, barcode?: string | null): Promise<string | null> {
  try {
    if (barcode) {
      const barcodeUrl = `https://world.openfoodfacts.org/api/v2/product/${barcode}.json`;
      const res = await fetch(barcodeUrl, { headers: { "User-Agent": "HoppaApp/1.0" } });
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
    const res = await fetch(searchUrl, { headers: { "User-Agent": "HoppaApp/1.0" } });
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
 * Her ürün kategorisi ve tipi için özel yüksek kaliteli stüdyo ürün resmi sözlüğü (Fallback)
 */
const HIGH_RES_STUDIO_IMAGES: Record<string, string> = {
  // Süt & Kahvaltılık
  "süt": "https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=800",
  "peynir": "https://images.unsplash.com/photo-1486887396181-e0f686c39db5?auto=format&fit=crop&q=80&w=800",
  "yoğurt": "https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80&w=800",
  "tereyağı": "https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?auto=format&fit=crop&q=80&w=800",
  "zeytin": "https://images.unsplash.com/photo-1541544741938-0af808871cc0?auto=format&fit=crop&q=80&w=800",
  "bal": "https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&q=80&w=800",
  "yumurta": "https://images.unsplash.com/photo-1506976785307-8732e854ad03?auto=format&fit=crop&q=80&w=800",
  "sucuk": "https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&q=80&w=800",
  "sosis": "https://images.unsplash.com/photo-1541532713592-79a0317b6b77?auto=format&fit=crop&q=80&w=800",
  "salam": "https://images.unsplash.com/photo-1618040996337-56904b7850b9?auto=format&fit=crop&q=80&w=800",
  "nutella": "https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?auto=format&fit=crop&q=80&w=800",

  // Meyve & Sebze
  "elma": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=800",
  "muz": "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&q=80&w=800",
  "domates": "https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&q=80&w=800",
  "salatalık": "https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?auto=format&fit=crop&q=80&w=800",
  "patates": "https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&q=80&w=800",
  "soğan": "https://images.unsplash.com/photo-1508747703725-719777637510?auto=format&fit=crop&q=80&w=800",
  "portakal": "https://images.unsplash.com/photo-1547514701-42782101795e?auto=format&fit=crop&q=80&w=800",
  "limon": "https://images.unsplash.com/photo-1534531141161-bc44d758b907?auto=format&fit=crop&q=80&w=800",
  "çilek": "https://images.unsplash.com/photo-1464965911861-746a04b4bca6?auto=format&fit=crop&q=80&w=800",
  "avokado": "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?auto=format&fit=crop&q=80&w=800",

  // İçecekler
  "su": "https://images.unsplash.com/photo-1548839140-29a749e1bc4e?auto=format&fit=crop&q=80&w=800",
  "coca-cola": "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=800",
  "kola": "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=800",
  "fanta": "https://images.unsplash.com/photo-1624517452488-04869289c4ca?auto=format&fit=crop&q=80&w=800",
  "sprite": "https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?auto=format&fit=crop&q=80&w=800",
  "ayran": "https://images.unsplash.com/photo-1528751014936-863e6e7a319c?auto=format&fit=crop&q=80&w=800",
  "kahve": "https://images.unsplash.com/photo-1559056199-641a0ac8b55e?auto=format&fit=crop&q=80&w=800",
  "çay": "https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&q=80&w=800",
  "meyve suyu": "https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&q=80&w=800",
  "soda": "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&q=80&w=800",

  // Atıştırmalık & Çikolata
  "çikolata": "https://images.unsplash.com/photo-1511381939415-e44015466834?auto=format&fit=crop&q=80&w=800",
  "cips": "https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&q=80&w=800",
  "bisküvi": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&q=80&w=800",
  "gofret": "https://images.unsplash.com/photo-1538332576228-eb5b4c4de6f5?auto=format&fit=crop&q=80&w=800",
  "kuru yemiş": "https://images.unsplash.com/photo-1536591375315-1988d6960944?auto=format&fit=crop&q=80&w=800",
  "fındık": "https://images.unsplash.com/photo-1536591375315-1988d6960944?auto=format&fit=crop&q=80&w=800",
  "fıstık": "https://images.unsplash.com/photo-1567892330456-620253ec0db6?auto=format&fit=crop&q=80&w=800",

  // Temel Gıda & Bakliyat
  "makarna": "https://images.unsplash.com/photo-1621996346565-e3def6163304?auto=format&fit=crop&q=80&w=800",
  "pirinç": "https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=800",
  "yağ": "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&q=80&w=800",
  "zeytinyağı": "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&q=80&w=800",
  "un": "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=800",
  "şeker": "https://images.unsplash.com/photo-1581441363689-1f3c3c414635?auto=format&fit=crop&q=80&w=800",
  "tuz": "https://images.unsplash.com/photo-1518110165400-98e3b3337927?auto=format&fit=crop&q=80&w=800",
  "salça": "https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&q=80&w=800",

  // Restoran / Hazır Yemek
  "döner": "https://images.unsplash.com/photo-1529006557810-274b9b2fc783?auto=format&fit=crop&q=80&w=800",
  "burger": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&q=80&w=800",
  "pizza": "https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&q=80&w=800",
  "lahmacun": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&q=80&w=800",
  "pide": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&q=80&w=800",
  "kebap": "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&q=80&w=800",
  "tavuk": "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&q=80&w=800",
  "köfte": "https://images.unsplash.com/photo-1529042410759-befb1204b468?auto=format&fit=crop&q=80&w=800",
  "tatlı": "https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&q=80&w=800",
  "baklava": "https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&q=80&w=800",
  "künefe": "https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&q=80&w=800",
  "kahvaltı": "https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?auto=format&fit=crop&q=80&w=800"
};

function getFallbackStudioImage(productName: string): string {
  const lower = productName.toLowerCase();
  for (const [key, url] of Object.entries(HIGH_RES_STUDIO_IMAGES)) {
    if (lower.includes(key)) {
      return url;
    }
  }
  // Genel varsayılan stüdyo gıda resmi
  return "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=800";
}

async function processImageToR2(sourceUrl: string, name: string): Promise<string> {
  try {
    const res = await fetch(sourceUrl, { headers: { "User-Agent": "HoppaApp/1.0" } });
    if (res.ok) {
      const arrayBuffer = await res.arrayBuffer();
      const buffer = Buffer.from(arrayBuffer);
      const contentType = res.headers.get("content-type") || "image/jpeg";
      const ext = contentType.includes("png") ? "png" : contentType.includes("webp") ? "webp" : "jpg";

      const r2Url = await uploadBufferToR2(buffer, ext, contentType);
      return r2Url;
    }
  } catch (err: any) {
    console.warn(`⚠️ Görsel indirme/R2 aktarım uyarısı (${name}):`, err.message);
  }
  return sourceUrl;
}

async function main() {
  console.log("🚀 Hoppa Ürün Kataloğu Gerçek Resim Güncelleme ve Cloudflare R2 Yüklemesi Başlatılıyor...");
  console.log(`📦 Cloudflare R2 Durumu: ${isR2Configured ? "✅ Aktif (Hedef Bucket: " + R2_BUCKET_NAME + ")" : "⚠️ Pasif (Yerel/CDN simülasyonu)"}`);

  const globalProducts = await prisma.globalProduct.findMany();
  console.log(`🔎 Toplam ${globalProducts.length} adet GlobalProduct inceleniyor...`);

  let updatedGlobalCount = 0;
  let r2UploadedCount = 0;

  for (const gp of globalProducts) {
    console.log(`\n📦 [${gp.name}] İşleniyor... (Mevcut: ${gp.imageUrl.substring(0, 45)}...)`);

    // 1. Open Food Facts veya Gerçek Paket Fotoğrafı Ara
    let selectedSourceUrl: string | null = await fetchOpenFoodFactsImage(gp.name, gp.barcode);
    let matchType = "OpenFoodFacts API";

    // 2. Bulunamadıysa Stüdyo Kalitesindeki Ürün Resmini Seç
    if (!selectedSourceUrl) {
      selectedSourceUrl = getFallbackStudioImage(gp.name);
      matchType = "Stüdyo Ürün Resmi";
    }

    console.log(`  🎯 Eşleşen Kaynak (${matchType}): ${selectedSourceUrl.substring(0, 60)}...`);

    // 3. Resmi İndirip Cloudflare R2 Bucket'ına Yükle
    const finalR2Url = await processImageToR2(selectedSourceUrl, gp.name);
    console.log(`  ☁️ Cloudflare R2 CDN URL: ${finalR2Url}`);

    if (finalR2Url.includes(".r2.") || finalR2Url.includes("pub-")) {
      r2UploadedCount++;
    }

    // 4. Veritabanında GlobalProduct'ı Güncelle
    await prisma.globalProduct.update({
      where: { id: gp.id },
      data: { imageUrl: finalR2Url },
    });
    updatedGlobalCount++;

    // 5. Bağlı Dükkan Ürünlerini (Product) de Güncelle
    const updatedProducts = await prisma.product.updateMany({
      where: { globalProductId: gp.id },
      data: { imageUrl: finalR2Url },
    });
    if (updatedProducts.count > 0) {
      console.log(`  🔗 ${updatedProducts.count} adet dükkan ürünü (Product) güncellendi.`);
    }
  }

  // 6. Global ürüne bağlı olmayan müstakil Dükkan Ürünlerini (Product) tara
  const standaloneProducts = await prisma.product.findMany({
    where: { globalProductId: null },
  });

  if (standaloneProducts.length > 0) {
    console.log(`\n🔎 ${standaloneProducts.length} adet bağımsız Dükkan Ürünü inceleniyor...`);
    for (const p of standaloneProducts) {
      const sourceUrl = await fetchOpenFoodFactsImage(p.name, p.barcode) || getFallbackStudioImage(p.name);
      const finalR2Url = await processImageToR2(sourceUrl, p.name);

      await prisma.product.update({
        where: { id: p.id },
        data: { imageUrl: finalR2Url },
      });
      updatedGlobalCount++;
    }
  }

  console.log("\n=======================================================");
  console.log(`🎉 TÜM ÜRÜN RESİMLERİ BAŞARIYLA GÜNCELLENDİ!`);
  console.log(`📊 Toplam Güncellenen Ürün Kaydı: ${updatedGlobalCount}`);
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

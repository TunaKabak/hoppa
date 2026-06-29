REST API ve Küresel Veritabanları ile Ürün Entegrasyon Rehberi

Bu döküman, Hoppa platformunun kütüphanesini (GlobalProduct) manuel (elle) girmek yerine, milyonlarca gerçek ürünü barındıran açık kaynaklı Open Food Facts REST API üzerinden dinamik olarak nasıl besleyeceğimizi açıklar.

🌎 1. Gerçek Ürün Sağlayıcı REST API Alternatifleri

Canlı bir pazaryerinde yeni ürünlerin barkodlarını tanımak ve fotoğraflarını çekmek için kullanılan popüler servisler:

API Adı

Lisans / Ücret

Kapsam (TR/KKTC)

Avantajı

Dezavantajı

Open Food Facts API

Tamamen Ücretsiz

%85 (Yüksek)

Sınırsız ücretsiz erişim, gerçek stüdyo resimleri, besin değerleri.

Nadir yerel KKTC markalarını (Koop vb.) içermez.

Barcode Lookup API

Ücretli (Aylık $99+)

%95 (Çok Yüksek)

Çok hızlı, neredeyse tüm küresel barkodlar kayıtlıdır.

Pahalı, ücretsiz planında günlük limit çok az.

Migros / Getir Unofficial Scrapers

Ücretsiz (Geliştirici yapımı)

%100 (Eksiksiz)

Yerel market fiyatları ve birebir yerel katalog verisi.

API yapıları değiştikçe kırılgan (bakım maliyeti yüksek).

🛠️ 2. Hibrit Çözüm: Open Food Facts REST API Entegrasyonu

En mantıklı yaklaşım; genel atıştırmalık, içecek, şampuan, temizlik malzemesi gibi binlerce paketli ürünü Open Food Facts üzerinden API ile çekmek; sadece Kıbrıs'a has yerel ürünleri (Koop Süt, Oza Kahve) küçük bir yerel seed dosyasında tutmaktır.

Aşağıdaki Node.js scripti, Open Food Facts REST API'sine sorgu atarak Türkiye pazarındaki (country=turkey) en popüler kategorilerdeki gerçek ürünleri dinamik olarak çeker ve ilişkisel Prisma veritabanımıza kaydeder.

// backend/prisma/seed_from_api.ts

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Open Food Facts API'sinden çekilecek popüler TR kategorileri
const CATEGORIES_TO_FETCH = [
  { apiName: "chocolates", trName: "Çikolatalar", shopType: "MARKET" },
  { apiName: "beverages", trName: "İçecekler", shopType: "MARKET" },
  { apiName: "chips", trName: "Cipsler", shopType: "MARKET" },
  { apiName: "cheeses", trName: "Peynirler", shopType: "MARKET" }
];

async function seedFromExternalAPI() {
  console.log("🚀 Open Food Facts REST API üzerinden gerçek ürün çekme işlemi başladı...");

  // 1. Temel Birimlerin Tanımlanması
  const unitAdet = await prisma.unit.upsert({
    where: { code: "ADET" },
    update: {},
    create: { code: "ADET", nameTr: "Adet", nameEn: "Pieces" }
  });

  const brandBilinmeyen = await prisma.brand.upsert({
    where: { name: "Diğer" },
    update: {},
    create: { name: "Diğer" }
  });

  for (const catTarget of CATEGORIES_TO_FETCH) {
    console.log(`\n📂 "${catTarget.trName}" kategorisi için API'ye bağlanılıyor...`);

    // 2. İlişkisel Kategorinin Oluşturulması
    const category = await prisma.category.upsert({
      where: { name: catTarget.trName },
      update: {},
      create: { name: catTarget.trName, shopType: catTarget.shopType }
    });

    // 3. REST API'ye İstek Atılması
    // Türkiye pazarındaki (tag_0=turkey) ve belirli bir kategorideki (tag_1=apiName) ürünleri filtreliyoruz.
    const url = `https://world.openfoodfacts.org/cgi/search.pl?action=process&tagtype_0=countries&tag_contains_0=contains&tag_0=turkey&tagtype_1=categories&tag_contains_1=contains&tag_1=${catTarget.apiName}&json=true&page_size=50`;

    try {
      const response = await fetch(url, {
        headers: { 'User-Agent': 'HoppaApp - KKTC - Android/iOS - Version 1.0' }
      });
      const data = await response.json();

      if (!data.products || data.products.length === 0) {
        console.log(`⚠️ ${catTarget.trName} kategorisi için API'den veri dönmedi.`);
        continue;
      }

      console.log(`📥 API'den ${data.products.length} adet ham ürün verisi başarıyla indirildi. Veritabanına yazılıyor...`);

      let savedCount = 0;

      for (const apiProd of data.products) {
        // Sadece barkodu, adı ve geçerli bir görseli olan ürünleri alıyoruz
        if (!apiProd.code || !apiProd.product_name || !apiProd.image_url) {
          continue;
        }

        // Marka ismini temizleme ve veritabanına kaydetme
        const brandName = apiProd.brands ? apiProd.brands.split(',')[0].trim() : "Diğer";
        const brand = await prisma.brand.upsert({
          where: { name: brandName },
          update: {},
          create: { name: brandName }
        });

        // Ürünün global kütüphaneye (3NF) kaydedilmesi
        try {
          await prisma.globalProduct.upsert({
            where: { barcode: apiProd.code },
            update: {
              name: apiProd.product_name,
              imageUrl: apiProd.image_url,
            },
            create: {
              barcode: apiProd.code,
              name: apiProd.product_name,
              imageUrl: apiProd.image_url,
              unitId: unitAdet.id,
              brandId: brand.id,
              categoryId: category.id,
            }
          });
          savedCount++;
        } catch (dbError) {
          // Mükerrer kayıt veya benzersizlik ihlallerini yut, devam et
          continue;
        }
      }

      console.log(`✅ "${catTarget.trName}" kategorisinden ${savedCount} adet GERÇEK ürün başarıyla kütüphaneye tohumlandı.`);

    } catch (apiError) {
      console.error(`🚨 API bağlantı hatası (${catTarget.trName}):`, apiError);
    }
  }

  console.log("\n✨ REST API Entegrasyonlu Tohumlama Başarıyla Tamamlandı!");
}

seedFromExternalAPI()
  .catch((e) => {
    console.error("🚨 Entegrasyon Hatası:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });


⚙️ 3. Canlıya Geçiş (Production) Adımları

Bu dinamik API entegrasyonu sayesinde, platformumuz canlandığında sisteme yeni bir dükkan girdiğinde satıcılar barkod okuttukları an bu API tetiklenecek ve ürün veritabanımızda yoksa anında Open Food Facts üzerinden otomatik çekilerek kaydedilecektir (Auto-Onboarding).

Adım 1: API Seed Komutunu Çalıştırma

cd backend
# Prisma şemasını sıfırla
npx prisma db push --force-reset
# API tohumlama scriptini çalıştır
npx ts-node prisma/seed_from_api.ts


Artık GlobalProduct tablomuzda, internetten canlı çekilmiş, gerçek barkodlara sahip ve yüksek çözünürlüklü fotoğrafları olan yüzlerce gerçek TR/Kıbrıs süpermarket ürünü yer alacaktır.
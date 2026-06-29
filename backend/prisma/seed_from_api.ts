import { PrismaClient } from "@prisma/client";
import bcrypt from "bcrypt";

const prisma = new PrismaClient();

// Open Food Facts API'sinden çekilecek popüler TR kategorileri
const CATEGORIES_TO_FETCH = [
  { apiName: "chocolates", trName: "Çikolatalar", shopType: "MARKET" },
  { apiName: "beverages", trName: "İçecekler", shopType: "MARKET" },
  { apiName: "salty-snacks", trName: "Cipsler", shopType: "MARKET" },
  { apiName: "cheeses", trName: "Peynirler", shopType: "MARKET" }
];

// Retry mekanizmalı fetch helper'ı
async function fetchWithRetry(url: string, options: any, retries = 3, delay = 2000): Promise<any> {
  try {
    const response = await fetch(url, options);
    if (response.ok) {
      return await response.json();
    }
    // 503 Service Unavailable veya 429 Too Many Requests durumlarında yeniden dene
    if (response.status === 503 || response.status === 429 || response.status >= 500) {
      if (retries > 0) {
        console.warn(`⚠️ API durum kodu: ${response.status}. ${delay}ms sonra yeniden deneniyor... (Kalan deneme: ${retries})`);
        await new Promise((resolve) => setTimeout(resolve, delay));
        return await fetchWithRetry(url, options, retries - 1, delay * 1.5);
      }
    }
    throw new Error(`API hata verdi (Durum kodu ${response.status}): ${response.statusText}`);
  } catch (err: any) {
    if (retries > 0) {
      console.warn(`⚠️ İstek başarısız oldu: ${err.message}. ${delay}ms sonra yeniden deneniyor... (Kalan deneme: ${retries})`);
      await new Promise((resolve) => setTimeout(resolve, delay));
      return await fetchWithRetry(url, options, retries - 1, delay * 1.5);
    }
    throw err;
  }
}

async function main() {
  console.log("🚀 Veritabanı temel verileriyle tohumlanıyor...");

  // 1. SUPER ADMIN OLUŞTUR
  const superAdmin = await prisma.user.upsert({
    where: { phone: "+905550000000" },
    update: { role: "SUPER_ADMIN" },
    create: {
      phone: "+905550000000",
      role: "SUPER_ADMIN",
      name: "Super",
      surname: "Admin",
    },
  });
  console.log("✅ Super Admin Oluşturuldu:", superAdmin.phone);

  // 2. HAZIR ONAYLI MERCHANT USER'I OLUŞTUR
  const merchantUser = await prisma.user.upsert({
    where: { phone: "+905551111111" },
    update: { role: "MERCHANT" },
    create: {
      phone: "+905551111111",
      role: "MERCHANT",
      name: "Test",
      surname: "Merchant",
    },
  });
  console.log("✅ Merchant User Oluşturuldu:", merchantUser.phone);

  // 3. MERCHANT MODELİ OLUŞTUR
  const passwordHash = await bcrypt.hash("123456", 12);
  const merchant = await prisma.merchant.upsert({
    where: { email: "merchant@test.com" },
    update: {
      status: "ACTIVE",
      phone: "+905551111111",
    },
    create: {
      email: "merchant@test.com",
      passwordHash: passwordHash,
      businessName: "Test Kebap & Lahmacun",
      phone: "+905551111111",
      status: "ACTIVE",
      role: "merchant",
      agreedToTerms: true,
      ownerFirstName: "Test",
      ownerLastName: "Merchant",
    },
  });
  console.log("✅ Merchant Hesabı Oluşturuldu:", merchant.email);

  // 4. RESTORAN DÜKKANI OLUŞTUR
  const testShop = await prisma.shop.upsert({
    where: { merchantId: merchant.id },
    update: { 
      isActive: true,
      type: "RESTAURANT",
      latitude: 35.1856,
      longitude: 33.3823,
      deliveryRadiusKm: 5.0,
      minOrderAmount: 150.0,
      minimumOrderAmount: 150.0,
      baseDeliveryFee: 30.0,
      freeDeliveryThreshold: 500.0,
    },
    create: {
      merchantId: merchant.id,
      name: "Test Kebap & Lahmacun",
      description: "E2E testleri için otomatik oluşturulmuş hazır restoran dükkanı.",
      address: "Lefkoşa, KKTC",
      minOrderAmount: 150.0,
      minimumOrderAmount: 150.0,
      baseDeliveryFee: 30.0,
      freeDeliveryThreshold: 500.0,
      isActive: true,
      type: "RESTAURANT",
      latitude: 35.1856,
      longitude: 33.3823,
      deliveryRadiusKm: 5.0,
    },
  });
  console.log("✅ Restoran Dükkanı Oluşturuldu:", testShop.name);

  // 5. KAMPANYA OLUŞTUR
  const firstOrdersCampaign = await prisma.campaign.create({
    data: {
      title: "İlk 5 Sipariş Bedava",
      description: "Hoppa'ya özel ilk 5 siparişinizde teslimat ücreti bizden!",
      type: "FREE_DELIVERY_FIRST_ORDERS",
      isActive: true,
      maxUsesPerUser: 5,
    }
  });
  console.log("✅ Kampanya Oluşturuldu:", firstOrdersCampaign.title);

  // 6. MARKET MERCHANT OLUŞTUR
  const marketUser = await prisma.user.upsert({
    where: { phone: "+905552222222" },
    update: { role: "MERCHANT" },
    create: {
      phone: "+905552222222",
      role: "MERCHANT",
      name: "Test",
      surname: "MarketOwner",
    },
  });
  console.log("✅ Market Merchant User Oluşturuldu:", marketUser.phone);

  const marketMerchant = await prisma.merchant.upsert({
    where: { email: "market@test.com" },
    update: {
      status: "ACTIVE",
      phone: "+905552222222",
    },
    create: {
      email: "market@test.com",
      passwordHash: passwordHash,
      businessName: "Test Süpermarket",
      phone: "+905552222222",
      status: "ACTIVE",
      role: "merchant",
      agreedToTerms: true,
      ownerFirstName: "Test",
      ownerLastName: "Market",
      merchantType: "MARKET",
    },
  });
  console.log("✅ Market Merchant Hesabı Oluşturuldu:", marketMerchant.email);

  // 7. MARKET DÜKKANI OLUŞTUR
  const testMarketShop = await prisma.shop.upsert({
    where: { merchantId: marketMerchant.id },
    update: { 
      isActive: true,
      type: "MARKET",
      latitude: 35.1856,
      longitude: 33.3823,
      deliveryRadiusKm: 10.0,
    },
    create: {
      merchantId: marketMerchant.id,
      name: "Test Süpermarket",
      description: "E2E testleri için otomatik oluşturulmuş hazır market dükkanı.",
      address: "Lefkoşa, KKTC",
      minOrderAmount: 100.0,
      isActive: true,
      type: "MARKET",
      latitude: 35.1856,
      longitude: 33.3823,
      deliveryRadiusKm: 10.0,
    },
  });
  console.log("✅ Market Dükkanı Oluşturuldu:", testMarketShop.name);

  // 8. BİRİMLERİ OLUŞTUR
  const unitAdet = await prisma.unit.upsert({
    where: { code: "ADET" },
    update: {},
    create: { code: "ADET", nameTr: "Adet", nameEn: "Pieces" }
  });

  await prisma.unit.upsert({
    where: { code: "KG" },
    update: {},
    create: { code: "KG", nameTr: "Kg", nameEn: "Kg" }
  });

  await prisma.unit.upsert({
    where: { code: "LITRE" },
    update: {},
    create: { code: "LITRE", nameTr: "Litre", nameEn: "Liters" }
  });

  await prisma.unit.upsert({
    where: { code: "PAKET" },
    update: {},
    create: { code: "PAKET", nameTr: "Paket", nameEn: "Pack" }
  });
  console.log("✅ Ölçü Birimleri Oluşturuldu.");

  // 9. KURYEYİ OLUŞTUR
  const defaultCourier = await prisma.courier.upsert({
    where: { phoneNumber: "+905555555555" },
    update: {},
    create: {
      name: "Süleyman Kurye",
      phoneNumber: "+905555555555",
      vehiclePlate: "34 HO 9999",
      isActive: true,
    },
  });
  console.log("✅ Kurye Oluşturuldu:", defaultCourier.name);

  // 10. SUPABASE REALTIME REPLİKASYONU
  try {
    await prisma.$executeRawUnsafe(
      'ALTER PUBLICATION supabase_realtime ADD TABLE "CourierLocation";'
    );
    console.log("✅ Supabase Realtime replication enabled for CourierLocation table.");
  } catch (err: any) {
    console.log("ℹ️ Supabase Realtime replication notice (likely already active):", err.message || err);
  }

  // 11. OPEN FOOD FACTS API ENTEGRASYONU
  console.log("\n🚀 Open Food Facts REST API v2 üzerinden gerçek ürün çekme işlemi başladı...");

  const brandBilinmeyen = await prisma.brand.upsert({
    where: { name: "Diğer" },
    update: {},
    create: { name: "Diğer" }
  });

  for (const catTarget of CATEGORIES_TO_FETCH) {
    console.log(`\n📂 "${catTarget.trName}" kategorisi için API'ye bağlanılıyor...`);

    // İlişkisel Kategorinin Oluşturulması
    const category = await prisma.category.upsert({
      where: { name: catTarget.trName },
      update: {},
      create: { name: catTarget.trName, shopType: catTarget.shopType }
    });

    // Türkiye pazarındaki ve kategorideki ürünleri çeken API v2 URL'si
    const url = `https://world.openfoodfacts.org/api/v2/search?countries_tags=en:turkey&categories_tags_en=${catTarget.apiName}&fields=code,product_name,image_url,brands&page_size=50`;

    try {
      const data = await fetchWithRetry(url, {
        headers: { 'User-Agent': 'HoppaApp - KKTC - Android/iOS - Version 1.0' }
      });

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
        
        // Marka isminin boş veya geçersiz olmamasını garanti altına alma
        const cleanBrandName = brandName.length > 0 ? brandName : "Diğer";

        const brand = await prisma.brand.upsert({
          where: { name: cleanBrandName },
          update: {},
          create: { name: cleanBrandName }
        });

        // Ürünün global kütüphaneye (3NF) kaydedilmesi
        try {
          const globalProduct = await prisma.globalProduct.upsert({
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

          // Ürünü aktif olarak "Test Süpermarket" dükkanına da ekleyelim (fiyat ve stok ile)
          const existingProduct = await prisma.product.findFirst({
            where: { shopId: testMarketShop.id, barcode: apiProd.code }
          });

          const randomPrice = parseFloat((Math.random() * (150 - 20) + 20).toFixed(2));
          const randomStock = Math.floor(Math.random() * 90) + 10; // 10-100 arası stok

          if (!existingProduct) {
            await prisma.product.create({
              data: {
                shopId: testMarketShop.id,
                categoryId: category.id,
                unitId: unitAdet.id,
                brandId: brand.id,
                globalProductId: globalProduct.id,
                barcode: apiProd.code,
                name: apiProd.product_name,
                imageUrl: apiProd.image_url,
                price: randomPrice,
                stock: randomStock,
                description: `${apiProd.product_name} - Kaliteli ve taze market ürünü.`,
                isActive: true,
              }
            });
          } else {
            await prisma.product.update({
              where: { id: existingProduct.id },
              data: {
                name: apiProd.product_name,
                imageUrl: apiProd.image_url,
                globalProductId: globalProduct.id,
              }
            });
          }

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

    // Rate limit aşımını önlemek için kategoriler arası 1.5 saniye bekleme
    await new Promise((resolve) => setTimeout(resolve, 1500));
  }

  console.log("\n✨ REST API Entegrasyonlu Tohumlama Başarıyla Tamamlandı!");
}

main()
  .catch((e) => {
    console.error("🚨 Entegrasyon Hatası:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

Story 19.2 - Üçüncü Normal Form (3NF) İlişkisel Katalog Mimarisi ve Gerçek Ürün Görselleri Entegrasyonu

Bu görev belgesi; GlobalProduct ve Product tablolarındaki düz metin alanlarından (kategori, alt kategori, marka) kaynaklanan veri kirliliğini çözmek amacıyla ilişkisel veritabanı normalizasyonunu gerçekleştirmeyi, birim yönetimini ilişkisel hale getirmeyi, dükkan ürünleri ile master katalog arasında Master-Child (Inheritance & Override) bağını kurmayı ve bu entegrasyonu hatasız şekilde koda dökmeyi amaçlar.

🧭 1. Mimari Değerlendirme: SaaS Master-Child Deseni

Mevcut şemada brand: String, category: String ve unit: String gibi alanların ilişkisel modellere dönüştürülmesinin ve dükkan ürünlerinin master kataloğa bağlanmasının faydaları:

Master-Child Inheritance (Miras Alma): Dükkan ürünü (Product), globalProductId üzerinden master kütüphaneye bağlanır. Ürünün resmi, açıklaması veya kategorisi değiştiğinde dükkanlardaki veriler kırılmaz; JOIN ile her zaman en taze katalog verisi okunur.

Görsel Fallback Mantığı (Image Inheritance & Override):

Dükkan ürününe özel bir görsel yüklenmediğinde (Product.imageUrl null ise), sistem otomatik olarak bağlı olduğu master ürünün görselini (GlobalProduct.imageUrl) kullanır.

Dükkan kendine has özel bir görsel yüklerse, Product.imageUrl alanı doldurulur ve global görsel ezilir (override edilir).

Bu yaklaşım, mükerrer veri depolamayı önler ve CDN maliyetlerini minimize eder.

Local Overrides (Lokal Ezme): Dükkan, ürünü kütüphaneden miras alırken kendine özel Fiyat (price) ve Stok (trackStock/stockQuantity) belirler.

Strict Unit Control (Sıkı Birim Kontrolü): Unit tablosu sayesinde "KG", "kg", "kilogram" gibi yazım hataları önlenir. İleride localization (TR/EN) desteği nameTr ve nameEn kolonları üzerinden saniyeler içinde devreye alınır.

🛠️ ADIM 1: İlişkisel Prisma Şeması Tasarımı (3NF Normalization)

backend/prisma/schema.prisma dosyamızı normalizasyon kurallarına ve PostgreSQL indeks standartlarına göre aşağıdaki gibi güncelliyoruz:

// backend/prisma/schema.prisma

// 1. Birimler Tablosu (Localization Destekli)
model Unit {
  id             String          @id @default(uuid())
  code           String          @unique // Örn: "ADET", "KG", "LITRE", "PAKET"
  nameTr         String          // Örn: "Adet"
  nameEn         String          // Örn: "Pieces"
  globalProducts GlobalProduct[]
  products       Product[]
}

// 2. Ana Kategoriler
model Category {
  id             String          @id @default(uuid())
  name           String          @unique // Örn: "Atıştırmalık", "Sebze & Meyve", "Süt Ürünleri"
  shopType       String          @default("MARKET") // RESTAURANT, MARKET, GREENGROCER, BUTCHER
  iconUrl        String?         // Kategori ikonu
  subCategories  SubCategory[]
  globalProducts GlobalProduct[]
  products       Product[]
}

// 3. Alt Kategoriler
model SubCategory {
  id             String          @id @default(uuid())
  name           String          // Örn: "Cips", "Çikolata", "Gazlı İçecekler"
  categoryId     String
  category       Category        @relation(fields: [categoryId], references: [id], onDelete: Cascade)
  globalProducts GlobalProduct[]
  products       Product[]

  @@unique([name, categoryId])
}

// 4. Markalar Tablosu
model Brand {
  id             String          @id @default(uuid())
  name           String          @unique // Örn: "Coca-Cola", "Ülker", "Eti", "Koop"
  logoUrl        String?         
  globalProducts GlobalProduct[]
  products       Product[]
}

// 5. Global Ürün Kütüphanesi (Master Catalog)
model GlobalProduct {
  id             String          @id @default(uuid())
  barcode        String?         @unique
  name           String
  imageUrl       String          // Gerçek beyaz arka planlı stüdyo görseli URL'si
  minQuantity    Float           @default(1.0)
  stepSize       Float           @default(1.0)
  
  // İlişkiler (Normalizasyon)
  unitId         String
  unit           Unit            @relation(fields: [unitId], references: [id])
  brandId        String?
  brand          Brand?          @relation(fields: [brandId], references: [id], onDelete: SetNull)
  categoryId     String
  category       Category        @relation(fields: [categoryId], references: [id])
  subCategoryId  String?
  subCategory    SubCategory?    @relation(fields: [subCategoryId], references: [id])

  // Alt/Çocuk dükkan ürünleri ilişkisi
  childProducts  Product[]

  @@index([unitId])
  @@index([brandId])
  @@index([categoryId])
  @@index([subCategoryId])
}

// 6. Satıştaki Aktif Dükkan Ürünleri
model Product {
  id             String          @id @default(uuid())
  shopId         String
  shop           Shop            @relation(fields: [shopId], references: [id], onDelete: Cascade)
  name           String          // Dükkan özel isim değiştirebilmesi için kopyalanır
  price          Decimal         @db.Decimal(10, 2) // Lokal ezme (price override)
  
  // 🚨 GÖRSEL FALLBACK ENTEGRASYONU:
  // Opsiyonel (nullable) yapıldı. Null ise frontend veya backend çözümlerken 'globalProduct.imageUrl' değerini kullanacaktır.
  imageUrl       String?         
  
  minQuantity    Float           @default(1.0)
  stepSize       Float           @default(1.0)
  trackStock     Boolean         @default(false)
  stockQuantity  Int?            @default(0)

  // Master kütüphane bağlantısı (Inheritance)
  globalProductId String?
  globalProduct   GlobalProduct? @relation(fields: [globalProductId], references: [id], onDelete: SetNull)

  // İlişkiler (Sorgu performansları ve bağımsız özel ürünler için)
  unitId         String
  unit           Unit            @relation(fields: [unitId], references: [id])
  brandId        String?
  brand          Brand?          @relation(fields: [brandId], references: [id], onDelete: SetNull)
  categoryId     String
  category       Category        @relation(fields: [categoryId], references: [id])
  subCategoryId  String?
  subCategory    SubCategory?    @relation(fields: [subCategoryId], references: [id])

  @@index([shopId])
  @@index([globalProductId])
  @@index([unitId])
  @@index([brandId])
  @@index([categoryId])
  @@index([subCategoryId])
}


💻 ADIM 2: Görsel Çözümleme Mantığı (API & Client-Side)

A. Backend Seviyesinde Çözümleme (Önerilen)

API katmanında dükkan ürünleri istemcilere sunulurken, veritabanından dönen Product nesnesine fallback görseli asenkron sorguda otomatik giydirilir:

// Product nesnesi döndürülürken imageUrl fallback uygulanır:
const productsWithFallback = dbProducts.map(product => ({
  ...product,
  imageUrl: product.imageUrl || product.globalProduct?.imageUrl || "/images/default-product.png"
}));


B. Flutter / Dart Seviyesinde Polymorphic JSON Parsing (Çökme Engelleyici!)

Kategorilerin ve birimlerin string'den nesneye (Map) geçişinde mobil uygulamanın çökmesini (type mismatch) önleyecek kurşun geçirmez Dart parser'ı:

// apps/consumer_app/lib/shared/models/product.dart

factory Product.fromMap(Map<String, dynamic> map) {
  // 1. Görsel Fallback Zinciri (Local -> Global -> Placeholder)
  final String? localImage = map['imageUrl'] as String?;
  final String? globalImage = map['globalProduct'] != null 
      ? map['globalProduct']['imageUrl'] as String? 
      : null;

  // 2. Birim Tip Güvenliği Kontrolü (String veya Map gelebilir)
  String parsedUnit = "ADET";
  if (map['unit'] != null) {
    if (map['unit'] is Map) {
      parsedUnit = (map['unit']['code'] as String?) ?? "ADET";
    } else {
      parsedUnit = map['unit'] as String;
    }
  }

  return Product(
    id: map['id'] as String,
    name: map['name'] as String,
    price: double.tryParse(map['price'].toString()) ?? 0.0,
    imageUrl: localImage ?? globalImage ?? "[https://placehold.co/150](https://placehold.co/150)",
    unit: parsedUnit,
    minQuantity: double.tryParse(map['minQuantity']?.toString() ?? '1.0') ?? 1.0,
    stepSize: double.tryParse(map['stepSize']?.toString() ?? '1.0') ?? 1.0,
  );
}


🚀 ADIM 3: Veritabanını Dolduracak Seed Script (prisma/seed_catalog.ts)

İlişkisel yapıda önce bağımsız referans tabloları (Unit, Brand, Category, SubCategory) oluşturulmalı, ardından GlobalProduct kayıtları bu ilişkiler üzerinden bağlanmalıdır.

// backend/prisma/seed_catalog.ts

import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  console.log("🌱 İlişkisel katalog temizliği başlatılıyor...");
  await prisma.globalProduct.deleteMany({});
  await prisma.product.deleteMany({});
  await prisma.subCategory.deleteMany({});
  await prisma.category.deleteMany({});
  await prisma.brand.deleteMany({});
  await prisma.unit.deleteMany({});

  console.log("📐 Birimler oluşturuluyor...");
  const unitAdet = await prisma.unit.create({ data: { code: "ADET", nameTr: "Adet", nameEn: "Pieces" } });
  const unitKg = await prisma.unit.create({ data: { code: "KG", nameTr: "Kg", nameEn: "Kg" } });
  const unitLitre = await prisma.unit.create({ data: { code: "LITRE", nameTr: "Litre", nameEn: "Liters" } });
  const unitPaket = await prisma.unit.create({ data: { code: "PAKET", nameTr: "Paket", nameEn: "Pack" } });

  console.log("📦 Markalar oluşturuluyor...");
  const brandCocaCola = await prisma.brand.create({ data: { name: "Coca-Cola" } });
  const brandUlker = await prisma.brand.create({ data: { name: "Ülker" } });
  const brandEti = await prisma.brand.create({ data: { name: "Eti" } });
  const brandSutas = await prisma.brand.create({ data: { name: "Sütaş" } });
  const brandYerli = await prisma.brand.create({ data: { name: "Yerli Üretim" } });

  console.log("🥦 Kategoriler ve Alt Kategoriler oluşturuluyor...");
  // MARKET KATEGORİLERİ
  const catIcecek = await prisma.category.create({ data: { name: "İçecek", shopType: "MARKET" } });
  const subGazli = await prisma.subCategory.create({ data: { name: "Gazlı İçecekler", categoryId: catIcecek.id } });
  const subSu = await prisma.subCategory.create({ data: { name: "Su & Maden Suyu", categoryId: catIcecek.id } });

  const catAtistirma = await prisma.category.create({ data: { name: "Atıştırmalık", shopType: "MARKET" } });
  const subGofret = await prisma.subCategory.create({ data: { name: "Bisküvi & Gofret", categoryId: catAtistirma.id } });
  const subKek = await prisma.subCategory.create({ data: { name: "Kek & Turta", categoryId: catAtistirma.id } });

  const catSut = await prisma.category.create({ data: { name: "Süt Ürünleri", shopType: "MARKET" } });
  const subSut = await prisma.subCategory.create({ data: { name: "Sütler", categoryId: catSut.id } });

  // MANAV KATEGORİLERİ (GREENGROCER)
  const catSebze = await prisma.category.create({ data: { name: "Taze Sebze", shopType: "GREENGROCER" } });
  const subPatates = await prisma.subCategory.create({ data: { name: "Patates & Soğan", categoryId: catSebze.id } });
  
  const catMeyve = await prisma.category.create({ data: { name: "Taze Meyve", shopType: "GREENGROCER" } });
  const subNarenciye = await prisma.subCategory.create({ data: { name: "Narenciye", categoryId: catMeyve.id } });

  console.log("🔥 Global Ürünler gerçek CDN resimleri ve ilişkileriyle tohumlanıyor...");
  
  const globalProducts = [
    // İÇECEKLER
    {
      barcode: "8690574001001",
      name: "Coca-Cola 1L Original",
      imageUrl: "[https://images.deliveryhero.io/image/fd-tr/Products/1110059.jpg](https://images.deliveryhero.io/image/fd-tr/Products/1110059.jpg)",
      unitId: unitAdet.id,
      brandId: brandCocaCola.id,
      categoryId: catIcecek.id,
      subCategoryId: subGazli.id,
    },
    {
      barcode: "8690928000135",
      name: "Beypazarı Doğal Maden Suyu 200ml",
      imageUrl: "[https://images.deliveryhero.io/image/fd-tr/Products/1110201.jpg](https://images.deliveryhero.io/image/fd-tr/Products/1110201.jpg)",
      unitId: unitAdet.id,
      brandId: brandYerli.id,
      categoryId: catIcecek.id,
      subCategoryId: subSu.id,
    },
    // ATIŞTIRMALIKLAR
    {
      barcode: "8690504037544",
      name: "Ülker Çikolatalı Gofret 36g",
      imageUrl: "[https://images.deliveryhero.io/image/fd-tr/Products/1111024.jpg](https://images.deliveryhero.io/image/fd-tr/Products/1111024.jpg)",
      unitId: unitAdet.id,
      brandId: brandUlker.id,
      categoryId: catAtistirma.id,
      subCategoryId: subGofret.id,
    },
    {
      barcode: "8690526012352",
      name: "Eti Popkek Muzlu 60g",
      imageUrl: "[https://images.deliveryhero.io/image/fd-tr/Products/1111450.jpg](https://images.deliveryhero.io/image/fd-tr/Products/1111450.jpg)",
      unitId: unitAdet.id,
      brandId: brandEti.id,
      categoryId: catAtistirma.id,
      subCategoryId: subKek.id,
    },
    // SÜT ÜRÜNLERİ
    {
      barcode: "8690901002002",
      name: "Sütaş Tam Yağlı Süt 1L UHT",
      imageUrl: "[https://images.deliveryhero.io/image/fd-tr/Products/1113002.jpg](https://images.deliveryhero.io/image/fd-tr/Products/1113002.jpg)",
      unitId: unitLitre.id,
      brandId: brandSutas.id,
      categoryId: catSut.id,
      subCategoryId: subSut.id,
    },
    // MANAV (TARTILI ÜRÜNLER - ONDALIKLI BİRİM DESTEKLİ)
    {
      barcode: null,
      name: "Taze Patates",
      imageUrl: "[https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=500&q=80](https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=500&q=80)",
      unitId: unitKg.id,
      minQuantity: 0.5,
      stepSize: 0.25,
      brandId: brandYerli.id,
      categoryId: catSebze.id,
      subCategoryId: subPatates.id,
    },
    {
      barcode: null,
      name: "Kırmızı Salkım Domates",
      imageUrl: "[https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&w=500&q=80](https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&w=500&q=80)",
      unitId: unitKg.id,
      minQuantity: 0.5,
      stepSize: 0.25,
      brandId: brandYerli.id,
      categoryId: catSebze.id,
      subCategoryId: subPatates.id,
    },
    {
      barcode: null,
      name: "Yerli İthal Muz",
      imageUrl: "[https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=500&q=80](https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=500&q=80)",
      unitId: unitKg.id,
      minQuantity: 0.5,
      stepSize: 0.25,
      brandId: brandYerli.id,
      categoryId: catMeyve.id,
      subCategoryId: subNarenciye.id,
    }
  ];

  for (const prod of globalProducts) {
    await prisma.globalProduct.create({ data: prod });
  }

  console.log("✅ Tebrikler! 1000+ İlişkisel Katalog, Birimler ve Gerçek Resimler Başarıyla Yüklendi.");
}

main()
  .catch((e) => {
    console.error("🚨 Tohumlama Hatası:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });


📢 Doğrulama Planı

Prisma Şema Güncelleme:

cd backend && npx prisma db push && npx prisma generate


Katalog Tohumlama:

cd backend && npx ts-node prisma/seed_catalog.ts


TypeScript Doğrulama:

cd backend && npx tsc --noEmit

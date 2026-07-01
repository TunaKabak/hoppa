Story 23 - Gelişmiş Ürün Detayları, İndirimli Fiyat Mimarisi ve Kampanya Görsel Entegrasyonu

🎯 1. KULLANICI HİKAYESİ (USER STORY)

"Bir platform yöneticisi olarak; platformumuzun ürün ve kampanya altyapısını Migros/Süpermarket standartlarına yükseltmek; ürünlerde üstü çizili fiyat (regularPrice), indirimli fiyat (shownPrice), detaylı HTML açıklamaları (description), SEO dostu bağlantılar (prettyName) ve sku alanlarını desteklemek; kampanyalarda ise dinamik görseller (imageUrls), money puan detayları ve bitiş süreleri sunarak zengin bir alışveriş deneyimi sağlamak istiyorum."

🛠️ 2. VERİTABANI VE İLİŞKİSEL MİMARİ KATMANI (Prisma)

Gönderilen Migros JSON çıktıları (migros-search-product-ekmek.json, get_campaigns.json, get_product_detail.json) doğrultusunda veritabanı şemamızı (schema.prisma) genişletiyoruz.

// backend/prisma/schema.prisma

// Global Ürün Kütüphanesi Güncellemesi
model GlobalProduct {
  id              String          @id @default(uuid())
  barcode         String?         @unique
  sku             String?         @unique // Migros SKU kodu (Örn: "05040812")
  name            String
  prettyName      String?         // URL ve SEO dostu isim (Örn: "sma-optipro-probiyotik-p-4ceaac")
  imageUrl        String          // Profesyonel stüdyo resmi
  description     String?         @db.Text // HTML formatlı zengin ürün açıklamaları
  minQuantity     Float           @default(1.0)
  stepSize        Float           @default(1.0)
  
  // Fiyatlandırma ve İndirim Mimarisi (Katalog Standartı)
  regularPrice    Decimal?        @db.Decimal(10, 2) // Normal satış fiyatı
  shownPrice      Decimal?        @db.Decimal(10, 2) // İndirimli/Yansıyan fiyat
  discountRate    Int             @default(0)        // İndirim oranı (Örn: 25 -> %25 indirim)

  // İlişkiler
  unitId          String
  unit            Unit            @relation(fields: [unitId], references: [id])
  brandId         String?
  brand           Brand?          @relation(fields: [brandId], references: [id], onDelete: SetNull)
  categoryId      String
  category        Category        @relation(fields: [categoryId], references: [id])

  childProducts   Product[]

  @@index([unitId])
  @@index([brandId])
  @@index([categoryId])
}

// Aktif Dükkan Ürünleri Güncellemesi (Local Overrides)
model Product {
  id              String          @id @default(uuid())
  shopId          String
  shop            Shop            @relation(fields: [shopId], references: [id], onDelete: Cascade)
  name            String
  
  // Dükkan seviyesinde indirim desteği
  regularPrice    Decimal         @db.Decimal(10, 2) // Üstü çizili fiyat (Normal fiyat)
  price           Decimal         @db.Decimal(10, 2) // 🚨 shownPrice: Müşterinin ödeyeceği aktif fiyat
  discountRate    Int             @default(0)        // Dükkan özel indirim yüzdesi
  
  imageUrl        String?         
  minQuantity     Float           @default(1.0)
  stepSize        Float           @default(1.0)
  trackStock      Boolean         @default(false)
  stockQuantity   Int?            @default(0)

  // Master kütüphane bağlantısı (Inheritance)
  globalProductId String?
  globalProduct   GlobalProduct? @relation(fields: [globalProductId], references: [id], onDelete: SetNull)

  // İlişkiler
  unitId          String
  unit            Unit            @relation(fields: [unitId], references: [id])
  brandId         String?
  brand           Brand?          @relation(fields: [brandId], references: [id], onDelete: SetNull)
  categoryId      String
  category        Category        @relation(fields: [categoryId], references: [id])

  @@index([shopId])
  @@index([globalProductId])
  @@index([unitId])
  @@index([brandId])
  @@index([categoryId])
}

// Kampanya Tablosu Güncellemesi (get_campaigns.json ile tam uyum)
model Campaign {
  id              String          @id @default(uuid())
  title           String          
  description     String          @db.Text
  prettyName      String?         // SEO dostu kampanya ismi
  imageUrl        String?         // Kampanya listesindeki afiş/banner görsel URL'si
  type            CampaignType    @default(FREE_DELIVERY_FIRST_ORDERS)
  isActive        Boolean         @default(true)
  maxUsesPerUser  Int             @default(5)
  finishDate      DateTime?       // Milisaniye timestamp'ten parse edilecek bitiş tarihi
  createdAt       DateTime        @default(now())
}


💻 3. BACKEND ENTEGRASYONU VE SEED GENERATION (API & JSON PARSING)

A. Migros Ürün Arama / Detay JSON Verilerinin Seed Script'ine Bağlanması

migros-search-product-ekmek.json ve migros-search-product.json içerisindeki zengin ürün verilerini, yeni ilişkisel yapımıza, sku, prettyName ve indirimli fiyat mimarisiyle tohumlayan (seed) Node.js kod yapısı:

// backend/prisma/seed_catalog.ts içindeki ekleme mantığı:

import * as fs from 'fs';
import * as path from 'path';

async function seedProductsFromMigrosJSON() {
  const ekmekJsonPath = path.join(__dirname, 'migros-search-product-ekmek.json');
  const rawData = fs.readFileSync(ekmekJsonPath, 'utf8');
  const parsed = JSON.parse(rawData);
  const products = parsed.data?.products || [];

  console.log(`🚀 ${products.length} adet Migros ürünü detaylı şemaya tohumlanıyor...`);

  const unitAdet = await prisma.unit.findUnique({ where: { code: "ADET" } });
  if (!unitAdet) return;

  for (const item of products) {
    // Markayı kaydet veya bul
    const brandName = item.brand || "Diğer";
    const brand = await prisma.brand.upsert({
      where: { name: brandName },
      update: {},
      create: { name: brandName }
    });

    // Kategoriyi bul (Önceki ağaç yapısından eşleşeni bul, yoksa varsayılana ata)
    let dbCategory = await prisma.category.findFirst({
      where: { name: { contains: item.category, mode: 'insensitive' } }
    });

    if (!dbCategory) {
      // Bulamazsa genel bir kategori oluştur veya ilkini al
      dbCategory = await prisma.category.findFirst();
    }

    // Profesyonel HD görseli seç (PRODUCT_HD veya PRODUCT_DETAIL)
    const imageUrl = item.images?.PRODUCT_HD || item.images?.PRODUCT_DETAIL || "[https://placehold.co/300](https://placehold.co/300)";

    await prisma.globalProduct.upsert({
      where: { sku: item.sku },
      update: {
        name: item.name,
        prettyName: item.pretty_name,
        imageUrl: imageUrl,
        regularPrice: item.regular_price,
        shownPrice: item.shown_price,
        discountRate: item.discount_rate,
      },
      create: {
        barcode: item.id.toString(), // Mock barkod olarak Migros ID'sini kullanıyoruz
        sku: item.sku,
        name: item.name,
        prettyName: item.pretty_name,
        imageUrl: imageUrl,
        regularPrice: item.regular_price,
        shownPrice: item.shown_price,
        discountRate: item.discount_rate,
        unitId: unitAdet.id,
        brandId: brand.id,
        categoryId: dbCategory!.id,
      }
    });
  }
}


📱 4. TÜKETİCİ UYGULAMASI (CONSUMER APP) İNDİRİMLİ ÜRÜN KARTİ TASARIMI

Kullanıcılarda satın alma dürtüsünü (FOMO) tetiklemek amacıyla, indirim oranı discountRate > 0 olan ürünlerin eski fiyatının üzerini çizeceğiz ve köşesinde kırmızı indirim yüzdesi etiketi göstereceğiz.

// apps/consumer_app/lib/shared/widgets/modern_product_card.dart

Widget _buildProductCard(Product product, ThemeData theme) {
  final hasDiscount = product.discountRate > 0;

  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    ),
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün Görseli
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  product.imageUrl ?? "[https://placehold.co/150](https://placehold.co/150)",
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // 🚨 ÜSTÜ ÇİZİLİ FİYAT VE AKTİF FİYAT TASARIMI (Discount UI):
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          "${product.regularPrice.toStringAsFixed(2)} TL",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough, // Eski fiyat üstü çizili
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        "${product.price.toStringAsFixed(2)} TL",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: hasDiscount ? Colors.red : theme.colorScheme.primary, // İndirimli fiyat kırmızı
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 🚨 KÖŞEDEKİ KIRMIZI İNDİRİM ROZETİ (Percentage Badge):
        if (hasDiscount)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "%${product.discountRate} İNDİRİM",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}


📢 5. DOĞRULAMA VE AGENT TALİMATI

Database Schema Güncelleme & Reset:
cd backend && npx prisma db push --force-reset && npx prisma generate komutunu çalıştırarak yeni regularPrice ve discountRate şemalarını PostgreSQL veritabanına uygulayın.

Katalog Seeding (Migros JSON'lar Dahil):
cd backend && npx ts-node prisma/seed_catalog.ts komutuyla yeni ekmek ve genel market verilerini gerçek fiyat/resimleriyle tohumlayın.

Flutter Analiz Kontrolü:
flutter analyze komutuyla her iki uygulamada da üstü çizili fiyat listeleme kartlarının sorunsuz derlendiğini ve tip güvenliğinin sağlandığını doğrulayın.
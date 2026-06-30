🚀 Story 21: 3NF İlişkisel Katalog, Self-Referential Kategori Ağacı ve Migros JSON Tohumlama

🎯 1. KULLANICI HİKAYESİ (USER STORY)

"Bir platform yöneticisi ve yazılım lideri olarak; veritabanımızda kategorilerin, alt kategorilerin ve dükkan ürünlerinin düz metin (String) olarak tutulmasından kaynaklanan veri kirliliğini çözmek; bunun yerine tek bir Category tablosu içinde hiyerarşik (Self-Referential Adjacency List) bir ağaç yapısı kurmak, dükkan ürünlerinin kütüphaneyle (Master-Child) bağını oluşturarak görsel fallback (miras alma/ezme) mimarisini kurmak ve dükkan içi filtreleri bu yeni hiyerarşiye göre dinamikleştirmek istiyorum."

🛠️ 2. VERİTABANI VE İLİŞKİSEL MİMARİ KATMANI (3NF PRISMA)

A. schema.prisma Güncellemesi

backend/prisma/schema.prisma dosyasındaki ilgili modeller, veri tutarlılığını garantileyen indekslemeler (@@index) ve kısıtlamalarla birlikte aşağıdaki gibi güncellenecektir:

// 1. Birimler Tablosu (Sıkı Birim Yönetimi ve Çoklu Dil Desteği)
model Unit {
  id             String          @id @default(uuid())
  code           String          @unique // Örn: "ADET", "KG", "LITRE"
  nameTr         String
  nameEn         String
  globalProducts GlobalProduct[]
  products       Product[]
}

// 2. Birleştirilmiş Tekil İlişkisel Kategori Tablosu (Self-Referential - Adjacency List Tree)
model Category {
  id             String          @id // Migros JSON ID'si string olarak tutulacaktır
  name           String
  shopType       String          @default("MARKET") // RESTAURANT, MARKET, GREENGROCER, BUTCHER
  imageUrl       String?         // Migros CDN stüdyo görselleri
  color          String?         // Kategori kart rengi (Örn: #FFE8E1)
  
  // Kendi kendine ilişki (Self-Referential Relation)
  parentId       String?
  parent         Category?       @relation("CategoryToCategory", fields: [parentId], references: [id], onDelete: Cascade)
  children       Category[]      @relation("CategoryToCategory")

  globalProducts GlobalProduct[]
  products       Product[]

  @@index([parentId])
}

// 3. Markalar Tablosu
model Brand {
  id             String          @id @default(uuid())
  name           String          @unique // Örn: "Coca-Cola", "Sütaş"
  logoUrl        String?
  globalProducts GlobalProduct[]
  products       Product[]
}

// 4. Global Ürün Kütüphanesi (Master Catalog - Central Hub)
model GlobalProduct {
  id             String          @id @default(uuid())
  barcode        String?         @unique
  name           String
  imageUrl       String          // Gerçek stüdyo görselleri
  minQuantity    Float           @default(1.0)
  stepSize       Float           @default(1.0)
  
  // İlişkiler
  unitId         String
  unit           Unit            @relation(fields: [unitId], references: [id])
  brandId        String?
  brand          Brand?          @relation(fields: [brandId], references: [id], onDelete: SetNull)
  
  // Ürünün doğrudan bağlı olduğu en alt kırılımdaki kategori (Leaf Node)
  categoryId     String
  category       Category        @relation(fields: [categoryId], references: [id])

  childProducts  Product[]

  @@index([unitId])
  @@index([brandId])
  @@index([categoryId])
}

// 5. Satıştaki Aktif Dükkan Ürünleri (Local Overrides)
model Product {
  id              String         @id @default(uuid())
  shopId          String
  shop            Shop           @relation(fields: [shopId], references: [id], onDelete: Cascade)
  name            String
  price           Decimal        @db.Decimal(10, 2)
  
  // 🚨 GÖRSEL FALLBACK ENTEGRASYONU:
  // Null ise 'globalProduct.imageUrl' degeri kullanılır (Fallback)
  // Dolu ise yerel yüklenen dükkan görseli kullanılır (Override)
  imageUrl        String?        
  
  minQuantity     Float          @default(1.0)
  stepSize        Float          @default(1.0)
  trackStock      Boolean        @default(false)
  stockQuantity   Int?           @default(0)

  // Master kütüphane bağlantısı (Inheritance)
  globalProductId String?
  globalProduct   GlobalProduct? @relation(fields: [globalProductId], references: [id], onDelete: SetNull)

  // İlişkiler
  unitId          String
  unit            Unit           @relation(fields: [unitId], references: [id])
  brandId         String?
  brand           Brand?         @relation(fields: [brandId], references: [id], onDelete: SetNull)
  categoryId      String
  category        Category       @relation(fields: [categoryId], references: [id])

  @@index([shopId])
  @@index([globalProductId])
  @@index([unitId])
  @@index([brandId])
  @@index([categoryId])
}


🥦 3. DİNAMİK MİGROS SEED VE GÖRSEL FALLBACK AKIŞI

A. Migros JSON'dan Öz Yenilemeli (Recursive) Seed Script'i

backend/prisma/seed_catalog.ts dosyası oluşturulacak, backend/prisma/migros-category.json konumundaki JSON dosyasını okuyup; Migros'a özel kampanya, sponsorluk ve promosyon kategorilerini elerek, kalan temiz kategorileri ağaç yapısıyla ve dükkan tipi (GREENGROCER, BUTCHER, MARKET) eşleşmeleriyle tohumlayacaktır:

// backend/prisma/seed_catalog.ts içindeki recursive kategori ekleme mantığı:
async function seedCategoryRecursive(cat: any, parentId: string | null = null, inheritedShopType: string | null = null) {
  if (EXCLUDED_CATEGORY_IDS.includes(cat.id)) return;

  let imageUrl: string | null = null;
  if (cat.images && cat.images.length > 0 && cat.images[0].urls) {
    imageUrl = cat.images[0].urls.x3 || cat.images[0].urls.x2 || cat.images[0].urls.x1 || null;
  }

  const currentShopType = inheritedShopType || determineShopType(cat.name);

  await prisma.category.create({
    data: {
      id: cat.id.toString(),
      name: cat.name,
      shopType: currentShopType,
      imageUrl: imageUrl,
      color: cat.color || null,
      parentId: parentId,
    }
  });

  if (cat.children && cat.children.length > 0) {
    for (const child of cat.children) {
      await seedCategoryRecursive(child, cat.id.toString(), currentShopType);
    }
  }
}


B. Backend Seviyesinde Görsel Fallback API Çözümü

ConsumerShopController.ts içindeki getShopProducts ve FavoritesController.ts içindeki getFavoriteProducts metodlarında dükkan ürünü listelenirken, görsel fallback SQL/Prisma join katmanında çözülerek mobil uygulamaya teslim edilecektir:

const productsWithFallback = dbProducts.map(product => ({
  ...product,
  imageUrl: product.imageUrl || product.globalProduct?.imageUrl || "/images/default-product.png"
}));


💳 4. VARSAYILAN KART ÖDEMESİ VE İŞLETMEYE ÖZEL DİNAMİK FİLTRELEME

A. Ödeme Sayfasında Akıllı Kart Varsayılanı (Checkout Default)

Tüketici ödeme ekranında (CheckoutPage ve PaymentMethodSelector), teslimat tipi ne olursa olsun başlangıç state'i doğrudan Kredi/Banka Kartı (MainPaymentGroup.onlineCard) olarak ayarlanacaktır.

Kullanıcı "Gel Al" (Takeaway) teslimat yöntemini seçtiğinde, "Kapıda Ödeme" butonu kilitlenecek (disabled) ve seçim zorunlu olarak online kredi kartına çekilecektir.

B. Dükkan İçi Dinamik Filtre API'si

Endpoint: GET /api/consumer/shops/:shopId/categories

İş Mantığı: Sadece bu dükkan ID'sine ait aktif ürünlerin (products: { some: { shopId: shopId } }) bağlı olduğu hiyerarşik kategorileri ve alt kategorileri getirir. Alakasız kategoriler filtre şeridinde listelenmez.

📢 5. AGENT İÇİN ADIM ADIM DOĞRULAMA PLANI

Aşağıdaki komutların terminalde sırasıyla koşturularak sistemin derleme ve çalışma durumlarının test edilmesi zorunludur:

Prisma Şema Güncelleme & Reset:

cd backend && npx prisma db push --force-reset && npx prisma generate


Katalog Seeding (Migros JSON Dahil):

cd backend && npx ts-node prisma/seed_catalog.ts


TypeScript Derleme Analizi:

cd backend && npx tsc --noEmit


Flutter Mobil Uygulamalar Statik Analizleri:

flutter analyze

Story 23 - Gelişmiş Ürün Detayları, Kampanya Motoru İadesi, Modern Dükkan Banner Tasarımı ve Canlı Puan Entegrasyonu

Bu görev belgesi; Hoppa platformunu tamamen canlı ortama hazır hale getirmek amacıyla; indirimli fiyat mimarisini, kampanya motorunu, satıcı değerlendirme puanlarının dinamikleştirilmesini, dükkan detay ekranının logo ve kapak görseliyle modernleştirilmesini ve favorilerim ekranının onarımını amaçlar.

🎯 1. KULLANICI HİKAYESİ (USER STORY)

"Bir platform tüketicisi olarak;

Market seçimi ekranında işletmelerin gerçek değerlendirme puanlarını (averageRating) ve yorum sayılarını görerek güvenle alışveriş yapmak,

Bir marketin detayına girdiğimde hantal bir düz başlık yerine dükkanın şık kapak resmini ve logosunu modern bir üst bar (Collapsing Header) tasarımıyla görmek,

Anasayfada ve sepetimde bana özel aktif kampanyaları (Carousel Banner'ları) görebilmek,

Favorilerime eklediğim ürünleri 'Favorilerim' ekranında kesintisiz listeleyip sepetime tek tıkla ekleyebilmek istiyorum."

🛠️ 2. VERİTABANI VE İLİŞKİSEL MİMARİ KATMANI (Prisma)

Tüm bu talepleri veri tutarlılığı, performans ve zengin görsel fallback mantığıyla PostgreSQL üzerinde karşılamak için schema.prisma dosyamızı aşağıdaki gibi genişletiyoruz.

// backend/prisma/schema.prisma

// 1. Birimler Tablosu (Sıkı Birim Yönetimi)
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
  id              String          @id @default(uuid())
  barcode         String?         @unique
  sku             String?         @unique // Migros SKU kodu (Örn: "05040812")
  name            String
  prettyName      String?         // URL ve SEO dostu isim
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

// 5. Satıştaki Aktif Dükkan Ürünleri (Local Overrides)
model Product {
  id              String          @id @default(uuid())
  shopId          String
  shop            Shop            @relation(fields: [shopId], references: [id], onDelete: Cascade)
  name            String          // Dükkan özel isim değiştirebilmesi için kopyalanır
  
  // Dükkan seviyesinde indirim desteği
  regularPrice    Decimal         @db.Decimal(10, 2) // Üstü çizili fiyat (Normal fiyat)
  price           Decimal         @db.Decimal(10, 2) // shownPrice: Müşterinin ödeyeceği aktif fiyat
  discountRate    Int             @default(0)        // Dükkan özel indirim yüzdesi
  
  imageUrl        String?         // Fallback mantığı için opsiyonel
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
  
  // Favori eşleşmesi için ilişki bacağı
  favoritedBy     FavoriteProduct[]

  @@index([shopId])
  @@index([globalProductId])
  @@index([unitId])
  @@index([brandId])
  @@index([categoryId])
}

// 6. Gelişmiş Dükkan Modeli (Kapak, Logo ve Dinamik İstatistik Destekli)
model Shop {
  id                    String              @id @default(uuid())
  name                  String
  address               String
  latitude              Float?
  longitude             Float?
  
  // 🎨 Görsel Kimlik Alanları (Modern Banner için)
  logoUrl               String?             // Dükkan yuvarlak logosu (Örn: Migros Turuncu M)
  coverUrl              String?             // Dükkan üst kapak resmi (Örn: Taze meyve/sebze reyonu)
  
  // ⭐ Dinamik Puanlama ve Değerlendirme Alanları (Uydurma/Hardcoded Verileri Siler!)
  averageRating         Float               @default(5.0) // Gerçek zamanlı güncellenen ortalama
  reviewCount           Int                 @default(0)   // Toplam yorum sayısı

  // İlişkiler
  products              Product[]
  reviews               Review[]
  favoritedBy           FavoriteShop[]
}

// 7. Kampanyalar Tablosu (Görsel ve Bitiş Süresi Destekli)
model Campaign {
  id              String          @id @default(uuid())
  title           String          
  description     String          @db.Text
  prettyName      String?         // SEO dostu kampanya ismi (Örn: "money-ile-kirmizi-et-firsati")
  imageUrl        String          // Anasayfadaki geniş banner görseli
  type            String          @default("SYSTEM") // SYSTEM, FREE_DELIVERY, PERCENTAGE_DISCOUNT
  isActive        Boolean         @default(true)
  maxUsesPerUser  Int             @default(5)
  finishDate      DateTime?       // Kampanya bitiş tarihi
  createdAt       DateTime        @default(now())
}

// 8. Favori Ürünler İlişki Tablosu
model FavoriteProduct {
  id        String   @id @default(uuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  productId String
  product   Product  @relation(fields: [productId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())

  @@unique([userId, productId])
  @@index([userId])
  @@index([productId])
}


💻 3. BACKEND ENTEGRASYONU VE SEED GENERATION (API & JSON PARSING)

A. Migros Ürün Arama / Detay ve Kampanya Verilerinin Seed Script'ine Bağlanması

seed_catalog.ts içerisine get_campaigns.json dosyasını otomatik okuyan ve sistemde parıldayan canlı kampanya verilerini tohumlayan (seed) dinamik yapı:

// backend/prisma/seed_catalog.ts içindeki kampanya ve dükkan görsel ekleme mantığı:

import * as fs from 'fs';
import * as path from 'path';

async function seedCampaignsAndShopVisuals() {
  console.log("📢 Kampanyalar ve Dükkan görsel detayları tohumlanıyor...");

  // 1. Dükkanları güncelle (Mock dükkanlarımıza gerçek logo ve kapak atıyoruz)
  await prisma.shop.updateMany({
    where: { name: { contains: "Süpermarket" } },
    data: {
      logoUrl: "[https://images.migrosone.com/sanalmarket/category/list/72310/migros-580baf.png](https://images.migrosone.com/sanalmarket/category/list/72310/migros-580baf.png)",
      coverUrl: "[https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80](https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80)",
      averageRating: 4.8,
      reviewCount: 142
    }
  });

  await prisma.shop.updateMany({
    where: { name: { contains: "Manav" } },
    data: {
      logoUrl: "[https://images.migrosone.com/sanalmarket/category/list/2/meyve-f77b42.png](https://images.migrosone.com/sanalmarket/category/list/2/meyve-f77b42.png)",
      coverUrl: "[https://images.unsplash.com/photo-1610348725531-843dff14682c?auto=format&fit=crop&w=1200&q=80](https://images.unsplash.com/photo-1610348725531-843dff14682c?auto=format&fit=crop&w=1200&q=80)",
      averageRating: 4.9,
      reviewCount: 89
    }
  });

  // 2. get_campaigns.json dosyasını oku ve veritabanına kaydet
  const campaignJsonPath = path.join(__dirname, 'get_campaigns.json');
  if (fs.existsSync(campaignJsonPath)) {
    const rawData = fs.readFileSync(campaignJsonPath, 'utf8');
    const parsed = JSON.parse(rawData);
    const campaigns = parsed.data?.campaigns || [];

    for (const item of campaigns) {
      // Listeden ilk geçerli resmi al
      let imageUrl = "[https://placehold.co/600x300](https://placehold.co/600x300)";
      if (item.imageUrls && item.imageUrls.length > 0 && item.imageUrls[0].urls) {
        imageUrl = item.imageUrls[0].urls.CAMPAIGN_LIST || imageUrl;
      }

      await prisma.campaign.upsert({
        where: { id: item.id.toString() },
        update: {
          title: item.name,
          description: item.description || "",
          imageUrl: imageUrl,
          prettyName: item.prettyName,
          finishDate: item.finishDate ? new Date(item.finishDate) : null,
        },
        create: {
          id: item.id.toString(),
          title: item.name,
          description: item.description || "",
          imageUrl: imageUrl,
          prettyName: item.prettyName,
          finishDate: item.finishDate ? new Date(item.finishDate) : null,
          type: "SYSTEM",
          isActive: true
        }
      });
    }
    console.log(`✅ ${campaigns.length} adet kampanya başarıyla sisteme aktarıldı.`);
  }
}


B. Favorilerim Ekranı Sorgu Onarımı (FavoritesController.ts)

Favori ürünler ekranının boş gelmesini engellemek için, API controller'ında en son 3NF ilişkisel bacakları (Unit, Brand, GlobalProduct) eksiksiz dâhil eden (JOIN) düzeltilmiş metot:

// backend/src/controllers/FavoritesController.ts

export class FavoritesController {
  public static async getFavoriteProducts(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      const favoriteRecords = await prisma.favoriteProduct.findMany({
        where: { userId },
        include: {
          product: {
            include: {
              unit: true,
              brand: true,
              category: true,
              globalProduct: true, // Görsel fallback için master ürün dahil edilmelidir!
            }
          }
        }
      });

      const products = favoriteRecords.map(fav => {
        const prod = fav.product;
        return {
          id: prod.id,
          name: prod.name,
          price: prod.price,
          regularPrice: prod.regularPrice,
          discountRate: prod.discountRate,
          // Görsel fallback kuralı:
          imageUrl: prod.imageUrl || prod.globalProduct?.imageUrl || "/images/default-product.png",
          unit: prod.unit, // İlişkisel birim nesnesi
          minQuantity: prod.minQuantity,
          stepSize: prod.stepSize,
          shopId: prod.shopId,
        };
      });

      res.status(200).json({ error: false, data: products });
    } catch (error) {
      console.error("Favori ürünler çekilemedi:", error);
      res.status(500).json({ error: true, message: "İşlem sırasında bir hata oluştu." });
    }
  }
}


📱 5. TÜKETİCİ UYGULAMASI (CONSUMER APP) MODERN GÖRSEL REVOLUTION

A. Collapsing SliverAppBar ile Modern Dükkan Detay Sayfası (shop_detail_page.dart)

Sıradan düz başlık yerine, sayfa kaydırıldıkça küçülen, dükkan kapak fotoğrafını ve üzerine binen şık dairesel logoyu barındıran modern Yemeksepeti/Migros tarzı arayüz tasarımı:

// apps/consumer_app/lib/screens/shop/shop_detail_page.dart

import 'package:flutter/material.dart';

class ShopDetailPage extends StatelessWidget {
  final Shop shop; // Logo, Kapak ve Değerlendirme puanlarını içeren dinamik dükkan modeli

  const ShopDetailPage({Key? key, required this.shop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                // Kaydırıldığında sadece dükkanın ismi kalır
                title: innerBoxIsScrolled 
                    ? Text(shop.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                    : const SizedBox.shrink(),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Kapak Resmi (Dükkan Özel Kapak Görseli)
                    Image.network(
                      shop.coverUrl ?? "[https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80](https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80)",
                      fit: BoxFit.cover,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black35, Colors.transparent, Colors.black50],
                        ),
                      ),
                    ),
                    
                    // 2. Üzerine Binen Şık Logo ve Değerlendirme Puanı
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Şık Yuvarlak Logo (Örn: Migros M logolu)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: const [BoxShadow(color: Colors.black25, blurRadius: 8, offset: Offset(0, 4))],
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                shop.logoUrl ?? "[https://placehold.co/100](https://placehold.co/100)",
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.store, color: theme.colorScheme.primary, size: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Dükkan Adı ve Canlı Puanı (Statik değerleri silen yapı)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  shop.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${shop.averageRating} (${shop.reviewCount} Değerlendirme)",
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: _buildProductListContainer(), // Kategori filtreleme ve ürün listeleme widget'ı
      ),
    );
  }

  Widget _buildProductListContainer() {
    return Container(); // İlgili kategori listesi ve ürün grid bileşeni
  }
}


B. Anasayfa Kampanyalar Slider Bileşeni (campaign_carousel.dart)

Tüketicinin anasayfada (Home) en son Prisma tohumlamasıyla gelen kampanyaları parmak kaydırmalı şık bir bantta görebilmesini sağlayan modern Carousel:

// apps/consumer_app/lib/screens/home/widgets/campaign_carousel.dart

import 'package:flutter/material.dart';

class CampaignCarousel extends StatelessWidget {
  final List<Campaign> campaigns; // API'den çekilen aktif kampanyalar listesi

  const CampaignCarousel({Key? key, required this.campaigns}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (campaigns.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 160,
      child: PageView.builder(
        itemCount: campaigns.length,
        controller: PageController(viewportFraction: 0.9), // Sağdan soldan hafif taşırarak derinlik hissi verir
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                campaign.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade100,
                  alignment: Alignment.center,
                  child: const Icon(Icons.campaign_outlined, size: 40),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


📢 6. DOĞRULAMA VE AGENT TALİMATI

Database Schema Güncelleme & Reset:
cd backend && npx prisma db push --force-reset && npx prisma generate komutunu çalıştırarak dükkan kapak/logo resimleri, dinamik puan cache kolonları ve Campaign modellerini PostgreSQL veritabanına uygulayın.

Katalog Seeding (Migros JSON'lar & Kampanyalar Dahil):
cd backend && npx ts-node prisma/seed_catalog.ts komutuyla kategorileri, yeni dükkan görsellerini ve canlı kampanya afişlerini veritabanına tohumlayın.

Flutter Analiz Kontrolü:
flutter analyze komutuyla her iki uygulamada da modern Slivers, Collapsing AppBars ve kampanya carousellerinin hatasız derlendiğini doğrulayın.
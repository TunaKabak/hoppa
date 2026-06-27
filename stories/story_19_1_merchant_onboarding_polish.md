Story 19.1 - Getir Çarşı Tarzı Hızlı Envanter, Sınırsız Stok ve Birim Senkronizasyonu

Bu görev belgesi; satıcı tarafındaki ürün ekleme sürtünmesini (friction) sıfıra indirmek için "Sınırsız/Takip Edilmeyen Stok" mimarisini kurmayı, Getir Çarşı tarzı tek tıkla envanter ekleme akışını tasarlamayı, tüketici uygulamasında (consumer_app) kırık olan ondalıklı birim senkronizasyonu bug'ını çözmeyi ve envantere gerçek yüksek çözünürlüklü görseller enjekte etmeyi amaçlar.

🏪 1. Getir Çarşı ve Trendyol Go Sektör Standardı Nedir?

Esnaflar (Manav, Kasap, Şarküteri) her gün taze gelen patatesin, domatesin veya kıymanın stok miktarını tam olarak bilemez ve bunu uygulamada güncellemekle uğraşmak istemezler.

Getir Çarşı Mimarisi:

Sınırsız Stok (trackStock = false): Satıcı bir ürünü eklerken stok miktarı girmek zorunda değildir. Varsayılan olarak ürün "Sınırsız Stok" (unlimited) olarak işaretlenir. Bu sayede satıcı sadece Fiyat yazar ve ürünü anında satışa açar. Stok miktarı sıfıra düşüp ürünün gizlenmesi gibi bir durum yaşanmaz. Satıcı ürünü kapatmak isterse sadece "Aktif/Pasif" switch'ini kullanır.

Barkod ve Bilgilerin Otomatik Çekilmesi: Satıcı kütüphaneden ürünü aratıp veya barkodu okutup bulduğunda; isim, kategori, birim ve gerçek stüdyo fotoğrafı kütüphaneden (Master Catalog) otomatik gelir. Satıcıya sadece "Fiyatı Gir ve Ekle" adımı kalır.

🛠️ ADIM 1: Veritabanı ve API Sıkılaştırması (Prisma & Express)

Satıcıların her ürüne stok girmesini zorunlu kılmak yerine, veritabanına trackStock (Stok takip edilsin mi?) boolean alanını ekliyoruz.

A. Prisma Şeması Güncellemesi

// backend/prisma/schema.prisma

model Product {
  id             String   @id @default(uuid())
  name           String
  price          Decimal  @db.Decimal(10, 2)
  // ... mevcut alanlar
  unit           String   @default("ADET")
  minQuantity    Float    @default(1.0)
  stepSize       Float    @default(1.0)
  
  // Stoksuz/Sınırsız Satış Desteği
  trackStock     Boolean  @default(false) // Varsayılan false: Stok adedi takip edilmez, hep "Stokta" kabul edilir.
  stockQuantity  Int?     @default(0)     // Sadece trackStock true ise anlamlıdır.
}


B. Backend Controller ve Validasyon Güncellemesi (ProductController.ts)

Özel ürün oluştururken veya kütüphaneden ürün kopyalarken, satıcı stok miktarı belirtmediyse trackStock: false olarak kaydedilecek ve stockQuantity zorunlu olmayacaktır.

Tüketiciye dükkan ürünleri listelenirken (getShopProducts API'si):

Ürünün stokta olup olmadığı şu formülle hesaplanır: isInStock = (trackStock === false) || (stockQuantity > 0)

📱 ADIM 2: Tüketici Uygulamasında (Consumer App) Birim Bug'ının Çözülmesi

Sorun Analizi:

Manavda patatesi "KG" ve "0.25" artış adımlı yapmana rağmen tüketici uygulamasında hala "ADET" olarak görünmesinin asıl sebebi; tüketici uygulamasındaki product.dart modelinde unit, minQuantity ve stepSize alanlarının API'den gelen JSON verisinden çözümlenirken (fromMap) unutulmuş veya varsayılan değerlere ezilmiş olmasıdır.

Çözüm Adımları (product.dart Model Onarımı):

apps/consumer_app/lib/shared/models/product.dart dosyasını açıp fromMap metodunu şu şekilde kurşun geçirmez hale getiriyoruz:

// apps/consumer_app/lib/shared/models/product.dart

class Product {
  final String id;
  final String name;
  final double price;
  final String unit;
  final double minQuantity;
  final double stepSize;
  final String? imageUrl;
  final bool trackStock;
  final int stockQuantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.unit = "ADET",
    this.minQuantity = 1.0,
    this.stepSize = 1.0,
    this.imageUrl,
    this.trackStock = false,
    this.stockQuantity = 0,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      // Backend'den Decimal/Double veya String gelebilecek fiyatı güvenli parse etme
      price: double.tryParse(map['price'].toString()) ?? 0.0,
      
      // 🚨 KRİTİK BİRİM SENKRONİZASYON ONARIMI:
      // Eğer backend'den gelen değerler null ise veritabanı varsayılanlarına düşür
      unit: map['unit'] != null ? map['unit'] as String : "ADET",
      minQuantity: map['minQuantity'] != null 
          ? double.tryParse(map['minQuantity'].toString()) ?? 1.0 
          : 1.0,
      stepSize: map['stepSize'] != null 
          ? double.tryParse(map['stepSize'].toString()) ?? 1.0 
          : 1.0,
          
      imageUrl: map['imageUrl'] as String?,
      trackStock: map['trackStock'] as bool? ?? false,
      stockQuantity: map['stockQuantity'] as int? ?? 0,
    );
  }
}


🎨 ADIM 3: Gerçek Ürün Fotoğrafları ve Seed Verisi

Envanter listelerinde satıcının ve tüketicinin gerçek stüdyo kalitesinde görseller görmesi için seed_catalog.ts scriptimizi popüler Türkçe/KKTC markalarının gerçek CDN url'leriyle besliyoruz.

Sebze/Meyve Grubu: ,  gibi Open Food Facts ve Unsplash CDN linkleri.

Atıştırmalık/İçecek Grubu: Coca-Cola 1L, Ülker Çikolatalı Gofret, Sütaş Süt 1L gibi gerçek barkodlu ve resmi beyaz arka planlı stüdyo görselleri.

📢 Doğrulama Planı

Veritabanı Güncellemesi:

cd backend && npx prisma db push && npx prisma generate


Katalog Seed:

cd backend && npx ts-node prisma/seed_catalog.ts


Statik Analiz:

cd apps/consumer_app && flutter analyze
cd apps/merchant_app && flutter analyze

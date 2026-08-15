# Story 81: Birleşik Sepet/Sipariş Opsiyon Detayı ve Modern Restoran Menü / Popüler Yönetimi

## 1. Genel Bakış ve Amaç
Bu hikaye iki temel alanı modernize eder ve standartlaştırır:
1. **Standartlaştırılmış Opsiyon ve Yan Ürün Detayı (Unified Options Breakdown):**
   - Sepet (`CartPage`), Ödeme Özeti (`PaymentPage`), Sipariş Detayı (`OrderDetailPage`), Canlı Kurye Takibi (`OrderTrackingPage`) ve Aktif Sipariş Kartı (`ActiveOrderCard`) üzerindeki tüm ürün opsiyonları (ekstralar, çıkarmalar, soslar, boyutlar) tek ve tutarlı bir UI bileşeni (`SelectedOptionsBreakdown`) üzerinden şeffaf, hesaplanmış ve modern şekilde gösterilecektir.
2. **Modern Restoran Menü Mimarisi ve Akıllı Opsiyon Tetikleme:**
   - Bir ürünün opsiyonları varsa (`optionGroups.isNotEmpty`), ürün kartındaki `+` / "Ekle" butonuna veya ürünün kendisine basıldığında ürün doğrudan sepete eklenmeyecek; zorunlu veya isteğe bağlı seçimlerin yapılabilmesi için `FoodProductCustomizationSheet` modalı açılacaktır.
   - Sadece opsiyonu olmayan düz ürünler tek tıkla sepete eklenecektir.
   - Restoran menülerinde "🔥 En Popülerler / Çok Satanlar" kategorisi ve modern yapışkan (sticky) kategori navigasyonu devreye alınacaktır.

---

## 2. Kapsam ve Yapılacak Değişiklikler

### 2.1. Ürün Kartı ve Menü Ekleme Mantığı (`ModernProductCard` & `ShopDetailPage`)
- **`ModernProductCard._handleAdd`:**
  - `businessProduct.product.optionGroups.isNotEmpty` kontrolü eklenecek.
  - Eğer opsiyon varsa `FoodProductCustomizationSheet` açılacak; kullanıcı seçimlerini tamamlayıp "Sepete Ekle" dediğinde `addToCartWithOptions` çağrılacak.
  - Eğer opsiyon yoksa `ref.read(cartProvider.notifier).addToCart(businessProduct)` doğrudan çalışacak.
- **`ShopDetailPage`:**
  - Restoran türündeki işletmelerde en başta "🔥 Popüler Lezzetler" yatay / öne çıkarılmış vitrin alanı gösterilecek.
  - Kategori çubuğu ve alt kategori filtreleri modern restoran menüsü standartlarına getirilecek.

### 2.2. Tüm Ekranlarda Birleşik Opsiyon Görünümü (`SelectedOptionsBreakdown`)
- **`OrderTrackingPage`:**
  - Alt kayar karta açılır-kapanır (accordion) "Sipariş Kalemleri" özeti eklenecek ve her ürünün opsiyonları `SelectedOptionsBreakdown` ile listelenecektir.
- **`OrderDetailPage` & `PaymentPage` & `CartPage`:**
  - `SelectedOptionsBreakdown`'ın katlanabilir veya kompakt modu ile birebir aynı renk paleti, rozet hiyerarşisi ve hesaplanmış tutar yapısı kullanılacaktır.

---

## 3. Doğrulama Protokolü
- `flutter analyze` ile Flutter istemci analizi.
- Sepete opsiyonlu ürün eklerken modal açılma doğrulaması.
- Sepet, ödeme, sipariş takibi ve sipariş detay ekranlarında opsiyonların birebir aynı tasarımla basıldığının kontrolü.

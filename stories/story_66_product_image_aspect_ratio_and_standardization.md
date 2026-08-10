# Story 66: Ürün Görseli Standartlaştırılması ve Sabit Aspect Ratio Tasarımı

## 1. Amaç ve Kapsam
Tüm Hoppa uygulamalarında (Tüketici, İşletme ve Web) ürün kartlarındaki görsellerin farklı boyut, oran ve yüksekliklerde görünmesinden kaynaklanan düzensiz arayüz görünümünü engellemek. Tüm ürün görselleri için **1:1 (Kare)** sabit aspect ratio ve İşletme görsel yükleme standartlarını (Image Upload Standards) getirmek.

## 2. Mimari ve Tasarım Değişiklikleri

### 2.1. Tüketici Uygulaması (Frontend - Consumer App)
* **`ModernProductCard` Kart Tasarımı**:
  * Ürün görsel alanı `AspectRatio(aspectRatio: 1.0)` (1:1 Kare) konteynerine alınacak.
  * `BoxFit.cover` ile görsellerin kart kenarlarını tam doldurması ve taşma yapmaması sağlanacak.
  * Görsel arka planına nötr açık gri / stüdyo tonu (`#F8F9FA`) verilecek, böylece şeffaf veya küçük görseller estetik görünecek.
  * Grid görünümünde (`shop_detail_page.dart`, `search_page.dart`, `favorites_page.dart`, `campaign_products_page.dart`) `childAspectRatio` değerleri 1:1 görsel oranına ve sabit kart yüksekliğine göre optimize edilecek (Örn: 2 sütunlu grid için `0.70`).

### 2.2. İşletme Portalı ve Ürün Yükleme Standartları (Merchant App & Backend)
* **İşletme Görsel Yükleme Kılavuzu & Arayüzü**:
  * `merchant_product_list_page.dart` içerisinde özel ürün ekleme/düzenleme formuna görsel standart bilgisi ve 1:1 kırpma/önizleme rehberi eklenecek ("Standart Ürün Görseli: 1:1 Kare Format, Min 800x800 px").
* **Backend Katalog & Otomatik Resim Scripti (`update_catalog_real_images.ts`)**:
  * Cloudflare R2'ye yüklenecek veya dış kaynaklardan çekilecek tüm görseller için 1:1 kare oran hedefi koyularak stüdyo görseli ve R2 depolama standart hale getirilecek.

## 3. Test ve Doğrulama
* `flutter analyze` statik analizi.
* Tüketici uygulamasında dükkan detay, arama ve favoriler sayfalarında 2 sütunlu grid ürün kartlarının eşit yükseklikte ve hizada olduğunun doğrulanması.

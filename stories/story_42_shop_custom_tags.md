# Story #42: Shop Custom Tags & Badges (Özel Dükkan Etiketleri ve Sadeleştirme)

## Teknik Tasarım ve Kapsam

Bu hikaye, tüketicilere gösterilen dükkan kartlarındaki etiket kalabalığını sadeleştirmeyi ve kalan kritik etiketler ("Hızlı Teslimat", "Hoppa Kuryesi", "Gel-Al", "Yeni", "Müşteri Favorisi") için grafik tasarımcımızın istediği özel modern figürler (ikonlar, uyumlu renk paletleri) ile premium bir görsel gösterim sağlamayı hedefler.

### 1. Backend Değişiklikleri (`ConsumerShopController.ts`)
* **Dinamik Etiketlerin Sadeleştirilmesi:**
  * `enrichShopWithTags` fonksiyonundaki "Kaliteli Hizmet", "Efsane Lezzet", "Taze Ürünler" gibi gereksiz etiketleri kaldıracağız.
  * Sadece şu dinamik etiketleri hesaplayıp döneceğiz:
    * **Yeni:** Dükkanın `createdAt` tarihi son 30 gün içerisindeyse eklenecek.
    * **Hızlı Teslimat:** Dükkanın `avgSpeedRating >= 4.5` ise eklenecek.
    * **Müşteri Favorisi:** Dükkanın genel puanı `averageRating >= 4.7` ise eklenecek.

### 2. Frontend Geliştirmeleri (`consumer_app`)
* **Yeni Ortak Widget (`ShopBadge`):**
  * `apps/consumer_app/lib/apps/consumer/widgets/shop_badge.dart` altında yeni bir yeniden kullanılabilir widget oluşturulacak.
  * Desteklenen etiket tipleri ve görsel nitelikleri:
    * **Hoppa Kuryesi (PLATFORM_DELIVERY):**
      * İkon: `Icons.motorcycle_rounded` veya `Icons.delivery_dining_rounded`
      * Renk: Hoppa Yeşili (`Color(0xFF00A651)`)
    * **Gel-Al (PICKUP):**
      * İkon: `Icons.shopping_bag_outlined` veya `Icons.storefront_outlined`
      * Renk: Mor/Eflatun (`Colors.purple`)
    * **Esnaf Teslimatı (SELF_DELIVERY):**
      * İkon: `Icons.local_shipping_outlined`
      * Renk: Turuncu (`Colors.orange`)
    * **Hızlı Teslimat:**
      * İkon: `Icons.flash_on_rounded` (Şimşek)
      * Renk: Kehribar/Sarı (`Colors.amber.shade800`)
    * **Müşteri Favorisi:**
      * İkon: `Icons.favorite_rounded` (Kalp)
      * Renk: Kırmızı/Mercan (`Colors.redAccent`)
    * **Yeni:**
      * İkon: `Icons.auto_awesome_rounded` (Yıldızlar/Sparkle)
      * Renk: Turkuaz/Mavi (`Colors.cyan.shade700`)
  * Tasarım Detayları:
    * Arka plan hafif transparan ton (opasite `0.08` veya `0.1`).
    * İnce kenarlık (`Border.all` ile rengin `0.2` opasiteli versiyonu).
    * İkon ile metin arasında `4dp` boşluk.
    * Modern kıvrımlı köşeler (`BorderRadius.circular(6)`).

* **Entegrasyon Alanları:**
  * **`business_selection_page.dart` (Mağaza Listesi):**
    * Mevcut el yordamıyla oluşturulmuş `Container` yapıları `ShopBadge` widget'ı ile değiştirilecek.
    * Hem teslimat modelleri (`allowedFulfillmentModels`) hem de dinamik etiketler (`tags`) bu yeni widget ile gösterilecek.
  * **`shop_detail_page.dart` (Mağaza Detay Sayfası Header'ı):**
    * Mağaza detay sayfasındaki teslimat modeli rozetleri de `ShopBadge` widget'ı ile görsel uyuma kavuşturulacak.

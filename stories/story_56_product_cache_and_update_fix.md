# Story 56: İşletme Ürün Güncelleme ve Tüketici Uygulaması Önbellek Sorunu

## 1. Analiz ve Bulgular

### 1.1. Problem
İşletme uygulamasında (`merchant_app`) ürün resim ve marka bilgileri güncellenip başarıyla kaydedilmesine rağmen, Tüketici uygulamasında (`consumer_app`) bu güncellemeler anında yansımamakta ve eski resim/marka bilgileri görüntülenmeye devam etmektedir.

### 1.2. Bulgular ve Nedenleri
1. **Veritabanı Seviyesinde Başarı:**
   * Yapılan kontrollerde, satıcının yüklediği özel ürün resmi URL'si (`imageUrl`) ve marka adı (`brand`) veritabanında (PostgreSQL) başarıyla güncellenmekte ve saklanmaktadır.
2. **Tüketici Uygulaması Caching (Önbellek) Sorunu:**
   * Tüketici uygulamasında dükkan ürünleri, kategorileri ve kategori ağacı Riverpod sağlayıcıları (`shopProductsProvider`, `shopCategoriesProvider`, `shopCategoryTreeProvider`) aracılığıyla REST API'den (`/api/consumer/shops/$shopId/products`) çekilmektedir.
   * Bu sağlayıcılar `FutureProvider.family` olarak tanımlanmıştır ve varsayılan olarak `.autoDispose` niteliğine sahip değillerdir.
   * Bu durum, kullanıcı uygulamada bir dükkanın detay sayfasına girdiğinde ürünlerin belleğe süresiz olarak kaydedilmesine yol açar. Kullanıcı dükkandan çıkıp tekrar girdiğinde veya ana sayfayı yenilediğinde dükkan ürün sağlayıcıları tekrar tetiklenmez, doğrudan önbellekten eski veriler okunur.

## 2. Çözüm Önerisi

### 2.1. Riverpod Sağlayıcılarının autoDispose Yapılması
`consumer_shop_repository.dart` dosyasındaki dükkan bazlı veri çeken sağlayıcıları `.autoDispose` olarak güncelleyeceğiz. Böylece kullanıcı dükkan detay ekranından çıktığında bu dükkana ait ürün ve kategori listeleri bellekten temizlenecek, dükkana tekrar girildiğinde güncel veriler sunucudan çekilecektir.

*   `shopProductsProvider` -> `FutureProvider.autoDispose.family`
*   `shopCategoriesProvider` -> `FutureProvider.autoDispose.family`
*   `shopCategoryTreeProvider` -> `FutureProvider.autoDispose.family`
*   `filteredShopProductsProvider` -> `Provider.autoDispose.family`

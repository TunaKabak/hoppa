# Story 55: İşletme Logo ve Kapak Resimlerinin Senkronizasyon Sorunu

## 1. Analiz ve Bulgular

### 1.1. Problem
İşletme uygulamasında (`merchant_app`) dükkan ayarlarından logo ve kapak resmi güncellenip başarıyla kaydedilmesine rağmen, Tüketici uygulamasında (`consumer_app`) bu resimler güncellenmemektedir.

### 1.2. Nedenler ve Bulgular
1. **Firestore ve PostgreSQL Tutarsızlığı (Senkronizasyon Eksikliği):**
   * Hoppa projesinde dükkan bilgileri hem PostgreSQL (REST API `/api/merchant/shop`) hem de Firebase Firestore (`businesses` koleksiyonu) üzerinde tutulmaktadır.
   * `merchant_settings_page.dart` dosyasında ayarlar kaydedilirken sadece PostgreSQL veritabanını güncelleyen REST API (`updateShop`) çağrılmakta, Firestore'daki `businesses` belgesi ise **güncellenmemektedir**.
   * Consumer uygulamasındaki Sipariş Detay ekranı (`order_detail_page.dart`), Kurye modülleri ve Merchant uygulamasındaki bazı dashboard ekranları dükkan bilgilerini Firestore'dan (`BusinessService.getBusinessById`) çekmektedir. Firestore güncellenmediği için bu ekranlarda eski resimler kalmaktadır.

2. **Consumer App Caching ve Lifecycle Yenileme Eksikliği:**
   * Tüketici uygulamasındaki ana sayfa dükkan listesi (`consumerShopsProvider` -> `/api/consumer/shops` REST API) üzerinden PostgreSQL'den beslenmektedir.
   * Ancak kullanıcı dükkan detay sayfasındayken (`shop_detail_page.dart`) dükkan nesnesi (`widget.shop`) doğrudan ana sayfadaki listeden parametre olarak geçirilmekte ve detay sayfası açıkken resimlerin arka planda güncellenmesini tetikleyecek bir yenileme (refresh) mekanizması bulunmamaktadır.

## 2. Çözüm Önerisi

### 2.1. Merchant Uygulamasında Firestore Senkronizasyonunun Sağlanması
`merchant_settings_page.dart` dosyasındaki `_saveSettings` metodunda, REST API güncellemesi başarılı olduktan sonra Firestore'daki `businesses` belgesini de `BusinessService` aracılığıyla güncelleyeceğiz:
```dart
// Dükkan ayarları başarıyla PostgreSQL'e kaydedildikten sonra:
final BusinessService businessService = BusinessService();
await businessService.updateBusiness(_shop!.id, {
  'name': _nameController.text,
  'address': combinedAddress,
  'phone': _phoneController.text,
  'logoUrl': _imageUrl ?? '',
  'headerImageUrl': _headerImageUrl ?? '',
  'minBasketAmount': double.tryParse(_minBasketController.text) ?? 0.0,
  'deliveryRadius': _deliveryRadius,
  'latitude': _latitude ?? 0.0,
  'longitude': _longitude ?? 0.0,
  'campaignText': _campaignController.text.trim(),
});
```

### 2.2. Consumer Uygulamasında Dükkan Detay Sayfasında Yenileme Desteği
`shop_detail_page.dart` sayfasına dükkan bilgilerini API'den veya Firestore'dan tazelemek için bir yenileme (refresh) veya sayfa açıldığında dükkan detayını arka planda güncelleme mantığı eklenmesi düşünülebilir. Ancak ana sayfadaki pull-to-refresh (`consumerShopsProvider` invalidation) zaten çalışmaktadır. Firestore senkronizasyonu sağlandığında sipariş detayları ve diğer Firestore bağımlı ekranlardaki resimler de başarıyla güncellenecektir.

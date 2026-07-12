# Story #41: Shop Fulfillment Models (Teslimat Seçenekleri Entegrasyonu)

## Teknik Tasarım ve Kapsam

Bu hikaye, dükkanların sunduğu teslimat hizmet modellerini (Hoppa Kuryesi, İşletme Kuryesi, Gel-Al) esnek bir şekilde yönetebilmesini ve tüketicilerin sepet/ödeme ekranlarında bu modellere uygun seçimler yapabilmesini kapsar.

### 1. Veritabanı Değişiklikleri (`schema.prisma`)
* **Yeni Enum:** `FulfillmentModel`
  - `PLATFORM_DELIVERY`: Hoppa Kuryesi tarafından teslimat.
  - `SELF_DELIVERY`: İşletme (esnaf) kuryesi tarafından teslimat.
  - `PICKUP`: Gel-Al (tüketicinin kendisi alması).
* **`Shop` Tablosuna Yeni Alan:**
  - `allowedFulfillmentModels FulfillmentModel[] @default([PLATFORM_DELIVERY, PICKUP])`

### 2. Backend Geliştirmeleri
* **`ShopController.ts`:**
  - `updateMyShop` metoduna `allowedFulfillmentModels` validasyonu ve veritabanı kaydı eklenecek.
* **Sipariş Doğrulama Mantığı:**
  - Sipariş oluşturulurken (`createOrder` veya ilgili sepet endpoint'i), seçilen teslimat tipinin dükkanın izin verdiği `allowedFulfillmentModels` içinde olduğu kontrol edilecek.

### 3. Esnaf Uygulaması (`merchant_app`) Geliştirmeleri
* **`merchant_settings_page.dart`:**
  - Dükkan ayarlarında teslimat modellerinin açılıp kapatılabileceği Switch/Checkbox alanları eklenecek.
  - API'ye `allowedFulfillmentModels` parametresi gönderilecek.

### 4. Tüketici Uygulaması (`consumer_app`) Geliştirmeleri
* **`business_selection_page.dart` ve `shop_detail_page.dart`:**
  - Dükkanın hangi teslimat modelini sunduğu bilgisini gösteren rozetler/bilgilendirmeler.
* **Checkout / Sepet Süreci:**
  - Kullanıcıya teslimat seçeneği (Adrese Teslimat vs Gel-Al) sunulurken, dükkanın ayarları doğrultusunda seçenekler dinamik kısıtlanacak.

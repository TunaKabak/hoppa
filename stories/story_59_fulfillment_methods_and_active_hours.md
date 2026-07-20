# Story #59: Checkout and Shop Opening Hours Optimization

## Teknik Tasarım ve Kapsam

Bu hikaye, adrese teslimat seçeneğiyle çalışan işletmelerden sipariş verilirken yaşanan ödeme adımına geçememe sorununu çözmeyi ve dükkanların çalışma saatlerine (workingHours) göre otomatik olarak "Kapalı" durumuna gelmesini sağlamayı kapsar.

### 1. Tüketici Uygulaması (`consumer_app`) Geliştirmeleri
* **`delivery_provider.dart`:**
  - `updateUserId` fonksiyonu güncellenecek. Misafir kullanıcı giriş yaptığında, yeni kullanıcının SharedPreferences'ta kayıtlı bir adresi yoksa, hafızadaki mevcut misafir adresi (guest address) silinmeyip geçici olarak korunacak.
  - Bu sayede giriş sonrası tetiklenen adres taşıma (migration) işlemi misafir adresini başarıyla veritabanına kaydedebilecek ve yeni kullanıcının seçili adresi olarak belirleyebilecek.
  - Ödeme ekranındaki adres değiştirme kısıtlaması korunacak (çünkü sepet ve en yakın işletme mantığı seçili adrese bağlıdır). Giriş sonrası adresin null kalması engellendiği için kullanıcı artık ödeme adımından atılmayacaktır.
* **`consumer_shop_repository.dart`:**
  - API'den gelen dükkan listelerinde `isOpen` alanını sadece static `isActive` boolean değerine göre değil, API'den dönecek hesaplanmış dinamik `isOpen` alanına göre okuyacak:
    `map['isOpen'] = json['isOpen'] ?? json['isActive'] ?? true;`

### 2. Backend Geliştirmeleri (`backend`)
* **`ConsumerShopController.ts` ve `OrderController.ts`:**
  - Dükkanın çalışma saatlerini kontrol ederken, dükkanın bağlı olduğu satıcının (merchant) `countryCode` bilgisine göre timezone belirlenecek:
    - `countryCode === "CY" || countryCode === "KKTC"` ise `Europe/Nicosia` (Kıbrıs yerel saati, yaz/kış saatine göre otomatik UTC+3 / UTC+2 arasında değişir).
    - Diğer durumlar için `Europe/Istanbul` (Türkiye yerel saati, daima UTC+3).
  - Saat hesaplaması sunucu saatinden bağımsız olarak UTC bazlı başlayıp, `toLocaleString("en-US", { timeZone: tz })` ile ilgili dükkanın dinamik yerel zamanına dönüştürülecektir. Bu sayede yaz saati geçişleri (DST) Node.js'in dahili zaman veri tabanı tarafından otomatik yönetilecektir.
  - Hesaplanan bu değer `isOpen` alanı olarak response objesine eklenecek.
  - Böylece tüketici uygulamasında dükkanlar aktif saatlerine göre otomatik olarak kapalı gözükecek.

## Doğrulama Protokolü
* Değişikliklerden sonra mobil ve backend tarafındaki derleme doğrulamaları yapılacak.
* `flutter analyze` ile consumer_app statik analiz kontrolü gerçekleştirilecek.
* `npx tsc --noEmit` ile backend tip doğrulaması yapılacak.

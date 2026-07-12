# Story 40: Tüketici Deneyimi İyileştirmeleri, Kupon Sistemi ve Kayıtlı Kartlar

Bu hikaye, Hoppa tüketici uygulamasındaki geniş kapsamlı UX iyileştirmelerini, detaylı değerlendirme sistemini, sistem/işletme kupon mimarisini, kayıtlı kartları, dil seçimini ve otomatik konum altyapısını belgeler.

---

## 1. Veritabanı ve Şema Değişiklikleri (`backend/prisma/schema.prisma`)

Değerlendirmeler, kuponlar, bildirim tercihleri ve kayıtlı kartlar için veritabanı modelleri aşağıdaki gibi güncellenecektir:

### 1.1. `User` Modeline Yeni Alanlar
```prisma
model User {
  // ... (mevcut alanlar)
  // Bildirim Ayarları Tercihleri
  notifyOrderStatus Boolean @default(true)
  notifyCampaigns   Boolean @default(true)
  notifyNews        Boolean @default(true)

  // İlişkiler
  savedCards        SavedCard[]
  couponUsages      CouponUsage[]
}
```

### 1.2. `Review` ve `Shop` Modeli Güncellemeleri
Detaylı geri bildirim ve dinamik etiketleme için alt puanlar eklenecektir.
```prisma
model Review {
  // ... (mevcut alanlar)
  serviceRating Int?     // Servis/Paketleme puanı (1-5)
  speedRating   Int?     // Hız puanı (1-5)
  tasteRating   Int?     // Lezzet/Kalite puanı (1-5)
}

model Shop {
  // ... (mevcut alanlar)
  avgServiceRating Float @default(5.0)
  avgSpeedRating   Float @default(5.0)
  avgTasteRating   Float @default(5.0)
}
```

### 1.3. `SavedCard` Modeli (Kayıtlı Kartlarım)
```prisma
model SavedCard {
  id               String   @id @default(uuid())
  userId           String
  user             User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  cardTitle        String   // Örn: "Maaş Kartım", "Bonus"
  cardHolderName   String
  cardNumberHidden String   // Örn: "4355 24** **** 4321"
  cardToken        String   // Ödeme sağlayıcısından dönen token
  cardType         String   // Visa, Mastercard, Troy vb.
  
  createdAt        DateTime @default(now())
  updatedAt        DateTime @updatedAt

  @@index([userId])
}
```

### 1.4. `Coupon`, `CouponShop` ve `CouponUsage` Modelleri (Kupon/Kampanya Sistemi)
```prisma
model Coupon {
  id                String       @id @default(uuid())
  code              String       @unique // Örn: "HOPPA100", "WELCOME50"
  title             String
  description       String?
  discountType      String       // "PERCENTAGE" veya "FIXED"
  discountValue     Float
  minOrderAmount    Float        @default(0.0)
  maxDiscountAmount Float?
  startDate         DateTime
  endDate           DateTime
  isActive          Boolean      @default(true)
  isSystemCoupon    Boolean      @default(true) // true ise Hoppa, false ise dükkan kuponu
  creatorShopId     String?      // Dükkan özelindeyse dükkan ID'si

  allowedShops      CouponShop[]
  usages            CouponUsage[]
  
  createdAt         DateTime     @default(now())
  updatedAt         DateTime     @updatedAt
}

model CouponShop {
  id       String @id @default(uuid())
  couponId String
  coupon   Coupon @relation(fields: [couponId], references: [id], onDelete: Cascade)
  shopId   String
  shop     Shop   @relation(fields: [shopId], references: [id], onDelete: Cascade)

  @@unique([couponId, shopId])
  @@index([couponId])
  @@index([shopId])
}

model CouponUsage {
  id       String   @id @default(uuid())
  couponId String
  coupon   Coupon   @relation(fields: [couponId], references: [id], onDelete: Cascade)
  userId   String
  user     User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  orderId  String   @unique
  order    Order    @relation(fields: [orderId], references: [id], onDelete: Cascade)
  usedAt   DateTime @default(now())

  @@index([couponId])
  @@index([userId])
}
```

---

## 2. API Uç Noktaları ve Backend Değişiklikleri

### 2.1. Değerlendirme ve Etiket Mantığı (`ReviewController.ts` & `ConsumerShopController.ts`)
* `ReviewController.createReview` güncellenecek: `serviceRating`, `speedRating`, `tasteRating` parametreleri alınacak. `Shop` modelindeki `avgServiceRating`, `avgSpeedRating`, `avgTasteRating` değerleri transaction ile güncellenecektir.
* Dükkan listeleme veya dükkan detayı döndürülürken dinamik etiket hesaplaması:
  * **Hızlı Teslimat**: `avgSpeedRating >= 4.5` ve `reviewCount >= 1`
  * **Kaliteli Hizmet**: `avgServiceRating >= 4.5` ve `reviewCount >= 1`
  * **Efsane Lezzet**: `avgTasteRating >= 4.5` ve `reviewCount >= 1` (Restoran için)
  * **Taze Ürünler**: `avgTasteRating >= 4.5` ve `reviewCount >= 1` (Market/Manav için)
  * **Müşteri Favorisi**: `averageRating >= 4.7` ve `reviewCount >= 1`
* Yeni API: `GET /api/consumer/reviews/my` (Tüketicinin kendi yorumlarını listelemesi için).

### 2.2. Profil ve Bildirim Ayarları (`ProfileController.ts`)
* `GET /api/consumer/profile` (Profil, bildirim ayarları, vb.)
* `PUT /api/consumer/profile` (İsim, soyisim ve bildirim tercihleri güncellenmesi)

### 2.3. Kayıtlı Kartlar (`SavedCardController.ts`)
* `GET /api/consumer/cards` (Kayıtlı kartları getirir)
* `POST /api/consumer/cards` (Yeni kart kaydeder - Mock token ile)
* `DELETE /api/consumer/cards/:id` (Kart kaydını siler)

### 2.4. Kupon Sistemi (`CouponController.ts`)
* `GET /api/consumer/coupons` (Kullanıcının kullanabileceği kupon listesi)
* `POST /api/consumer/coupons/apply` (Sepete kupon uygular ve indirim tutarını doğrular)
* Hoşgeldin Kampanyası: verifyOtp aşamasında yeni bir kullanıcı oluşturulursa, otomatik olarak veritabanına "WELCOME50" (Yeni üyelere özel 50 TL kupon) kupon kaydı/kullanım hakkı tanımlanacaktır.

---

## 3. Flutter (Tüketici Uygulaması) Mimari Planı

### 3.1. Giriş ve OTP Akışı (`consumer_otp_verify_page.dart` & `consumer_login_page.dart`)
* "Üye olmadan devam et" butonu `Navigator.pop(context)` ile çalışacak.
* OTP doğrulandıktan sonra, eğer kullanıcı yeni ise (API'den dönen flag veya name/surname boş ise), kullanıcı direkt anasayfaya yönlendirilmeyecek.
* Bunun yerine `NameSurnameInputPage` isimli yeni bir ekrana yönlendirilecek. Bu ekrandan isim ve soyisim alındıktan sonra `PUT /api/consumer/profile` API'si çağrılacak ve ardından anasayfaya geçilecek.
* Misafir iken seçilmiş/girilmiş bir adres varsa (local guest address), login tamamlandıktan hemen sonra bu adres otomatik olarak backend API `POST /api/consumer/addresses` çağrılarak kullanıcının profiline kaydedilecektir.

### 3.2. Dil Seçimi (`language_selection_page.dart`)
* Profil ekranındaki dil seçimi satırı, ayrı bir `LanguageSelectionPage` sayfasına yönlendirecek.
* Bu sayfada Türkçe ve İngilizce dilleri radyo butonları veya şık kartlar ile listelenecek, seçilip kaydedilebilecektir.

### 3.3. Modern Hesabım Ekranı (`profile_page.dart`)
* Başlık kısmı soft yeşil-turuncu geçişli modern bir gradient kartına dönüştürülecek.
* Kullanıcı adı, soyadı ve telefon numarası şık tipografiyle gösterilecek.
* Menü elemanları gruplanacak (Hesabım, İşlemler, Ayarlar vb.) ve ince gölgeli beyaz modern kartlar içine yerleştirilecek.
* Menüye "Değerlendirmelerim", "Kayıtlı Kartlarım", "Kuponlarım" ve "Bildirim Ayarları" eklenecektir.

### 3.4. Siparişlerim Ekranı (`order_history_page.dart`)
* Son 3 ay filtresi varsayılan olarak uygulanacak.
* Ekranın üst kısmına filtre çipi satırı eklenecek: "Son 3 Ay", "Son 6 Ay", "Son 1 Yıl", "Tümü", "Özel Tarih".
* "Özel Tarih" seçildiğinde `showDateRangePicker` açılacak.
* Sipariş yoksa, "Alışverişe Başla" butonu çıkacak ve tıklandığında anasayfaya (kategori seçimine) yönlendirecektir.

### 3.5. Bildirim Ayarları Ekranı (`notification_settings_page.dart`)
* Detaylandırılmış seçenekler:
  * Sipariş Durum Bildirimleri (Anlık sipariş güncellemeleri)
  * Kampanyalar ve Fırsatlar (Kuponlar ve indirimler)
  * Duyurular ve Güncellemeler (Yenilikler ve haberler)
* Switch list tile'lar ile kullanıcı ayarları açıp kapatabilecek, değişiklikler anında veya kaydet butonuyla `PUT /api/consumer/profile` ile senkronize edilecektir.

### 3.6. Otomatik Konum İzni ve Yakındaki İşletmeler
* Uygulama açılışında (`MainLayoutPage` startup / `initState`), `DeliveryProvider.selectedAddress` boş ise konum izni istenecek ve konum bilgisi otomatik alınıp `DeliveryProvider`'a geçici adres olarak setlenecektir.
* Dükkan listesi, bu konum koordinatlarına göre en yakından en uzağa doğru sıralanacaktır.

### 3.7. Harita Görünümü Değiştirme
* `AddAddressPage` harita alanına katman değiştirme butonu (Standard, Uydu, Karanlık) eklenecek, kullanıcı tıkladığında `TileLayer`'ın `urlTemplate` parametresi güncellenecektir.

# Story 47: Major Consumer Updates (Curve Headers, 4 Categories, Sticky Cart, Wallet, Referral & Share)

Bu hikaye, Hoppa tüketici uygulamasında gerçekleştirilecek büyük tasarım iyileştirmelerini, kategori sadeleştirmesini, cüzdan ve davet/yorum ödüllendirme sistemlerini kapsar.

---

## 1. Teknik Tasarım ve Analiz

### 1.1. İstek 1: Curve Turuncu Header Yapısının Yaygınlaştırılması
* **Mevcut Durum:** Curve turuncu header (`HoppaHeader` widget'ı ve degrade arka planlı Container) sadece `SelectionCategoryPage` (Ana Kategori Ekranı) üzerinde mevcut. `SearchPage`, `CartPage` ve `ProfilePage` gibi ana ekranlarda standart beyaz `AppBar` kullanılıyor.
* **Tasarım Kararı:** 
  * `HoppaHeader` yapısı `SearchPage`, `CartPage` ve `ProfilePage` ekranlarında da kullanılacak.
  * Header'ın altında kalan içerik alanı, ana ekrandaki gibi oval köşeli beyaz bir Container (`BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))`) içinde gösterilecek.
  * Bu sayede uygulama genelinde tutarlı ve premium bir tasarım dili oluşturulacak.

### 1.2. İstek 2: Ana İşletme Kategorilerinin Sadeleştirilmesi (4 Kategori)
* **Mevcut Durum:** Veritabanında 8 farklı kategori (Market, Restoran, Su, Kuruyemiş, Kahve, Çiçek, Manav, Kasap) bulunuyor.
* **Tasarım Kararı:**
  * Ana işletme kategorileri sadece **4 kategoriye** indirilecek:
    1. **Market:** Renk kodu daha canlı yeşil tonuna güncellenecek (`#00B359`).
    2. **Yemek:** Eski "Restoran" kategorisinin adı "Yemek" olarak değiştirilecek ve rengi kırmızıya yakın bir tona güncellenecek (`#E53935`).
    3. **Su:** Renk tonu daha canlı maviye güncellenecek (`#0288D1`).
    4. **Çiçek:** Renk tonu daha canlı pembeye güncellenecek (`#EC407A`).
  * Diğer kategoriler (Kuruyemiş, Kahve, Manav, Kasap) veritabanında `isActive: false` yapılacak veya tohumlama dosyasından kaldırılarak gizlenecek.
  * Mobil uygulamadaki category grid elemanları (`selection_category_page.dart` ve `business_type.dart`) bu 4 kategoriye göre güncellenecek. "Restoran" -> "Yemek" kelime eşleştirmeleri tamamlanacak.

### 1.3. İstek 3: Sticky Cart (Yapışkan Sepet) Kısayolu
* **Mevcut Durum:** Kullanıcı ana kategori ekranına (`SelectionCategoryPage`) döndüğünde alt menü çubuğu gizleniyor. Sepete eklenmiş bir ürün olduğunda sepeti görme veya doğrudan gitme kısayolu bulunmuyor.
* **Tasarım Kararı:**
  * `SelectionCategoryPage` ekranında eğer sepette en az 1 ürün varsa, ekranın alt kısmına şık ve animasyonlu bir **Floating Cart Bar** yerleştirilecek.
  * Bar içeriği: Sol tarafta sepet ikonu, ürün adedi ("X Ürün") ve toplam tutar ("X TL"). Sağ tarafta ise "Sepete Git" butonu bulunacak.
  * Tıklandığında kullanıcıyı `NavigationProvider` aracılığıyla Sepetim sekmesine (Index: 2) yönlendirecek.

### 1.4. İstek 4: Tek Renk Profil İkonları
* **Mevcut Durum:** `ProfilePage` menüsündeki ikonlar farklı renklerden (mavi, kırmızı, sarı vb.) oluşuyor.
* **Tasarım Kararı:**
  * Profil menüsündeki tüm ikonlar Hoppa'nın kurumsal kimliğine uygun olarak tek renk (Hoppa Turuncusu: `#E95D22` veya Hoppa Yeşili: `#00A651`) yapılacak.
  * İkonların arka planındaki dairesel alanlar da bu ana rengin düşük opasiteli hali (`opacity: 0.12`) ile kaplanacak.

### 1.5. İstek 5 & 8: Cüzdan (Wallet) ve Yorum Ödülleri (Hoppa Para)
* **Cüzdan Yapısı:**
  * Kullanıcıların cüzdanında bakiye (kendi yükledikleri) ve "Hoppa Para" (kazanılan ödüller) tutulacak.
  * Sipariş oluştururken "Cüzdan ile Ödeme" seçeneği eklenecek.
  * Yorum yapıldığında kazanılan Hoppa Paralar cüzdan bakiyesine eklenecek ve 30 günlük kullanım süresi olacak.
* **Veritabanı Şeması (Prisma):**
  * `Wallet` ve `WalletTransaction` modelleri tanımlanacak.
  * `WalletTransactionType` enum'una `DEPOSIT`, `WITHDRAW`, `REFUND`, `REFERRAL_BONUS`, `REVIEW_BONUS` eklenecek.
* **Yorum Ödüllendirme Akışı:**
  * Sipariş teslim edildikten sonra kullanıcı yorum yaptığında backend, yorumun doğruluğunu kontrol edip cüzdana dinamik ödül tutarında (örneğin 15 TL) Hoppa Para aktaracak. Bu işlemin log kaydı `WalletTransaction`'da tutulacak.

### 1.6. İstek 6 & 7: Davet Et Kazan ve Paylaşım Özelliği
* **Davet Et Kazan:**
  * Kullanıcının profilinde "Davet Et Kazan" menüsü yer alacak. Buradan kullanıcıya özel bir davet linki (örn: `https://hoppa.delivery/invite?code=ABC123XY`) paylaşılabilecek.
  * Bu link üzerinden üye olan kişiler ilk alışverişini yaptığında (veya doğrudan üye olduğunda) hem davet eden hem de davet edilen kupon kazanacak.
  * Ödül kuponunun kuralları: Minimum 250 TL alışverişte geçerli, 1 hafta (7 gün) süreli.
* **İşletme/Ürün Paylaş:**
  * İşletme detay (`ModernShopDetailPage`) ve Ürün detay (`ProductDetailPage`) sayfalarına "Paylaş" butonu yerleştirilerek yerel paylaşım (share_plus paketi) tetiklenecek.

---

## 2. Veritabanı Değişiklikleri (Prisma Schema)

```prisma
// schema.prisma güncellemesi

model User {
  // ... mevcut alanlar ...
  referralCode String?   @unique
  referredById String?
  referredBy   User?     @relation("ReferralRelation", fields: [referredById], references: [id])
  referrals    User[]    @relation("ReferralRelation")
  wallet       Wallet?
}

model Wallet {
  id        String              @id @default(uuid())
  userId    String              @unique
  user      User                @relation(fields: [userId], references: [id], onDelete: Cascade)
  balance   Decimal             @db.Decimal(10, 2) @default(0.00)
  createdAt DateTime            @default(now())
  updatedAt DateTime            @updatedAt
  transactions WalletTransaction[]
}

enum WalletTransactionType {
  DEPOSIT
  WITHDRAW
  REFUND
  REFERRAL_BONUS
  REVIEW_BONUS
}

model WalletTransaction {
  id          String                @id @default(uuid())
  walletId    String
  wallet      Wallet                @relation(fields: [walletId], references: [id], onDelete: Cascade)
  amount      Decimal               @db.Decimal(10, 2)
  type        WalletTransactionType
  description String?
  expiresAt   DateTime?             // Hoppa Para için geçerlilik süresi
  createdAt   DateTime              @default(now())

  @@index([walletId])
}

model Referral {
  id               String   @id @default(uuid())
  referrerId       String
  referredId       String   @unique
  couponId         String?  // Davet edene verilen kupon
  referredCouponId String?  // Davet edilene verilen kupon
  createdAt        DateTime @default(now())
}
```

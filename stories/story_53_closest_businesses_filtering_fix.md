# Story 53: Closest Businesses Filtering and Seeding Bug Fix

## 1. Analiz ve Bulgular

### 1.1. Veritabanı İncelemesi (Shop Tablosu)
Veritabanındaki `Shop` kayıtları incelendiğinde, `"Market"` türündeki bazı işletmelerin adlarının (`name`) veritabanında yanlış olduğu tespit edilmiştir:
* **Yeniboğaziçi Koop Market** (ID: `0fcb3301-3ccf-477d-b26d-26aa4435fc67`, E-posta: `bogazicimarket@test.com`) -> Adı veritabanında **"Mağusa Kebap Dünyası"** olarak görünmektedir.
* **Mağusa Merkez Süpermarket** (ID: `2d50df56-a38f-4ec0-834f-f51edfe54b15`, E-posta: `magusasupermarket@test.com`) -> Adı veritabanında **"Mağusa Kebap Dünyası"** olarak görünmektedir.

### 1.2. Seeding (Tohumlama) Hatası (`seed.ts`)
Bu isimlendirme hatasının kaynağı `backend/prisma/seed.ts` dosyasıdır:
* `prisma.shop.upsert` fonksiyonunun `update` bloğunda `name` ve `description` alanları güncellenmemektedir.
* DB seeding tekrar çalıştırıldığında veya kayıtlar güncellendiğinde, dükkan isimleri daha önce oluşturulmuş olan ilk dükkanın adı ("Mağusa Kebap Dünyası") olarak kalmıştır.

### 1.3. İstemci Tarafı Filtreleme Hatası (`business_selection_page.dart`)
Tüketici uygulamasında (`consumer_app`) `"Market"` kategorisinde alt kategori filtreleri (Market, Kasap, Manav vb.) uygulandığında:
```dart
if (subLower == 'market') {
  return b.type.name == 'market' && 
      (nameLower.contains('market') || nameLower.contains('süpermarket') || nameLower.contains('bakkal') || nameLower.contains('koop'));
}
```
* Yeniboğaziçi Koop Market'in adı `"Mağusa Kebap Dünyası"` olduğu için bu filtreyi geçememekte ve listeden tamamen kaybolmaktadır.
* Kullanıcı dükkanın adını `"Yeniboğaziçi Koop Market"` olarak aradığında da dükkan adı yanlış olduğu için arama sonuçlarında çıkmamaktadır.

## 2. Çözüm Önerisi

1. **`seed.ts` Güncellemesi:**
   `backend/prisma/seed.ts` dosyasındaki `seedShopWithProducts` fonksiyonundaki `prisma.shop.upsert` çağrısının `update` bloğuna `name` ve `description` alanları eklenecektir.

2. **Veritabanının Yeniden Tohumlanması:**
   `npx prisma db seed` komutu çalıştırılarak veritabanındaki dükkan isimleri ve tanımları düzeltilecektir.

3. **Doğrulama:**
   Veritabanı kontrol edilerek dükkan isimlerinin doğru şekilde güncellendiği teyit edilecektir.

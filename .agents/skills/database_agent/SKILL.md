---
name: database_agent
description: Database Agent is triggered when modifying databases, Prisma schemas (schema.prisma), seed files (seed.ts), migrations, or Firestore rules.
---

# 🗄️ Database Agent Yeteneği (SKILL.md)

Sen Hoppa projesinin kıdemli **Veritabanı ve Altyapı Mimarı** temsilcisisin. Prisma şemaları, PostgreSQL ilişkileri, Firestore JSON yapıları ve veritabanı tohumlama (seeding) süreçlerinde aşağıdaki kurallara göre hareket etmelisin.

## 1. Mimari Standartlar

### 1.1. Prisma Şema Değişiklikleri
* `backend/prisma/schema.prisma` üzerinde alan eklerken/çıkarırken mevcut verilerin kaybolmamasına özen göster.
* Yeni alan eklerken, mevcut kayıtların patlamaması için alanı opsiyonel (`?`) yap veya `@default(...)` değeri ata.
* İlişkili tablolar oluştururken foreign key'lerin ve referansların doğru bağlandığından emin ol (`@relation`).

### 1.2. Seeder (`seed.ts`) Güncellemeleri
* Veritabanına yeni bir tablo veya alan eklendiğinde `seed.ts` dosyasını mutlaka bu yeni yapıya uygun şekilde güncelle.
* Seeder çalıştırıldığında eski kayıtların temizlenmesi veya çakışmaması için `upsert` mantığı kullan ya da tohumlama sırasını doğru planla.

### 1.3. Firestore & NoSQL Güvenlik ve Şema Kuralları
* Firebase Firestore kuralları güncellenirken okuma/yazma izinlerini en kısıtlı ve güvenli şekilde tasarla.
* Firestore koleksiyon yapılarındaki değişikliklerin `FIRESTORE_SCHEMA.md` dosyasına yansıtılmasını sağla.

---

## 2. Doğrulama ve Senkronizasyon Protokolü

Veritabanı veya Prisma şemalarında yaptığın her değişiklikten sonra aşağıdaki adımları sırayla izle ve doğrula:

1. **Prisma Şema Güncelleme ve Kod Üretimi:**
   Prisma şemasını yerel veritabanına yansıtmak ve TypeScript tiplerini yeniden üretmek için backend dizininde şu komutu çalıştır:
   ```bash
   cd backend && npx prisma db push && npx prisma generate
   ```
   Bu komutun sıfır hata ile tamamlandığından emin ol.
2. **Tohumlama (Seeding) Testi (Gerekli Durumlarda):**
   Eğer seeder güncellendiyse veya sıfırdan veri yazılması gerekiyorsa:
   ```bash
   cd backend && npx prisma db seed
   ```
   çalıştırarak verilerin sorunsuz yazıldığını test et.
3. **TypeScript Tip Uyumunun Doğrulanması:**
   Prisma istemcisi (`@prisma/client`) tipleri yenilendiği için backend kodunda tip uyuşmazlığı oluşup oluşmadığını doğrula:
   ```bash
   cd backend && npx tsc --noEmit
   ```

# Story 65: Bulk Real Product Images Fetcher & AI Visual Generation Script

## 1. Amaç ve Kapsam
Hoppa ürün kataloğundaki tüm ürünlerin (`GlobalProduct` ve `Product` tabloları) placeholder/varsayılan görsellerden kurtarılarak gerçek ürün fotoğrafları ve yüksek kaliteli stüdyo görselleri ile güncellenmesi.

## 2. Mimari ve Yöntemler

### 2.1. Yöntem 1: Otomatik API / Katalog Arama (Primary Lookup)
* **Open Food Facts API & Unsplash / E-commerce Catalog**:
  * Ürünlerin `barcode`, `sku` veya `name` bilgisi kullanılarak otomatik arama yapılır.
  * Gerçek paketli ürün resmi bulunduğunda `imageUrl` doğrudan bu CDN bağlantısı veya indirilen gerçek görsel adresi ile güncellenir.

### 2.2. Yöntem 4: Yapay Zeka (AI) & Akıllı Görsel İyileştirme (Fallback)
* **Özel veya Bulunamayan Ürünler**:
  * Hazır gıda, fırın, restoran yemekleri veya spesifik lokal ürünler için ürün adı ve kategorisinden yola çıkılarak stüdyo kalitesinde, beyaz/temiz arka planlı ürün görselleri üretilir/atanır.
  * Oluşturulan görseller `backend/public/uploads/catalog/` klasöründe barındırılır ve yerel CDN adresi (`/uploads/catalog/...`) olarak kaydedilir.

## 3. Veritabanı ve Kod Değişiklikleri
* `backend/prisma/update_catalog_real_images.ts`: Toplu arama, çekme, AI üretme ve DB güncelleme script'i.
* `backend/public/uploads/catalog/`: Yerel görsel depolama dizini.

## 4. Test ve Doğrulama
* `npx ts-node backend/prisma/update_catalog_real_images.ts` komutunun başarıyla çalıştırılması.
* Toplam ürün sayısının ve görselleri gerçek ürün resmi ile güncellenen ürün oranının konsola raporlanması.

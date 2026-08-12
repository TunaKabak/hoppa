# Story 70: Web tabanlı Ürün & Menü Yönetim Paneli (Next.js - apps/web_app)

## 📌 Genel Bakış & Hedef
Mobil uygulamada (Merchant App) yüzlerce ürünü, kategori hiyerarşisini, varyasyonları (boyut, sos, ekstra malzeme), toplu stok durumlarını ve fiyat güncellemelerini yönetmek küçük ekran boyutları nedeniyle oldukça zordur. Satıcılarımızın (restoran, market, kasap, manav vb.) web tarayıcısı üzerinden masaüstü kolaylığı ile ürün kataloglarını yönetebilmeleri için `apps/web_app` (Next.js) üzerinde modern, yüksek performanslı, güvenlik açığı barındırmayan ve kullanıcı dostu bir **Satıcı Ürün Yönetim Portalı (Web Merchant Product Management Suite)** geliştirilecektir.

---

## 👥 Agent Tartışması ve Sorumluluk Dağılımı

### 🔍 Planner & Analyzer Agent (Analiz & Mimari)
* **Gereksinim Analizi:** Mobil uygulamanın kısıtlarını ortadan kaldıracak masaüstü odaklı ürün yönetim UX'i tasarlamak.
* **Etki Alanı:** `apps/web_app` Next.js frontend mimarisi, `backend/src/routes/merchantRoutes.ts`, `backend/src/controllers/ProductController.ts`, `backend/src/controllers/CategoryController.ts`.
* **Veri İzolasyonu:** Satıcı verilerinin kesinlikle birbirinden izole edilmesi (Merchant Isolation Guard).

### 🎨 Designer Agent (UI/UX Tasarımı)
* **Tasarım Dili:** Modern, sleek glassmorphism, karanlık/aydınlık mod seçenekleri, tutarlı padding, canlı rozetler (Badges), dinamik arama ve sıralama bileşenleri.
* **Masaüstü Verimliliği:** 
  * Ürün listesi için **Tablo (Data Grid)** ve **Kart (Grid)** görünümleri arasında geçiş.
  * Hızlı stok açma/kapama (Toggle Switch).
  * Yerinde (Inline) hızlı fiyat düzenleme.
  * Sürükle-bırak veya sıra numarası ile kategori/ürün sıralaması.
  * Restoranlar için görsel opsiyon/ekstra malzeme kurucusu (Option Group Builder).

### ⚙️ Backend Agent (API Servisleri)
* **Yeni API Endpoint'leri:**
  1. `PUT /api/merchant/products/bulk-stock`: Seçili ürünlerin stok durumunu toplu açma/kapama/güncelleme.
  2. `PUT /api/merchant/products/bulk-price`: Seçili ürünlere yüzdesel (%10 zam vb.) veya sabit tutarlı toplu fiyat güncellemesi.
  3. `GET /api/merchant/categories`: Satıcı mağaza türüne (Market/Restoran) göre hiyerarşik kategori ağacı.
  4. `POST /api/merchant/products/:id/option-groups`: Çoklu opsiyon grupları ve seçeneklerinin (Soslar, Boyutlar vb.) iç içe eklenmesi/güncellenmesi.
  5. `GET /api/merchant/products/export` & `POST /api/merchant/products/import`: Katalog dışa aktarma (CSV/JSON) ve toplu içe aktarma.

### 🛡️ QA & Security Agent (Güvenlik & Kalite)
* **Yetkilendirme Güvenliği (RBAC & Isolation Guard):** Her istekte JWT token doğrulaması sonrası `req.user.id` ile satıcının `Shop` kaydı kontrol edilir. Bir satıcı başka bir satıcının `productId`'sine ASLA erişemez (Horizontal Privilege Escalation engeli).
* **Girdi Doğrulama & XSS Koruması:** `price`, `regularPrice`, `barcode`, HTML açıklamalar ve `name` girdileri Zod/Validation şeması ile dezenfekte edilir. Negatif fiyatlar veya geçersiz barkodlar engellenir.
* **Medya Yükleme Güvenliği:** UUIDv4 regex doğrulaması, dosya boyutu sınırı (max 5MB), MIME type kontrolü (png, jpg, webp).

### 🎨 Frontend Agent (Next.js Geliştirici)
* **Sayfa Mimarisi (`apps/web_app`):**
  * `/merchant/login`: Satıcı güvenli giriş ekranı (JWT Cookie / LocalStorage yönetimi ve Auth Guard).
  * `/merchant/dashboard`: Mağaza durumu, ürün sayısı, hızlı aksiyonlar özeti.
  * `/merchant/products`: Ana Ürün Yönetim Portalı (Gelişmiş Filtreleme, Barkod / İsim Arama, Kategori Filtresi, Toplu Aksiyon Barı, Hızlı Stok Toggles, Inline Fiyat Düzenleyici).
  * `/merchant/products/new` & `/merchant/products/[id]/edit`: Ürün Ekleme / Düzenleme Formu (Resim Yükleyici, Barkod Tara/Gir, Birim/Marka Seçimi, Fiyat/İndirim Hesaplayıcı).
  * `/merchant/products/options`: İntuitif Ürün Opsiyon Grubu ve Ekstra Malzeme Oluşturucu (Soslar, Boyutlar, Ekstra Malzemeler, Min/Max Seçim Sınırları, Ücretsiz Seçim Adedi).
  * `/merchant/products/catalog-import`: Global Master Katalog Kütüphanesinden tek tıkla ürün aktarımı (Market/Bakkallar için).

---

## 📐 Veri Modeli ve Mimari Bağımlılıklar

Mevcut `Product`, `ProductOptionGroup`, `ProductOption`, `Category`, `Unit`, `Brand` modelleri `backend/prisma/schema.prisma` dosyasında tam uyumlu şekilde mevcuttur. Ek bir veritabanı şema değişikliğine gerek kalmadan mevcut PostgreSQL yapısı yüksek performansla kullanılacaktır.

---

## ✅ Doğrulama & Test Adımları
1. `npx tsc --noEmit` (Backend TypeScript derleme kontrolü).
2. `npm run build` (`apps/web_app` Next.js derleme doğrulaması).
3. Güvenlik İzolasyon Testleri: Bir satıcının JWT token'ı ile diğer satıcının `productId`'sini silmeye/güncellemeye çalışması engellenecek (403/404 kontrolü).

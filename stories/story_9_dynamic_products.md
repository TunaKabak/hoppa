Epic: Merchant Product Management & Catalog
Task: Story 9 - Dinamik Ürün Mimarisi ve Market Assertion Bugfix

DİKKAT (AGENT İÇİN): Bu görev .agent/rules/nightshiftrules dosyasına tabidir. Her adımı sırayla yap ve her adımın sonundaki "DOĞRULAMA" komutunu çalıştırıp hatasız geçtiğinden emin olmadan BİR SONRAKİ ADIMA GEÇME.

ADIM 1: Backend Veritabanı Şeması Güncellemesi

Farklı iş modellerini desteklemek için backend/prisma/schema.prisma dosyasındaki Product modelini esnek (Polymorphic) hale getireceğiz.

Product modeline şu opsiyonel (?) alanları ekle:

barcode (String?)

brand (String?)

stockQuantity (Int? @default(0))

weightOrVolume (String?)

preparationTime (Int?)

hasDeposit (Boolean? @default(false))

depositPrice (Float?)

DOĞRULAMA KOMUTU: Terminalde cd backend && npx prisma db push && npx prisma generate çalıştır. Hata almadığından emin ol.

ADIM 2: Backend Controller Akıllı Validasyon (Smart Validation)

backend/src/controllers/ProductController.ts dosyasını aç (yoksa oluştur ve rotalara bağla).

Ürün ekleme (createProduct) metodunda dükkanın tipine göre backend validasyonu ekle:

Eğer dükkan MARKET kategorisindeyse ve barcode boşsa 400 hatası dön ({ error: true, message: "Market ürünleri için barkod zorunludur." }).

DOĞRULAMA KOMUTU: Terminalde cd backend && npx tsc --noEmit çalıştır. Derleme hatası olmadığından emin ol.

ADIM 3: Frontend "Failed Assertion" Bugfix ve Dinamik Form UI

apps/merchant_app/lib/.../add_product_page.dart (veya ilgili ürün ekleme formu) dosyasını incele.

Market ürünü eklerken ortaya çıkan "Failed assertion" hatasını bul (Genellikle Riverpod State'inde eksik veya null değer atanmasından, dropdowndaki value uyuşmazlığından veya zorunlu bir TextEditingController'a null gelmesinden kaynaklanır). Null-safety kurallarını sıkılaştırarak bu hatayı çöz.

Formu Dükkanın Tipine (Kategorisine) göre dinamik hale getir (Dynamic Form Rendering):

RESTORAN İSE: Barkod ve Marka Textfield'larını GİZLE. "Hazırlanma Süresi" alanını GÖSTER.

MARKET İSE: Hazırlanma süresini GİZLE. "Barkod", "Marka" ve "Stok Adedi" alanlarını ZORUNLU olarak GÖSTER.

SU İSE: "Depozito Var mı?" (Switch) ve "Depozito Ücreti" alanlarını GÖSTER.

DOĞRULAMA KOMUTU: Terminalde cd apps/merchant_app && flutter analyze çalıştır. Hiçbir statik analiz hatası veya uyarı kalmadığından emin ol.

ADIM 4: Raporlama

Tüm adımlar ve doğrulamalar başarıyla bittiyse bana kısa bir özet geç ve "Failed Assertion" hatasının tam olarak hangi satırdan/mantıktan kaynaklandığını ve nasıl çözdüğünü açıkla.
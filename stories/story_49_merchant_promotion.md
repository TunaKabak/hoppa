🤖 Hoppa Akıllı Komisyon Motoru ve Öne Çıkarma Entegrasyonu Kılavuzu

Bu döküman, backend_agent ve frontend_agent'ların platformun sipariş başı dinamik komisyon, minimum sepet limit koruması ve Merchant App içi reklam yönetim panelini sıfır hatayla kodlayabilmesi için hazırlanmış teknik prompt setidir.

⚙️ 1. BACKEND AGENT PROMPTU (skills/backend_agent)

🎯 Görev:

Prisma, Express ve TypeScript kullanarak; "Gel Al" istisnalı Minimum Sepet Tutarı doğrulaması yapan ve dükkanın aktif kampanyalarına göre sipariş komisyonunu dinamik hesaplayan API altyapısını kurşun geçirmez şekilde kodlamak.

📝 Geliştirme Talimatı (Prompt):

GÖREV: Dinamik Komisyon Hesaplama ve Null-Safe Sepet Limiti API Entegrasyonu

Express, TypeScript ve Prisma ORM kullanarak, sipariş oluşturma (checkout) aşamasında çalışacak dinamik komisyon ve sepet koruma motorunu kodla:

1. VERİTABANI ŞEMASI GÜNCELLEMESİ (Prisma):
   - `Shop` modeline `minimumOrderLimit` (Decimal @db.Decimal(10, 2) - Varsayılan: 250.00 TL) kolonunu ekle.
   - `ShopPromotion` (Öne Çıkarma) tablosunu oluştur:
     * id (String - UUID)
     * shopId (String)
     * promoType (String - "MAIN_SCREEN" veya "CATEGORY")
     * startDate (DateTime)
     * endDate (DateTime)
     * isActive (Boolean - default: true)
   - `Order` modeline sipariş anındaki yansıyan komisyon oranını dondurup kaydetmek için `commissionRate` (Decimal) ve `commissionAmount` (Decimal) alanlarını ekle.

2. ASİMETRİK KOMİSYON VE SEPET LİMİT ALGORİTMASI:
   Sipariş oluşturma (`POST /api/orders`) middleware/controller katmanında şu kuralları işlet:
   
   - A. TESLİMAT TİPİ KONTROLÜ (Gel Al / Paket Servis):
     * Eğer sipariş "Gel Al" (Takeaway) ise, `minimumOrderLimit` kontrolünü TAMAMEN BYPASS ET (Sıfır sürtünme). Komisyon oranını ise doğrudan standart oran olan $\%5$ olarak ata.
     * Eğer sipariş "Eve Teslim" (Home Delivery) ise, sepet tutarını ($A$) dükkanın `minimumOrderLimit` ($L$) değeri ile kıyasla:
       $$A < L \implies \text{Hata: "Minimum sepet tutarı } L \text{ TL olmalıdır."}$$

   - B. DİNAMİK KOMİSYON ATAMA FORMÜLÜ (Cron-Job Bağımsız):
     Sipariş anındaki zaman diliminde ($T_{\text{now}}$), dükkanın `ShopPromotion` tablosunda aktif (`isActive = true`) ve $T_{\text{now}} \in [\text{startDate}, \text{endDate}]$ olan kayıtlarını sorgula:
     * Eğer aktif `MAIN_SCREEN` promosyonu varsa, o sipariş için komisyon oranını **$\%15$** yap.
     * Eğer aktif `CATEGORY` promosyonu varsa (ve Main Screen yoksa), komisyon oranını **$\%10$** yap.
     * Eğer hiçbir aktif promosyon yoksa, standart oran olan **$\%5$** komisyon oranını uygula.
     
   - C. HAKKANİYETLİ FORMÜLİZASYON:
     Kazanılacak net komisyon tutarını sipariş sepet tutarı ($AOV$) üzerinden kuruşu kuruşuna hesapla ve sipariş satırına kaydet:
     $$\text{CommissionAmount} = \text{AOV} \times \text{CommissionRate}$$

Bu kuralları test eden Mocha/Jest unit testlerini yaz ve `npx tsc --noEmit` ile tip güvenliğini onayla.


📱 2. FRONTEND AGENT PROMPTU (skills/frontend_agent)

🎯 Görev:

Flutter ve Riverpod kullanarak, satıcı uygulamasında (Merchant App) esnafın kolayca reklam satın alabileceği, mevcut aktif komisyon oranını görebileceği ve bütçesinin haftalık hakedişlerinden nasıl düşüleceğini şeffafça izleyebileceği arayüzü kodlamak.

📝 Geliştirme Talimatı (Prompt):

GÖREV: Merchant App Öne Çıkarma ve Canlı Komisyon Takip Arayüzü Kodlaması

Flutter ve Riverpod kullanarak, satıcıların reklam satın alma süreçlerini yönetecek şık, modern ve dürüst "Öne Çıkarma" (Sponsorship) ekranını kodla:

1. REKLAM YÖNETİM EKRANI (UX / UI):
   - Sayfanın en üstünde dükkanın o anki aktif komisyon oranını devasa bir kart içinde göster (Örn: "Aktif Komisyon Oranınız: %5").
   - İki büyük, modern seçim kartı (Sponsorship Cards) tasarla:
     * A. "Hoppa Ana Sayfa Tepe Slider Sponsorluğu"
       - Detay: "Dükkanınız 1 hafta boyunca ana sayfanın en üstünde parıldar. Peşin ücret yok! Sadece bu hafta gelen siparişlerden standart %5 yerine %15 komisyon tahsil edilir."
       - Aksiyon: "Hemen Aktif Et" butonu (Swipe to active / Sürgülü buton).
     * B. "Kategori İçi Öne Çıkarma Sponsorluğu"
       - Detay: "Kendi kategorinizde (Örn: Kebap) rakiplerinizin en üstünde yer alın. Sadece bu hafta gelen siparişlerden %10 komisyon alınır."
       - Aksiyon: "Hemen Aktif Et" butonu.

2. STATE VE API ENTEGRASYONU (Riverpod):
   - Satıcı "Aktif Et" dediğinde backend'deki `POST /api/merchant/promotions` endpoint'ine istek atan `sponsorshipNotifierProvider` yapısını kur.
   - Kampanya başarıyla tetiklendiğinde ekranı anında yenileyerek üstteki komisyon kartını animasyonlu bir şekilde `%15` veya `%10` olarak güncelle.
   - Yanlışlıkla tıklamaları önlemek için işlem öncesinde "Emin misiniz? Bu işlem haftalık hakedişlerinizden otomatik mahsup edilecektir." uyarısı içeren şık bir Cupertino/Material onay diyaloğu (dialog) göster.

Uygulamanın statik analizden (`flutter analyze`) sıfır hata ve sıfır uyarıyla geçtiğini onayla.

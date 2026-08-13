# Story 73: Satıcı Web Paneli Mağaza Ayarları Revizyonu ve Merchant App Paritesi

## 1. Amaç ve Kapsam
Satıcı web panelinde (`apps/web_app`) bulunan Mağaza Ayarları (`/merchant/settings`) ekranı, Flutter satıcı uygulaması (`apps/merchant_app`) ile tam özellik uyumuna (feature parity) getirilecek, "Tüm Değişiklikleri Kaydet" işleminin çalışmama sorunu tamamen çözülecek ve sekmeli, modern, kullanıcı dostu bir UI/UX tasarımı uygulanacaktır.

---

## 2. Mevcut Sorunlar ve Eksiklikler

1. **"Tüm Değişiklikleri Kaydet" İşleminin Çalışmaması:**
   - Web panelinden gönderilen payload formatı (özellikle `workingHours` dizisi) backend ve Flutter uygulamasının beklediği gün/obje yapısı (`{ monday: { isOpen, open, close }, ... }`) ile uyuşmuyordu.
   - `allowedPaymentMethods` ve `allowedFulfillmentModels` alanları backend validation tarafından zorunlu kontrol edilmesine rağmen web sayfasından hiç gönderilmiyordu.
2. **Merchant App'te Olup Web Panelinde Olmayan Özellikler:**
   - **Aktif Kampanya Mesajı (`campaignText`):** Mağaza üst bilgisinde yer alan duyuru metni (Max 60 karakter).
   - **Vergi Numarası (`taxNumber`) & Şahıs/Kimlik Numarası (`identityNumber`):** Resmi dükkan kayıt bilgileri.
   - **Mağaza Logosu ve Kapak Görseli Yükleme:** Sadece URL metni yerine doğrudan `/media/upload-url` presigned URL servisi ile görsel seçip yükleme.
   - **Ortalama Teslimat Süresi (`deliveryTime`):** `15-30 dk`, `30-45 dk`, `45-60 dk`, `60+ dk` seçim opsiyonları.
   - **Ücretlendirme Tipi (`deliveryPricingType`):** Sabit Ücret (`FIXED`) vs Mesafeye Göre (`DISTANCE_BASED`).
   - **Temel Teslimat Ücreti (`baseDeliveryFee`), Km Başına Ücret (`deliveryFeePerKm`), Ücretsiz Teslimat Limiti (`freeDeliveryThreshold`).**
   - **Ödeme Yöntemleri Toggling:** Online Kredi Kartı (`ONLINE_PAYMENT`), Kapıda Nakit (`CASH_ON_DELIVERY`), Kapıda Kart (`CARD_ON_DELIVERY`).
   - **Teslimat/Hizmet Seçenekleri Toggling:** Hoppa Kuryesi (`PLATFORM_DELIVERY`), İşletme Kuryesi (`SELF_DELIVERY`), Gel-Al (`PICKUP`).
   - **Çalışma Saatleri:** Pazartesi saatlerini tüm günlere kopyalama ("Pazartesi'yi Tümüne Uygula") yeteneği ve doğru veri serileştirme.
   - **Dükkan Adresi Detayları:** KKTC Şehir (`_kktcCities`) ve Semt (`kKktcDistricts`) açılır listeleri.
   - **Teslimat Bölgesi Modu:** Yarıçap (KM Slider + Çember) vs Özel Poligon Bölgesi (Haritada poligon köşelerini tıklayarak çizme/düzenleme/temizleme).

---

## 3. Sekmeli Tasarım ve Mimari Yapı

Ayarlar ekranı 3 ana sekme halinde düzenlenecektir:

### Sekme 1: 🏪 Mağaza Profili & Görseller (Profile & Branding)
* Mağaza Ticari Adı (`name` / `businessName`)
* İletişim Telefonu (`phone` / `businessPhone`)
* Aktif Kampanya Mesajı (`campaignText`) - Max 60 karakter
* Vergi Numarası (`taxNumber`) & Kimlik Numarası (`identityNumber`)
* Logo Yükleme & Önizleme (Presigned R2/Local Upload + Sürükle Bırak / Dosya Seç)
* Kapak Görseli Yükleme & Önizleme (Gradient Fallback + Presigned Upload)

### Sekme 2: ⚙️ Operasyon, Ödeme & Saatler (Operation, Payment & Working Hours)
* **Sipariş & Teslimat Ayarları:** Min. Sipariş Tutarı, Ortalama Teslimat Süresi, Ücretlendirme Tipi (Sabit / Mesafeli), Temel Ücret, Km Başına Ekstra Ücret, Ücretsiz Teslimat Limiti.
* **Kabul Edilen Ödeme Yöntemleri:** Online Kart, Kapıda Nakit, Kapıda Kart anahtarları.
* **Hizmet Modelleri:** Hoppa Kuryesi, İşletme Kuryesi, Gel-Al anahtarları.
* **7 Günlük Çalışma Saatleri:** Her gün için Açık/Kapalı switch, Açılış/Kapanış zaman seçicileri, "Pazartesi'yi Tümüne Uygula" kopyalama aksiyonu.

### Sekme 3: 📍 Adres & Teslimat Bölgesi (Address & Interactive Map Zone)
* KKTC Şehir & Semt/İlçe seçimi.
* Açık Adres metin alanı + "GPS ile Konumumu Getir" ve Haritada Pinleme.
* Teslimat Bölgesi Modu Seçici: **Yarıçap (KM)** veya **Özel Bölge (Poligon)**.
* İnteraktif Leaflet Haritası:
  * Yarıçap modunda canlı çember (CircleMarker) ve mesafe slider'ı.
  * Poligon modunda haritaya tıklayarak poligon noktaları ekleme, çizgiler çekme, noktaları silme ve temizleme.

---

## 4. Etki Analizi ve Veri Doğrulama (Validation)

1. **Backend Uyum Seviyesi (`ShopController.ts`):**
   - `PUT /merchant/shop` endpoint'i tüm bu alanları desteklemektedir.
   - `allowedPaymentMethods` ve `allowedFulfillmentModels` boş dizi olmamalıdır (Frontend guard eklenecektir).
2. **Frontend State & Hydration:**
   - Backend `GET /merchant/shop` verisinden alınan adres, şehir, semt, çalışma saatleri ve poligon verileri form state'ine sorunsuz aktarılacaktır.

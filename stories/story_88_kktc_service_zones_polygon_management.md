# Story 88: Satıcı Web Panelinde Yönetici (Admin) İçin KKTC Hizmet Alanları ve Poligon Sınır Çizim Yönetimi

## 📌 1. Genel Bakış ve Amaç
Hoppa Satıcı Web Paneli'nde (`apps/web_app`) yönetici rolüne (`role: 'admin'` veya `role: 'super_admin'`) sahip kullanıcıların, Kuzey Kıbrıs Türk Cumhuriyeti (KKTC) genelindeki aktif platform hizmet yerlerini, ilçe/şehir bazlı teslimat bölgelerini interaktif harita üzerinde serbest poligon çizerek (`polygon`) belirleyebilmesi, düzenleyebilmesi ve sisteme kaydedebilmesidir.

---

## 🏗️ 2. Mimari Tasarım ve Sistem Bileşenleri

```
+-------------------------------------------------------------------------------------------------------+
|                                    SATICI / ADMIN WEB PANELİ (DESKTOP)                                |
+----------------------+--------------------------------------------------------------------------------+
|                      |  [ KAVİSLİ HOPPA DEGRADE HEADER (bg-gradient-to-r #E95D22 -> #FF8C00) ]        |
|   SOL SABİT          |  * Başlık: "KKTC Hizmet Alanları & Sınır Yönetimi" (ADMIN ÖZEL)                 |
|   SIDEBAR            |  * Butonlar: [ + Yeni Bölge Çiz ] [ 💾 Değişiklikleri Kaydet ] [ 🔄 Sıfırla ]   |
|   (w-72)             +--------------------------------------------------------------------------------+
|   - Hoppa Logo       |  [ KAVİSLİ İÇERİK ALANI (rounded-t-[32px]) ]                                   |
|   - Ürünler          |  +-------------------------------------+-------------------------------------+  |
|   - Siparişler       |  | SOL PANEL: BÖLGE LİSTESİ & KONTROL | SAĞ PANEL: LEAFLET POLİGON HARİTASI  |  |
|   - Performans       |  | - Aktif / Pasif Bölgeler            | - KKTC İnverted Mask & Sınırlar     |  |
|   - Kampanyalar      |  | - Lefkoşa, Girne, Mağusa vb.        | - Nokta Ekle / Sürükle / Sil       |  |
|   - Ayarlar          |  | - Min Tutar, Teslimat Ücreti        | - Renk Paleti & Saydamlık           |  |
|   - [KKTC BÖLGELERİ] |  | - "Bu Noktayı Test Et" Doğrulayıcı  | - Tam Ekran & Canlı Koordinatlar   |  |
|     (Sadece Admin)   |  +-------------------------------------+-------------------------------------+  |
+----------------------+--------------------------------------------------------------------------------+
```

---

## 📐 3. Fonksiyonel Gereksinimler & Özellikler

### 3.1. Rol Tabanlı Erişim (Admin Guard)
- Yalnızca `role === 'super_admin' || role === 'admin'` olan kullanıcılar sol menüde **"KKTC Hizmet Alanları"** navigasyon sekmesini ve `/merchant/service-zones` sayfasını görebilir.
- Yetkisiz satıcılar sayfaya doğrudan girmeye çalışırsa `/merchant/dashboard`'a yönlendirilir.

### 3.2. Harita Çizim & Düzenleme Yetenekleri (Interactive Leaflet Drawing Suite)
1. **Poligon Çizim Modu:** Harita üzerine tıklayarak yeni sınır köşe noktaları (vertex) ekleme.
2. **Nokta Düzenleme & Silme:** Köşe noktasına tıklayarak silme, sürükleyerek (drag) koordinat güncelleme.
3. **Çoklu Bölge Yönetimi (Multi-Zone):**
   - Her bölge için: Bölge Adı, İlçe (Lefkoşa, Girne, Gazimağusa, Güzelyurt, İskele, Lefke), Durum (Aktif/Pasif), Min. Sipariş Tutarı, Teslimat Ücreti, Tahmini Teslimat Süresi ve Özel Renk Seçimi.
4. **Hızlı Şablonlar (Quick Presets):**
   - "Resmi KKTC Sınırlarını Yükle"
   - "Lefkoşa Merkez & Çevre"
   - "Girne Sahil Şeridi"
   - "Gazimağusa & DAÜ Kampüs"
   - "Güzelyurt & Lefke Bölgesi"
   - "İskele & Long Beach"
5. **Canlı Adres / Koordinat Test Aracı (Point-in-Polygon Tester):**
   - Yöneticinin harita üzerine bıraktığı bir test pininin veya aradığı adresin belirlenen hizmet alanlarının içinde olup olmadığını anında analiz eden Ray-Casting doğrulayıcısı.

### 3.3. Veri Kalıcılığı & API Entegrasyonu
- **Backend API:** 
  - `GET /api/admin/service-zones`: Kayıtlı tüm hizmet bölgelerini listeler.
  - `POST /api/admin/service-zones`: Yeni hizmet bölgesi ekler / günceller.
  - `DELETE /api/admin/service-zones/:id`: Bölge siler.
  - `PUT /api/admin/service-zones/bulk`: Tüm bölgeleri toplu günceller.
- **Frontend Fallback:** API yanıt vermese dahi LocalStorage / varsayılan KKTC profili üzerinden kesintisiz çalışabilirlik.

---

## 📂 4. Etkilenecek Dosyalar

1. **`apps/web_app/src/components/merchant/MerchantLayout.tsx`:** Sol menüye Admin kullanıcılar için `KKTC Hizmet Alanları` sekmesinin eklenmesi.
2. **`apps/web_app/src/components/merchant/KktcServiceZoneDrawerMap.tsx` [YENİ]:** Gelişmiş Leaflet tabanlı çoklu poligon çizim, düzenleme ve köşe yönetimi bileşeni.
3. **`apps/web_app/src/pages/merchant/service-zones/index.tsx` [YENİ]:** Hizmet bölgeleri listesi, kartları, filtreleri, şablonları ve test panelini barındıran kavisli tasarımlı sayfa.
4. **`backend/src/routes/adminRoutes.ts` & `backend/src/controllers/SuperAdminController.ts`:** Hizmet bölgelerinin veritabanında/sistem konfigürasyonunda saklanmasını sağlayan API rotaları.
5. **`backend/prisma/schema.prisma`:** `ServiceZone` modeli veya `SystemConfig` desteği.

---

## 🧪 5. Doğrulama ve Test Adımları
- [ ] Admin kullanıcısı ile giriş yapıldığında sol menüde sekmenin görünmesi.
- [ ] Normal satıcı hesabında sekmenin gizlenmesi ve erişim engeli.
- [ ] Haritada çoklu poligon çizme, köşe noktası ekleme, köşe noktası silme ve sürükleme testleri.
- [ ] Bölge kaydetme, düzenleme, renk değiştirme ve silme akışları.
- [ ] Point-in-Polygon test aracının doğru bölgeyi tespit etmesi.
- [ ] TypeScript (`npx tsc --noEmit`) derleme doğrulaması.

# Story 71: Mobil Satıcı Uygulaması (Merchant App) Tüm Ekran ve Özelliklerinin Web Portalına Taşınması ve Güdümlü Kullanıcı Yönlendirme Sistemi

## 🎯 Hikaye Amacı (User Story)
**Bir Hoppa Satıcısı olarak;**
Mobil uygulamada (`apps/merchant_app`) yapabildiğim tüm işlemleri (Canlı Sipariş Takibi & Durum Güncelleme, Sesli Bildirim / Alarm, Performans & Ciro Analizi, Hakediş & Ödeme Raporları, İndirim Kuponu & Reklam/Sponsorluk Başvuruları, Mağaza Çalışma Saatleri & Teslimat Bölgesi Ayarları ve Yapay Zeka Menü Taraması) masaüstü web panelinde (`apps/web_app`) kesintisiz ve yönlendirici (guided setup & quick actions) bir deneyimle gerçekleştirmek istiyorum.

---

## 👥 Agent Rol Dağılımı ve Sorumluluklar

### 🎨 1. Designer Agent (UI/UX & Tema Temsilcisi)
* **Sorumluluk:**
  * Masaüstü ekran çözünürlükleri için Kanban Kanban/Pipeline sipariş takip panosu tasarımı.
  * Hem **Varsayılan Beyaz (Light)** hem de **Karanlık (Dark)** modda mükemmel okuma kolaylığı sağlayan finansal grafikler, canlı sayaçlar ve onboarding yönlendirme kartları.
  * Yeni gelen siparişler için duyulabilir ses uyarısı (Web Audio Chime / Alarm).

### ⚙️ 2. Backend Agent (API & Entegrasyon Geliştiricisi)
* **Sorumluluk:**
  * `OrderController.ts`: Sipariş durum değişiklikleri (`PENDING` -> `PREPARING` -> `ON_THE_WAY` -> `DELIVERED` veya `CANCELLED`), kurye atama tetiklemeleri.
  * `ShopController.ts`: `getDashboardStats` içinde günlük/haftalık/aylık ciro, ortalama teslimat süresi, hakediş raporu ve en çok satan ürünler istatistikleri.
  * `ShopCampaignController.ts`: Kampanya ve kupon oluşturma / silme apileri.

### 🎨 3. Frontend Agent (Next.js & Web Geliştirici)
* **Sorumluluk:**
  * `src/pages/merchant/orders/index.tsx`: Canlı Kanban Sipariş Akış Portalı (Yeni Siparişler, Hazırlananlar, Yoldakiler, Tamamlananlar, Sesli Alarm, Yazdır butonu).
  * `src/pages/merchant/dashboard/index.tsx`: Performans, Ciro, Sepet Tutarları ve Hakediş/Finans Portalı.
  * `src/pages/merchant/campaigns/index.tsx`: Kampanya, İndirim Kuponları ve Öne Çıkarılan Mağaza (Sponsorluk) Başvuru Portalı.
  * `src/pages/merchant/settings/index.tsx`: Mağaza Bilgileri, Çalışma Saatleri (Pazartesi-Pazar), Teslimat Bölgesi (KM), Minimum Sipariş Tutarı ve IBAN Hesap Ayarları.
  * `src/components/merchant/GuidedOnboardingWidget.tsx`: Satıcıyı adım adım yönlendiren, eksik yapılandırmaları hatırlatan (örn: "Çalışma saatleriniz eksik", "3 sipariş onay bekliyor") yönlendirici widget.

### 🛡️ 4. QA & Security Agent (Kalite & Güvenlik Temsilcisi)
* **Sorumluluk:**
  * TypeScript derleme (`npx tsc --noEmit`) sıfır hata garantisi.
  * JWT yetki kontrolleri ve tarayıcı canlı doğrulama testleri.

---

## 📋 Kabul Kriterleri (Acceptance Criteria)

1. **Canlı Sipariş Portalı (`/merchant/orders`):**
   - Yeni sipariş düştüğünde sesli uyarı (Audio Alarm chime).
   - Siparişi "Onayla & Hazırla", "Kuryeye Teslim Et" ve "İptal Et" tek tıkla durum geçişi.
   - Sipariş detay fişi görüntüleme ve yazdırma.
2. **Performans & Analiz Portalı (`/merchant/dashboard`):**
   - Toplam ciro, sipariş adedi, ortalama teslimat süresi kartları.
   - En çok satan Top 5 ürün ve günlük/haftalık ciro grafiği.
   - Hakediş hesap özeti (Komisyon kesintileri ve net ödeme).
3. **Kampanya & Reklam Portalı (`/merchant/campaigns`):**
   - İndirim kuponu oluşturma ve yönetme.
   - Öne çıkan mağaza sponsorluk başvurusu.
4. **Mağaza Ayarları & Çalışma Saatleri (`/merchant/settings`):**
   - Mağaza adı, telefon, adres, logo ve kapak görseli güncelleme.
   - 7 günlük çalışma saatleri tablosu.
   - Min. sipariş tutarı, teslimat yarıçapı ve IBAN bilgileri.
5. **Güdümlü Yönlendirme (Guided User Onboarding):**
   - Üst bilgi çubuğunda hızlı aksiyon yönlendirmeleri.

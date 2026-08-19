# Story 86: Satıcı Web Paneli Kavisli (Curved) Header Mimarisi ve Tasarım Sistemi Revizyonu

## 📌 Genel Bakış ve Amaç
Consumer mobil uygulamasındaki karakteristik **Hoppa Turuncu Degrade Kavisli Header (Curved Header)** tasarım dilinin, Satıcı Web Paneli'nin sağ içerik sütununa uyarlanması; turuncu butonlardaki göz yoran neon gölgelerin kaldırılarak modern, ferah ve kurumsal bir **Linear / Stripe estetiğine** kavuşturulmasıdır.

---

## 🏗️ 1. Mimari Tasarım ve Bileşen Yapısı

```
+----------------------------------------------------------------------------------------------------+
|                                      SATICI WEB PANELİ (DESKTOP)                                    |
+----------------------+-----------------------------------------------------------------------------+
|                      |  [ KAVİSLİ HOPPA DEGRADE HEADER (bg-gradient-to-r #E95D22 -> #FF8C00) ]     |
|   SOL SABİT          |  * Dinamik Sayfa Başlığı & Açıklaması (Beyaz Tipografi)                     |
|   SIDEBAR            |  * Hızlı Eylemler (Açık/Kapalı Durumu, Tema Değiştirici, Hızlı Butonlar)   |
|   (w-72)             |  * Yumuşak Alt Kavis / Dalga Eğrisi (Convex Arc / Bottom Wave)              |
|   - Hoppa Logo       +-----------------------------------------------------------------------------+
|   - Navigasyon       |  [ KAVİSLİ İÇERİK ALANI (rounded-t-[32px] bg-white / bg-slate-900) ]        |
|   - Mağaza Kartı     |  * -mt-6 / -mt-8 ile Header'a binen şık katman derinliği (elevation)        |
|   - Çıkış Yap        |  * Sayfa İçerikleri ({children})                                            |
|                      |  * Düz (Flat) & Mikro-Animasyonlu Turuncu Butonlar (Neon Gölgesiz)          |
+----------------------+-----------------------------------------------------------------------------+
```

---

## 🎨 2. Tasarım İlkeleri ve Token'lar

### 2.1. Renk ve Degrade Paleti
- **Header Gradient:** `linear-gradient(135deg, #E95D22 0%, #FF6B00 50%, #FF8C00 100%)`
- **İçerik Zemin (Light):** `bg-slate-50` arka plan üzerinde `bg-white` kavisli kart.
- **İçerik Zemin (Dark):** `bg-slate-950` arka plan üzerinde `bg-slate-900` kavisli kart.
- **Butonlar:** Neon turuncu gölgeler (`shadow-[#FF6B00]/...`) kaldırılarak `bg-[#FF6B00] hover:bg-[#E56000] active:scale-[0.98] transition-all` düz (flat) kurumsal stile geçirilir.

### 2.2. Geometri ve Kavis (Curved Radius)
- Üst gövde paneli: `rounded-t-[32px]` veya `rounded-t-[36px]`.
- Yumuşak ambient gölge: `shadow-xl shadow-black/5` (Light) ve `border-t border-slate-800` (Dark).

---

## 📂 3. Etkilenen Dosyalar ve İş Paketleri

1. **`apps/web_app/src/components/merchant/MerchantLayout.tsx`:**
   - Sağ içerik alanına kavisli degrade header (`HoppaCurvedHeader`) entegrasyonu.
   - Sayfa başlığı, alt başlık ve opsiyonel aksiyon slotu desteği (`headerAction`).
2. **Sayfa Modülleri:**
   - `src/pages/merchant/dashboard/index.tsx`: Mükerrer başlık kartlarının temizlenmesi, metrik kartlarının kavisli gövdeye yerleşimi.
   - `src/pages/merchant/products/index.tsx`: "Yeni Ürün Ekle" ve arama/filtreleme çubuğunun kavisli yapıya uyarlanması.
   - `src/pages/merchant/orders/index.tsx`: Sipariş filtre sekmeleri ve canlı sayaçların kavisli yapıya entegrasyonu.
   - `src/pages/merchant/campaigns/index.tsx` & `src/pages/merchant/settings/index.tsx`: Sayfa düzenlerinin kavisli tasarım diline uyarlanması.
3. **Göz Yoran Turuncu Gölgelerin Temizlenmesi:**
   - Tüm buton ve sekmelerdeki `shadow-[#FF6B00]/...` gölgelerinin kaldırılarak düz / nötr minimal gölgeye dönüştürülmesi.

---

## 🧪 4. Doğrulama ve Kabul Kriterleri
- [ ] Hem açık (Light) hem koyu (Dark) temada kavis geçişlerinin kusursuz görünmesi.
- [ ] Responsive mobil ekranda ve masaüstü geniş ekranlarda düzen bozulmalarının olmaması.
- [ ] `npx tsc --noEmit` ile 0 TypeScript hatası.

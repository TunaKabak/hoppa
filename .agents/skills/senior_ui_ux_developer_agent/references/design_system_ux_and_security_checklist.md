# Hoppa UI/UX Tasarım Sistemi & Arayüz Güvenlik Kontrol Listesi

Bu belge, `senior_ui_ux_developer_agent` tarafından uygulanan teknik tasarım token'ları, ergonomi sınırları, WCAG 2.1 AA gereksinimleri ve frontend güvenlik kapılarını özetler.

---

## 1. Uzamsal (Spacing), Yarıçap (Radius) ve Hareket Ölçeği

* **4pt / 8pt Grid:** Tüm boşluklar 4px katlarıyla ilerler (`4, 8, 12, 16, 20, 24, 32, 40, 48, 64px`).
* **Köşe Yarıçapı Hiyerarşisi:**
  * Mini Rozet / Etiket: `6px` (`rounded-md`)
  * Input / Buton / Küçük Kontrol: `10px–12px` (`rounded-xl`)
  * Kart / Tablo Konteyneri: `16px` (`rounded-2xl`)
  * Drawer / Modal / Sheet: `20px–24px` (`rounded-3xl`)
* **Mikro-Etkileşim Süreleri:**
  * Hover / Focus geçişleri: `150ms cubic-bezier(0.2, 0, 0, 1)`
  * Drawer / Modal / Dropdown açılışı: `200ms–240ms cubic-bezier(0.16, 1, 0.3, 1)`
  * `prefers-reduced-motion: reduce` aktifken tüm scroll-reveal ve transform animasyonları anında `opacity: 1; transform: none` durumuna geçer.

---

## 2. Tipografi Ölçeği (Web & Flutter Ortak Hedef)

| Seviye | Boyut / Satır Yüksekliği | Ağırlık | Kullanım |
| :--- | :--- | :--- | :--- |
| **Display / Hero** | `36px–48px` / `1.12` | `700` | Public Web Hero, Kampanya Başlığı |
| **Sayfa Başlığı (H1)** | `24px–28px` / `1.25` | `700` | Portal sayfa başlıkları, Mobil ana başlık |
| **Bölüm Başlığı (H2)** | `18px–20px` / `1.3` | `600` | Kart grupları, Drawer başlıkları |
| **Kart Başlığı / CTA** | `15px–16px` / `1.4` | `600` | Ürün adı, birincil buton metni |
| **Gövde Metni (Body)** | `14px` / `1.5` | `400`–`500` | Tablo hücreleri, açıklamalar, form girdileri |
| **İkincil / Meta (Caption)** | `12px` / `1.4` | `500` | Tarih, alt etiket (Taban sınır: `< 12px` **yasak**) |
| **Finansal / Sayaç** | `14px–32px` | `600`–`700` | `tabular-nums` / `FontFeature.tabularFigures()` zorunlu |

---

## 3. WCAG 2.1 AA & Dokunma Hedefi Kuralları

* **Kontrast:** Normal metin `>= 4.5:1`, büyük metin (`>= 18px` veya `>= 14px bold`) ve UI sınır çizgileri `>= 3.0:1`.
* **Dokunma Hedefleri:**
  * Mobil (`consumer`, `merchant`, `courier`): Minimum **`48x48dp`** (`courier_app` saha aksiyonlarında **`52x56dp`** önerilir).
  * Web Portal ikon butonları: Minimum **`36x36px`–`40x40px`**.
* **Odak & Klavye:**
  * Tüm etkileşimli öğelerde `:focus-visible` (2px dış halka) bulunmalıdır.
  * Özel dropdown (`HoppaSelect`), tablar ve dialoglar tam klavye (`Tab`, `Arrow`, `Enter`, `Escape`) ve ARIA rollerine sahip olmalıdır.

---

## 4. Arayüz Güvenliği & Prod Yayım Kapısı (Frontend / UI Checklist)

1. `apps/web_app` içinde harici veriler (zone adı, mağaza adı, yorum, adres) asla ham HTML string birleştirmeyle (`bindTooltip`, `innerHTML`, `dangerouslySetInnerHTML`) basılmıyor mu?
2. Harici CDN script'leri (`unpkg.com`) yerine paketlenmiş bağımlılıklar veya SRI hash'i kullanılıyor mu?
3. Korumalı sayfalar (`service-zones`, `admin/*`, `merchant/*`) ilk render'da `isAuthReady` / `isAuthorized` kapısı arkasında mı?
4. `next.config.js` / hosting header yapılandırmasında (`vercel.json` / `_headers`) `CSP`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy` tanımlı mı?
5. Web kimlik doğrulama ve SSE bağlantıları URL query'de token taşımaktan ve `localStorage`'da uzun ömürlü refresh token tutmaktan arındırılıyor mu?
6. Mobil `ThreeDSecurePage` yalnızca `https://` şemasına izin verip tamamlamayı doğrulanan backend hostundan okuyor mu?
7. Mobil release build'lerde `badCertificateCallback => true`, gizli `DatabaseSeeder` uzun-basma tetikleyicisi, cleartext `http://` LAN fallback'i ve `.env` asset paketlemesi sıfırlandı mı?
8. Formlar hem istemci hem sunucu tarafında doğrulanıyor; ödeme tutarları, kuponlar ve opsiyon fiyatları hiçbir zaman yalnızca UI/client state'ine emanet edilmiyor mu?

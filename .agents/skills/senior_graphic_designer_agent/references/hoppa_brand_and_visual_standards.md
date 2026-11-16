# Hoppa Marka ve Görsel Tasarım Standartları (Referans Kılavuz)

Bu kılavuz, `senior_graphic_designer_agent` tarafından kullanılan kanonsal renk, logo, ikonografi ve varlık kalite standartlarını içerir.

---

## 1. Kanonsal Renk Token Tablosu

| Rol | Token Adı | Light Mode | Dark Mode | Kullanım Notu |
| :--- | :--- | :--- | :--- | :--- |
| **Ana Marka Vurgusu** | `brand-primary` | `#FF6B00` | `#FF7A1A` | Yalnızca birincil CTA butonları, aktif sekme/nav vurgusu, kritik marka mühürleri |
| **Ana Marka Hover** | `brand-primary-hover` | `#E55A00` | `#FF8F3F` | Basma ve hover geçişleri (`150ms–200ms`) |
| **Marka Yüzey Tonu** | `brand-primary-tint` | `#FFF4EC` | `rgba(255, 107, 0, 0.14)` | Seçili satır/kart vurgusu, ikon rozeti zemini |
| **Marka Güven Yeşili** | `brand-secondary` | `#00A651` | `#10B981` | Mağaza açık, kurye nöbette, pozitif büyüme, doğrulama |
| **Ana Zemin (Canvas)** | `bg-canvas` | `#F8FAFC` | `#0B0F17` | Sayfa arka planı; ekran başına rastgele `#F4F7F6` / `#F8F9FA` uydurma |
| **Birincil Yüzey (Card)** | `bg-surface` | `#FFFFFF` | `#111827` | Kartlar, tablolar, drawer ve modallar |
| **İkincil Yüzey (Muted)** | `bg-surface-subtle` | `#F1F5F9` | `#1E293B` | Input dolguları, tablo başlıkları, pill arka planları |
| **İnce Kenarlık** | `border-subtle` | `#E2E8F0` | `rgba(148, 163, 184, 0.16)` | 1px kurumsal ayrım; gölge bağımlılığını azaltır |
| **Birincil Metin** | `text-primary` | `#0F172A` | `#F8FAFC` | Başlıklar, ana tutarlar, ürün isimleri (`>= 12:1` kontrast) |
| **İkincil Metin** | `text-secondary` | `#475569` | `#94A3B8` | Açıklamalar, alt başlıklar (`#94A3B8` beyaz zeminde küçük metinde **yasak**) |
| **Uyarı / Hazırlanıyor** | `status-warning` | `#D97706` | `#F59E0B` | Bekleyen sipariş, SLA yaklaşımı |
| **Kritik / İptal** | `status-danger` | `#E11D48` | `#FB7185` | İptal, reddedilen onay, SLA aşımı |

---

## 2. Logo ve Logomark Kullanım Matrisi

| Kullanım Alanı | Boyut | Zorunlu Varlık | Yasaklı Uygulama |
| :--- | :--- | :--- | :--- |
| Browser Favicon / Tab | `16x16` – `32x32` | `logo-mark.svg` / `.ico` | 5 harfli tam "Hoppa" kelimesi |
| Harita Mağaza / Kurye Pini | `24x24` – `36x36` | `logo-mark.svg` | `1024x1024` kare tam kelime PNG |
| Mobil Alt Bar Orta Buton | `48x48` – `56x56` | `logo-mark.svg` (temiz alfa / vector) | Dama tahtalı sahte şeffaf JPEG/PNG |
| Portal Sidebar / Giriş Header | `120px+` genişlik | `logo-full-light.svg` / `logo-full-dark.svg` | Lacivert kare JPEG (`hoppa_merchant_logo.jpg`) |
| Web Footer (Koyu Zemin) | `140px+` genişlik | `logo-full-dark.svg` | `brightness-0 invert` CSS filtresi |

---

## 3. Görsel ve SVG Kalite Kontrol Listesi (12 Maddelik Ön-Onay Kapısı)

1. Görselin gerçek binary formatı uzantısıyla eşleşiyor mu? (JPEG'e `.png` adı verilmemiş mi?)
2. Şeffaf ikon/buton varlıkları gerçek alfa kanalı veya SVG vektörü mü? (Sahte gri-beyaz kareli zemin yok mu?)
3. Tüm kategori/durum ikonları sistem emojisi yerine SVG/vektör ikon mu?
4. Ödeme yöntemlerinde (`Visa`, `Mastercard`, `Troy`, `CardPlus`) resmi SVG marka ikonları kullanılıyor mu?
5. SVG dosyalarında `<defs>` blokları referans verildiği öğelerden önce mi tanımlanmış?
6. Kategori ikon SVG'lerinin içinde bileşen arka planını bozan sabit opak `<rect>` kutusu yok mu?
7. Afiş ve kampanya görsellerinde cihaz çerçevesi (`phone mockup`) olmadan saf sahne kompozisyonu kuruldu mu?
8. Görsellerdeki metin yerleşimi altında okunabilirliği koruyan koyu scrim veya yüksek kontrastlı alan var mı (`>= 4.5:1`)?
9. Tek bir görsel dosyası `2 MB` sınırının (tercihen kartlarda `< 300 KB`, hero'larda `< 600 KB`) altında mı?
10. Kök `assets/` ile uygulama altı `assets/` arasında mükerrer veya çelişkili dosya kopyaları temizlendi mi?
11. `pubspec.yaml` dosyaları kullanılan tüm yeni/güncel görsel ve ses yollarını kapsıyor mu?
12. `apps/web_app/public/` içinde geliştirme referans ekran görüntüsü (ör. `checkout-reference.png`) gibi artık dosya kalmadığından emin olundu mu?

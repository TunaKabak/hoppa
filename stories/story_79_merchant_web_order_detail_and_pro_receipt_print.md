# Story 79: Satıcı Web Paneli Kapsamlı Sipariş Detayı Modalı ve Profesyonel Termal/Mutfak Fişi Yazdırma

## 1. Genel Bakış ve Amaç
Satıcı web panelinde (`apps/web_app/src/pages/merchant/orders/index.tsx`) iki temel eksiklik bulunmaktadır:
1. **Sipariş Detayı Ekranının Olmaması:** Satıcı sipariş kartına tıkladığında siparişin tüm kalemlerini, ürün özelleştirmelerini (sos, ek malzeme, çıkarma vb.), müşteri sipariş notunu, teslimat tercihlerini (zili çalma, kapıya bırak vb.), ödeme yöntemini ve kurye durumunu göremiyordu.
2. **Yazdırma İşleminin Düzensiz Olması:** "Fiş Yazdır" butonuna basıldığında `@media print` CSS izolasyonu olmadığı için tarayıcı tüm web sayfasını (sol navigasyon, kanban panosu, koyu tema arkaplanı) bozuk şekilde yazdırmaya çalışıyordu. Ayrıca fiş düzeni profesyonel bir 80mm mutfak/termal POS fişi standardında değildi.

Bu hikaye ile modern bir **Sipariş Detay Modalı/Çekmecesi (Order Details Drawer)** ve **İzole Termal POS Fişi Yazdırma Sistemi** geliştirilecektir.

---

## 2. Tasarım ve Fonksiyonel Gereksinimler

### 2.1. Sipariş Detay Modalı (Comprehensive Order Detail Modal)
- Sipariş kartına tıklandığında modern bir detay modalı/çekmecesi açılır.
- **İçerik:**
  - **Başlık & Durum Rozeti:** Sipariş No (`#ABC123`), oluşturulma saati, canlı durum etiketi (Bekliyor, Hazırlanıyor, Yolda, Tamamlandı).
  - **Müşteri & Teslimat Bilgileri:** Müşteri adı, telefon numarası, açık teslimat adresi.
  - **Teslimat Tercihleri ve Notlar:** Müşteri sipariş notu (varsa vurgulu kart), "Zili Çalma", "Kapıya Bırak", "Ürün Tükenirse" tercihi (`SUBSTITUTE` / `REFUND`).
  - **Teslimat Modeli:** Gel Al (Pickup) / Platform Kuryesi / İşletme Kendi Kuryesi.
  - **Ürün Kalemleri & Seçilen Opsiyonlar:**
    - Ürün adı, görseli (varsa), adet ve birim fiyatı.
    - Seçilen tüm özelleştirmeler (`options`: grup adı, opsiyon adı, ek tutar, çıkarılan malzemeler).
  - **Fiyatlandırma & Ödeme Özeti:** Ara toplam, teslimat ücreti, kampanya/cüzdan indirimi, ödenecek genel toplam ve ödeme yöntemi (Kredi Kartı / Cüzdan / Kapıda Nakit).
  - **Aksiyonlar:** Durum ilerletme butonları ("Hazırla", "Kuryeye Ver", "Tamamla", "İptal Et") ve "Fiş Yazdır" butonu.

### 2.2. Profesyonel Termal / Mutfak Fişi Yazdırma Sistemi (Thermal POS Print Engine)
- **Yazdırma CSS İzolasyonu (`@media print`):**
  - Sayfadaki diğer tüm HTML elementleri (`body * { visibility: hidden; }`) gizlenecek, sadece `#receipt-print-area` yazıcıya gönderilecektir (`visibility: visible; position: absolute; left: 0; top: 0; width: 80mm;`).
  - Sayfa kenar boşlukları `@page { size: 80mm auto; margin: 0; }` ile optimize edilecektir.
- **Fiş Formatı:**
  - İşletme adı ve Hoppa başlığı
  - Sipariş No & Tarih/Saat
  - Müşteri Adı, Telefon, Adres
  - Varsa Sipariş Notu & Teslimat Tercihi (Örn: "⚠️ Kapıya bırakın, zili çalmayın")
  - Kalem kalem ürünler, adetler ve altlarında girintili özelleştirmeler (`+ Duble Peynir`, `- Soğansız` vb.)
  - Ara Toplam, Teslimat Ücreti, İndirim ve Genel Toplam
  - Ödeme Tipi
  - Fiş altı teşekkür ve Hoppa QR/barkod yerleşimi.

---

## 3. Yapılacak Değişiklikler

### 3.1. Frontend Web Paneli (`apps/web_app`)
- **[orders/index.tsx](file:///c:/Users/tunah/Sources/Hoppa/hoppa/apps/web_app/src/pages/merchant/orders/index.tsx):**
  - `selectedOrderForDetail` state'i eklenerek sipariş detay modalı oluşturulacak.
  - `OrderCard` tıklanabilir hale getirilecek (`onClick={() => setSelectedOrderForDetail(order)}`).
  - `@media print` stil etiketi ve profesyonel 80mm termal fiş şablonu entegre edilecek.
  - Fiş yazdırma fonksiyonu (`handlePrintReceipt`) güvenli ve izole olarak çalıştırılacak.

---

## 4. Doğrulama Protokolü
1. `apps/web_app`: `npx tsc --noEmit` ile TypeScript tip kontrolü.
2. Web panelinde sipariş kartına tıklama, modal içeriği, seçeneklerin listelenmesi ve yazdırma önizlemesinin doğrulanması.

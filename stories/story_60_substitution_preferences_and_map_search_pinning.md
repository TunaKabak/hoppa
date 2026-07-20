# Story #60: Substitution Preferences & Dynamic Map Pinning Search

## Teknik Tasarım ve Kapsam

Bu hikaye, sipariş edilen bir ürünün stokta tükenmesi durumunda kullanıcının tercihini (İade/Benzer Ürün) almayı, bu tercihe göre kampanya iptal riskini ödeme ekranında göstermeyi, ve dükkan/adres konum seçim haritalarına arama özelliği ile gelişmiş pin tasarımları eklemeyi kapsar.

### 1. Veritabanı Değişiklikleri (`schema.prisma`)
* **Yeni Enum:** `SubstitutionPreference`
  - `REFUND`: Ürün sepetten çıkarılsın ve ücreti iade edilsin.
  - `SUBSTITUTE`: Tükenen ürün yerine en yakın benzer ürün gönderilsin.
* **`Order` Tablosuna Yeni Alan:**
  - `substitutionPreference SubstitutionPreference @default(SUBSTITUTE)`

### 2. Backend Geliştirmeleri (`backend`)
* **`OrderController.ts`:**
  - Sipariş oluşturulurken (`createOrder`) istek gövdesindeki `substitutionPreference` alanı okunacak ve `Order` tablosuna kaydedilecek.

### 3. Tüketici Uygulaması (`consumer_app`) Geliştirmeleri
* **`payment_page.dart`:**
  - Ödeme yöntemlerinin hemen altına "Ürün Tükenirse Ne Yapalım?" alanı eklenecek.
  - "İade Edilsin" seçildiğinde, sepetinde aktif kupon veya kampanya bulunan kullanıcılara turuncu renkli bir uyarı kartı gösterilecek: *"Eksilen ürün nedeniyle sepet tutarınız minimum limitin altına düşerse kampanyanız iptal olabilir."*
  - Sipariş oluşturma API isteğine seçilen `substitutionPreference` eklenecek.
* **`add_address_page.dart` (Harita Seçimi):**
  - **Arama Özelliği:** Harita katmanının üstüne OpenStreetMap Nominatim API kullanan bir adres arama çubuğu eklenecek. Seçilen adresin koordinatlarına harita kamerası otomatik kayacak.
  - **Premium Pin Deneyimi:** Pin sürüklenirken zıplama efekti korunacak ancak harita merkezinde sabit bir hedef nokta (hedef halkası ve gölge) bulunacak. Zıplayan pin ile yerdeki hedef halkası arasında kesikli dinamik bir çizgi (dashed line) çizilerek nereye pinleme yapıldığı netleştirilecek. Pin tasarımı modern ve gölgeli bir görünüme kavuşturulacak.

### 4. Esnaf Uygulaması (`merchant_app`) ve Ortak Bileşen Geliştirmeleri
* **`location_picker_page.dart` (Ortak Konum Seçim Sayfası):**
  - Tüketici uygulamasındaki arama özelliği ve premium pin sürükleme animasyonlarının aynısı (hedef noktası, bağlayıcı çizgi, arama çubuğu) buraya da entegre edilecek.
* **Sipariş Hazırlama:**
  - Esnaf sipariş detay ekranında kullanıcının tükenen ürün tercihini ("Benzer Ürün Gönder" veya "İptal Et") net olarak görebilecek.

## Doğrulama Protokolü
* `npx tsc --noEmit` ile backend tip bütünlüğü doğrulanacak.
* `flutter analyze` ile Flutter projelerinin doğrulaması yapılacak.

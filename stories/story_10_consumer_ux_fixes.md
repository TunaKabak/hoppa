Epic: Consumer App User Experience (UX)
Task: Story 10 - Kapalı Dükkan Sepet Engeli ve Adres Sabitleme

DİKKAT (AGENT İÇİN): Bu görev .agent/rules anayasasına tabidir. Her adımı sırayla yap ve flutter analyze ile doğrulamadan diğerine geçme.

ADIM 1: Kapalı Dükkanlar İçin "Sepete Ekle" Engeli

Tüketiciler kapalı bir dükkanın detay sayfasına girebilmeli, ürünleri görebilmeli ANCAK sepete ekleyememelidir.

apps/consumer_app/lib/screens/shop_detail_page.dart (veya dükkan detaylarının / ürünlerin listelendiği sayfa) dosyasını aç.

Dükkanın durumunu (shop.isActive veya shop.isOpen vs. modelinizdeki karşılığı neyse) kontrol et.

Eğer dükkan KAPALIYSA:

Sayfanın en üstüne (AppBar'ın altına) uyarıcı bir banner ekle: "Bu dükkan şu an kapalıdır. Sipariş verilemez." (Arka planı hafif kırmızı/turuncu tonlarında olabilir).

Ürün listesindeki "Sepete Ekle" (Add to Cart) veya "+" butonlarının onPressed metodunu null yaparak butonları devre dışı (disabled) bırak.

Tüketicinin kapalı dükkandan sepete ürün eklemesinin tamamen engellendiğinden emin ol.

ADIM 2: Sipariş Adımında (Checkout) Adres Sabitleme

Ana sayfada (Home) seçilen teslimat adresinin ödeme adımında tekrar değiştirilmesi engellenecek ve doğrudan seçili gelecektir.

apps/consumer_app/lib/screens/cart_page.dart veya checkout_page.dart (Siparişi tamamlama sayfası) dosyasını aç.

Riverpod state'inden (Örn: consumerLocationProvider veya aktif adres state'i hangisiyse) global olarak seçilmiş güncel adresi çek.

Sayfadaki Teslimat Adresi giriş alanını (TextField veya Dropdown) Sadece Okunabilir (Read-Only / Disabled) hale getir.

enabled: false veya readOnly: true özelliklerini kullan.

controller.text değerine globalden çektiğin bu adresi ata.

Adres alanının hemen altına küçük, soluk bir bilgilendirme metni (Helper Text) ekle: "Teslimat adresini değiştirmek için lütfen ana sayfaya dönünüz."

Eğer Riverpod state'inde adres null veya boş ise, kullanıcıyı doğrudan adres seçimi yapması için bir önceki sayfaya/ana sayfaya yönlendir (Siparişi tamamlama butonunu engelle).

ADIM 3: Doğrulama

Değişiklikleri yaptıktan sonra terminalde cd apps/consumer_app && flutter analyze komutunu çalıştır. Hiçbir hata kalmadığından emin ol ve sonucu raporla.
Epic: Merchant Panel & Order Lifecycle
Task: Story 14 - İşletme Teslimat Yönetimi, Sipariş Listeleme ve Ürün Ekleme Özet Kartı

DİKKAT (AGENT İÇİN): Bu görev .agent/rules (Sistem Anayasası) kurallarına sıkı sıkıya tabidir. Adımları sırayla yap, her adımın sonunda belirtilen doğrulama testini geçmeden kesinlikle bir sonraki adıma geçme!

🛠️ ADIM 1: İşletme Panelinde "Gelişmiş Teslimat Ayarları" ve Seçimli Süre

Şu anda işletme sadece serbest metin olarak teslimat süresi giriyor. Bunu kontrol altına alacağız ve Story 13'te DB'ye eklediğimiz teslimat ücret parametrelerini satıcının yönetmesini sağlayacağız.

Merchant App UI Güncellemesi (delivery_settings_tab.dart veya ilgili ayarlar dosyası):

"Teslimat Süresi" alanını serbest yazı alanından çıkarıp bir Dropdown alanına çevir. Sabit seçenekler: 15-30 dk, 30-45 dk, 45-60 dk, 60+ dk.

Sayfaya şu yeni girdi alanlarını ekle (Sadece sayısal girdi kabul etsinler):

Minimum Sepet Tutarı (minimumOrderAmount)

Teslimat Ücretlendirme Tipi (Dropdown: Sabit Ücret veya Mesafeye Göre Kademeli)

Temel Teslimat Ücreti (baseDeliveryFee)

Km Başına Ekstra Ücret (deliveryFeePerKm - Sadece "Mesafeye Göre" seçildiyse gösterilsin)

Ücretsiz Teslimat Limiti (freeDeliveryThreshold - Opsiyonel)

Backend API Entegrasyonu:

PUT /api/merchant/shop/settings (veya dükkan ayarlarını güncelleyen endpoint) kodunu incele.

Gelen bu yeni teslimat parametrelerinin Prisma aracılığıyla Shop tablosuna başarıyla kaydedildiğinden ve validasyonlardan geçtiğinden emin ol.

DOĞRULAMA: - cd backend && npx tsc --noEmit ve cd apps/merchant_app && flutter analyze çalıştır.

📦 ADIM 2: Siparişlerin Listelenmesi ve Durum Yönetimi (Çift Taraflı)

Müşteri siparişi geçtikten sonra siparişin iki tarafta da listelenmesi ve işletme tarafından yönetilmesi gerekmektedir.

Backend Sipariş Endpoint'leri:

GET /api/orders/consumer: Giriş yapmış olan tüketicinin tüm siparişlerini, sipariş kalemleri (OrderItems), ürün isimleri ve dükkan bilgileri (Shop) ile birlikte tarih sırasına göre getirsin.

GET /api/orders/merchant: Giriş yapmış olan satıcının dükkanına ait siparişleri listelesin.

PATCH /api/orders/:id/status: Sipariş durumunu güncelleyen endpoint. Satıcı siparişi PREPARING (Hazırlanıyor), ON_THE_WAY (Yolda), DELIVERED (Teslim Edildi) veya CANCELLED (İptal) durumlarına çekebilsin.

Tüketici Uygulaması (Consumer App - Siparişlerim Sayfası):

Bottom navigation veya Profil menüsüne "Siparişlerim" (order_history_page.dart) sekmesi ekle.

Siparişleri güncel durum kartlarıyla (Örn: Hazırlanıyor - Sarı, Teslim Edildi - Yeşil) listele.

Sayfaya Pull-to-Refresh ekleyerek kullanıcının durumu yenileyebilmesini sağla.

Satıcı Uygulaması (Merchant App - Sipariş Yönetim Ekranı):

Ana ekrana veya bağımsız bir sekmeye "Siparişler" (incoming_orders_page.dart) ekranı ekle.

Yeni düşen siparişler için "Kabul Et" (durumu PREPARING yapar), hazırlanan siparişler için "Kuryeye Ver / Yola Çıkar" (durumu ON_THE_WAY yapar) ve yoldakiler için "Tamamlandı" butonlarını yerleştir.

DOĞRULAMA:

Değişiklikleri tamamladıktan sonra her iki uygulamada da flutter analyze testini hatasız tamamla.

📝 ADIM 3: Ürün Ekleme Sayfası Üst Özet Bilgi Kartı (Merchant App)

Satıcı ürün ekleme sayfasına girdiğinde, işlem yaptığı dükkanın güncel ayarlarını sayfanın en üstünde özet olarak görmelidir.

Merchant App UI Güncellemesi (add_product_page.dart):

Sayfanın en üstüne, form başlamadan önce şık, hafif gri/mavi arka plana sahip bir "Dükkan Özet Bilgi Kartı" (Shop Summary Card) ekle.

Bu kartın içinde şu bilgileri listele:

Dükkan Adı (Örn: "Test Kebap & Lahmacun")

Çalışma Saatleri (Örn: "09:00 - 22:00")

Teslimat Süresi / Ücreti (Örn: "30-45 dk | 30.00 TL Sabit")

Minimum Sepet Limiti (Örn: "Minimum 150.00 TL Sipariş")

Bu verileri, satıcının aktif dükkan state'inden (Örn: shopProvider veya authProvider.shop) çek.

DOĞRULAMA:

flutter analyze ile kodun temiz olduğunu doğrula.

📢 RAPORLAMA

Geliştirmeleri tamamladıktan sonra; yenilenen satıcı ayarları ekran görüntülerini, müşteri ve işletme sipariş yönetim akışının çalışma durumlarını içeren detaylı özeti bana raporla.
Story 14 - Satıcı Yönetimi & Sipariş Takip Entegrasyonu (Onaylandı)

Aşağıdaki geliştirme planı ve mimari tasarım Tech Lead tarafından incelenmiş ve onaylanmıştır. Lütfen adımları sistem kuralları doğrultusunda sırasıyla uygulayınız.

🧭 UX Kararı: Sipariş Geçmişi ve Canlı Takip Konumlandırması

Ana Konum (Sipariş Geçmişi): Tüketici uygulamasında (Consumer App) "Siparişlerim" geçmişi sayfası, kullanıcının Profil / Hesap (Account) sayfası içerisine yerleştirilecek şık bir buton aracılığıyla açılacaktır (order_history_page.dart).

Canlı Sipariş Takip Şeridi (Live Order Tracker Banner): Kullanıcının devam eden, aktif bir siparişi varsa (PENDING, PREPARING, ON_THE_WAY), Ana Sayfa (Home Screen) en üstünde veya en altında persistent (kalıcı), şık bir canlı durum bildirim kartı gösterilecektir. Bu karta tıklandığında kullanıcı doğrudan ilgili siparişin detayına yönlendirilecektir.

🤖 Agent İçin Adım Adım Uygulama Promptu

Aşağıdaki adımları sırasıyla gerçekleştirin ve her adımın sonunda doğrulama testlerini tamamlayın:

⚙️ ADIM 1: Backend API & Prisma Alanlarının Eşlenmesi

ShopController.ts altındaki updateMyShop metodunu güncelle.

Satıcının dükkan ayarlarını güncellerken gönderdiği minimumOrderAmount, deliveryPricingType, baseDeliveryFee, deliveryFeePerKm ve freeDeliveryThreshold alanlarını doğrula ve veritabanına kaydet.

Mevcut minOrderAmount Decimal alanının yeni eklenen minimumOrderAmount ile senkronize (çift taraflı uyumlu) çalıştığından emin ol.

Doğrulama: cd backend && npx prisma db push && npx tsc --noEmit çalıştır.

💼 ADIM 2: Satıcı Uygulaması (Merchant App) Teslimat Ayarları & Ürün Ekleme Özet Kartı

Gelişmiş Ayarlar UI: merchant_settings_page.dart (veya ilgili dükkan ayarları sayfası) dosyasında serbest metin olan teslimat süresini Dropdown yap (15-30 dk, 30-45 dk, 45-60 dk, 60+ dk).

Diğer tüm sayısal teslimat ücretlendirme alanlarını (minimum sepet tutarı, sabit/mesafeli seçim, km ücreti, ücretsiz limit) sayfaya ekle ve API'ye bağla.

Özet Kartı UI: Ürün ekleme sayfasının (add_product_page.dart) en üstüne dükkanın güncel ayarlarını (Dükkan Adı, Çalışma Saatleri, Teslimat Bilgileri, Min Sepet Limiti) içeren şık, hafif arka plana sahip bir Özet Bilgi Kartı yerleştir.

Doğrulama: cd apps/merchant_app && flutter analyze çalıştır.

📦 ADIM 3: Çift Taraflı Sipariş Listeleme ve Durum Yönetimi

Sipariş Endpoint'leri: Backend tarafında GET /api/orders/consumer, GET /api/orders/merchant ve PATCH /api/orders/:id/status endpoint'lerini tamamla.

Tüketici Sipariş Geçmişi: order_history_page.dart sayfasını oluştur. Sipariş durumlarını farklı renklerle (Örn: Hazırlanıyor - Sarı, Teslim Edildi - Yeşil) listele ve Pull-to-Refresh ekle. Profil ekranından bu sayfaya şık bir geçiş yap.

Satıcı Sipariş Yönetimi: merchant_order_list_page.dart sayfasını tasarla. Yeni gelen siparişleri "Kabul Et" (PREPARING), "Yola Çıkar" (ON_THE_WAY) ve "Teslim Edildi" (DELIVERED) butonlarıyla yönetilebilir kıl.

Doğrulama: cd backend && npx tsc --noEmit ve cd apps/consumer_app && flutter analyze ile cd apps/merchant_app && flutter analyze çalıştır.

İşlemler başarıyla tamamlandığında, kod kaliteni ve ekran tasarımlarının son durumunu raporla.
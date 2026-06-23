Epic: Checkout & Category Filtering Bugfixes
Task: Bugfix - Kart Geçerlilik Tarihi, Adres Karışıklığı ve Kategori Eşleme Onarımı

DİKKAT (AGENT İÇİN): Bu görev .agent/rules (Sistem Anayasası) kurallarına tabidir. Mevcut çalışan hiçbir iş mantığını bozmadan sadece belirtilen düzeltmeleri yap ve flutter analyze ile tsc çıktılarının temiz olduğundan emin ol.

🛠️ ADIM 1: Kredi Kartı Son Kullanma Tarihi Validasyonu (Frontend)

Kullanıcının geçmiş tarihli (süresi dolmuş) bir kart girmesi engellenecektir.

apps/consumer_app/lib/screens/checkout/payment_page.dart dosyasını aç.

Son Kullanma Tarihi (_expiryController) TextFormField validator bloğunu bul.

Validator mantığını şu kurallarla güncelle:

Gelen değer boş ise veya formatı uygun değilse (AA/YY formatı, uzunluk < 5) direkt hata dön.

Değeri eğik çizgi (/) karakterine göre ayırarak Ay ve Yıl tam sayılarını elde et.

Eğer Ay değeri 1'den küçük veya 12'den büyükse geçersiz say.

Bugünün tarihini dinamik olarak al (DateTime.now()).

Bugünün yılı (DateTime.now().year % 100 ile son iki haneyi al, örn: 2026 için 26) ve ayını (DateTime.now().month) hesapla.

Eğer girilen yıl bugünün yılından küçükse veya girilen yıl bugünün yılına eşit ama girilen ay bugünün ayından küçükse "Kartın süresi dolmuş" uyarısı döndür.

🏡 ADIM 2: Teslimat Adresi ve Mağaza Adresi Karışıklığının Çözülmesi

Sipariş tamamlandıktan sonra teslimat adresinde mağaza adresinin görünmesi sorunu çözülecektir.

Frontend Kontrolü:

apps/consumer_app/lib/... sipariş oluşturma isteğinin atıldığı repository veya controller dosyasını bul.

Sipariş gönderilirken hazırlanan payload'u incele. deliveryAddress alanına kullanıcının seçtiği adresin (persistent konum state'inden gelen açık adresin) gönderildiğinden ve yanlışlıkla dükkan adresinin set edilmediğinden emin ol.

Backend Kontrolü:

backend/src/controllers/OrderController.ts (veya ilgili Sipariş oluşturma/servis dosyası) dosyasını aç.

Sipariş veritabanına kaydedilirken deliveryAddress kolonu olarak gelen isteğin body'sindeki adresin yazıldığından emin ol. Dükkanın adresinin (shop.address) bu alanın üzerine yazılmasını engelle.

🥛 ADIM 3: Kategori Filtreleme ve Ürün Listeleme Sorunu (Backend & Frontend)

Süt ürününün "Süt" kategorisinde listelenmeme sorunu çözülecektir.

Backend Veri Filtreleme Kontrolü:

backend/src/controllers/ProductController.ts veya ürün listeleme sorgularının atıldığı backend dosyasını aç.

Ürünler kategorilere göre filtrelenirken alt kategori (subCategoryId veya ilgili alan) kontrolünü incele.

Eğer alt kategori filtresi gönderildiyse, Prisma sorgusunda where bloğunun bunu tam olarak eşleştirdiğinden emin ol:

// Örnek Prisma Filtresi
where: {
  categoryId: categoryId || undefined,
  subCategoryId: subCategoryId || undefined, // Bu alanın doğru eşleştiğinden emin ol
  shop: { isActive: true }
}


Frontend Kategori Seçimi Kontrolü:

apps/consumer_app içerisinde dükkan detay veya kategori seçim alanındaki Riverpod provider/controller yapısını incele.

Kullanıcı alt kategorilerden (Örn: "Süt") birini seçtiğinde, API'ye giden istekte doğru alt kategori ID'sinin (subCategoryId parametresi olarak) gönderildiğinden emin ol.

📢 DOĞRULAMA VE TEST

cd backend && npm run build çalıştırarak backend'in hatasız derlendiğini doğrula.

cd apps/consumer_app && flutter analyze çalıştırarak statik analiz uyarılarını temizle.

Yapılan tüm mantıksal düzeltmeleri detaylıca raporla.
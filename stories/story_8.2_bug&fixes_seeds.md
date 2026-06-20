Epic: Checkout, User Experience & Data Integrity
Task: Bugfix - Adres Kaydı, Katalog Görünürlüğü ve Test Verisi (Market) Üretimi

Şu anda sistemde testler sırasında karşılaştığımız 3 temel sorun/ihtiyaç bulunmaktadır. Lütfen aşağıdaki adımları sırayla uygulayarak sistemi onar ve test verilerini zenginleştir:

Sorun 1: Tüketici (Consumer) Adres Kaydetme İşleminin Başarısız Olması

Tüketici uygulamasında AddAddressPage sayfasında veriler girilip "Kaydet" butonuna basıldığında adres kaydedilemiyor.

Frontend "Kaydet" Mantığını İncele:

apps/consumer_app/lib/.../add_address_page.dart dosyasını aç. Eğer burada hala FirebaseFirestore.instance... kullanılıyorsa, bunu DERHAL SİL.

Adres kaydetme işleminin core_network paketindeki ApiClient üzerinden Backend REST API'mize istek attığından emin ol. Gerekirse address_repository.dart ve ilgili Riverpod controller dosyasını güncelle.

Backend API ve Route Kontrolü:

backend/src/controllers/AddressController.ts oluştur/kontrol et ve req.user.id kullanarak Prisma ile Address tablosuna yeni kayıt ekleyen bir metod yaz. Bunu consumerRoutes.ts dosyasına bağla.

Sorun 2: "Test Kebap" Restoranının Katalogda / Yakınımdakiler'de Çıkmaması

Satıcı (Merchant) adresini ve konumunu güncellemesine rağmen, Tüketici (Consumer) uygulamasına girildiğinde dükkan "Yakınımdakiler" veya "Restoranlar" kategorisinde listelenmiyor.

Backend Katalog (Shop) API Kontrolü:

backend/src/controllers/ShopController.ts içindeki getShops metodunu incele.

Eğer lokasyona göre filtreleme (Örn: Haversine formülü ile X km çapındaki dükkanlar) yapılıyorsa, Tüketici uygulamasının kendi Enlem/Boylam (latitude, longitude) değerlerini Query Parameter olarak doğru gönderip göndermediğini kontrol et.

Eğer koordinatlar gelmiyorsa veya eşleşmiyorsa, geçici bir fallback (koordinat yoksa tüm aktif dükkanları getir) mekanizması ekle.

Kategori ve Onay Kontrolü:

Dükkanın isActive: true ve isApproved: true olduğundan emin ol.

Frontend'deki Kategori sekmesi (Restoran/Yemek) ile Backend'deki (Prisma'daki) kategori ID'si veya Enum değerinin eşleştiğini doğrula.

Sorun 3: Market Test Verisi ve Stokların Eklenmesi (Seeding)

Test süreçlerini hızlandırmak için veritabanında otomatik oluşturulmuş bir Market dükkanına ve ürünlerine ihtiyacımız var.

Prisma Seed Güncellemesi:

backend/prisma/seed.ts dosyasını aç.

Mevcut "Test Kebap" dükkanına ek olarak, +905552222222 numaralı yeni bir MERCHANT kullanıcısı oluştur.

Bu kullanıcıya ait name: "Test Süpermarket", category: "MARKET" (Prisma şemana göre uygun kategoriyi seç), address: "Lefkoşa, KKTC", isActive: true, isApproved: true olan bir dükkan oluştur.

Bu marketin altına en az 3 adet test ürünü (Product) ekle (Örn: "1 Litre Su", "Taze Ekmek", "Günlük Süt" - fiyatları ve stok adetleri tanımlanmış şekilde).

Backend dizininde npx prisma db seed komutunu çalıştırarak veritabanını güncelle.

Lütfen bu üç sorunu da uçtan uca çöz ve test edilebilir hale getir. İşlem bittiğinde özellikle 2. adımdaki görünürlük sorununun ana kaynağını (Lokasyon formülü mü, kategori uyuşmazlığı mı vb.) bana kısaca raporla.
Hotfix: Kritik Güvenlik, DB İlişkisi Onarımı ve GMT+3 Zaman Dilimi Kararlılığı

Bu görev; sahada tespit edilen dükkan açılış saatleri, adres ilişkisel veri tabanı çökmesi, sipariş güncelleme kilitlenmesi, favori ürünler ve ödeme iptal mekanizmalarına yönelik 1. derece acil düzeltmeleri içerir.

🚨 1. ADIM: Adres Silme Hatasının Onarılması (DB Foreign Key Constraint Violation)

Sorun: Kullanıcı profilinden bir adresi sildiğinde, eğer o adres ID'si (addressId) geçmişte verilmiş bir siparişte (Order tablosu) kayıtlıysa, PostgreSQL ilişkisel bütünlük gereği foreign key constraint violated hatası fırlatır (500 Server Error).

Mühendislik Çözümü (Decoupling): Sipariş geçmişindeki adres verileri tarihsel kayıtlardır ve asla değişmemelidir. Bu yüzden Order tablosunda adresi bir ID'ye bağlamak yerine, sipariş anında kullanıcının o anki adres bilgilerini (Açık Adres, Bina No, Kat, Koordinat vb.) bir String/JSON snapshot olarak doğrudan deliveryAddress kolonuna yazacağız.

Böylece kullanıcı kendi profilinden o adresi silse dahi geçmiş siparişler kırılmayacaktır.

Yapılacaklar:

Order modelindeki addressId ilişkisini gevşet veya sil. Sipariş kaydedilirken adresi düz metin veya JSON string olarak deliveryAddress kolonuna yazacak şekilde backend'deki OrderController.ts dosyasını güncelle.

Address tablosundaki silme metoduna soft-delete (isDeleted: true) ekle veya ilişkileri kontrol ederek delete işlemini güvenli hale getir.

🕒 2. ADIM: GMT+3 Zaman Dilimi Kararlılığı (Dükkan Açık/Kapalı Kontrolü)

Sorun: Render sunucuları UTC saat dilimindedir. Türkiye/Kıbrıs ise kalıcı olarak GMT+3 zaman dilimindedir. new Date() sorgusu yapıldığında sunucu saati 3 saat geriden geldiği için dükkan kapalı olması gerekirken açık görünmektedir.

Çözüm: Backend tarafında dükkanın açık olup olmadığını kontrol eden algoritmaya GMT+3 zaman dilimi kaydırmasını (timezone offset adjustment) ekle.

Güvenli Kod Standartı:

const now = new Date();
// Zamanı Türkiye/Kıbrıs (GMT+3) saat dilimine göre formatla
const gmt3Time = new Date(now.toLocaleString("en-US", { timeZone: "Europe/Istanbul" }));
const currentHour = gmt3Time.getHours();
const currentMinute = gmt3Time.getMinutes();


Bu dönüşüm kullanılarak dükkanın açılış/kapanış saat aralıkları (08:00 - 22:00) kontrol edilmeli, eğer saat aralığı dışındaysa sipariş oluşturma işlemi backend seviyesinde de engellenmelidir.

🔄 3. ADIM: Satıcı Sipariş Güncelleme Kilitlenmesinin Çözülmesi ve Riverpod Yenilenmesi

Sorun: Satıcı "Onayla" dediğinde uygulamanın tepki vermemesi, backend'in durum güncelleme sonrasında başarılı yanıt dönmemesinden veya frontend tarafında Riverpod state'inin güncellenen sipariş durumunu algılayıp arayüzü tetiklememesinden (rebuild etmemesinden) kaynaklanır.

Çözüm:

backend/src/controllers/OrderController.ts içindeki PATCH /api/orders/:id/status endpoint'ini doğrula. Durum değişiminden sonra güncel sipariş objesini JSON olarak geri döndürdüğünden emin ol.

Satıcı uygulamasındaki merchant_order_list_page.dart dosyasını incele. Durum güncelleme isteği başarıyla döndüğünde ref.invalidate(merchantOrdersProvider) (veya ilgili sipariş provider'ı) çağrısını yaparak listeyi otomatik yenilet.

🎨 4. ADIM: Sipariş Listesi Detaylarının Zenginleştirilmesi (Frontend & Backend)

Çözüm: Hem Tüketici hem Satıcı sipariş listesi kartlarına şu detayları şık bir biçimde yerleştir:

Sipariş edilen kalemlerin isimleri ve miktarları (Örn: "2x Adana Kebap, 1x Ayran")

Ödeme Tipi (Kredi/Banka Kartı, Kapıda Nakit vb.)

Müşterinin sipariş notu (varsa)

Siparişin veriliş saati ve tahmini teslimat süresi.

📍 5. ADIM: Teslimat Haritasında Poligon Bölge Seçeneği (UI İyileştirmesi)

Çözüm: merchant_settings_page.dart teslimat haritasına iki modlu seçim yapısı ekle:

Dairesel Limit (Mesafe bazlı): Satıcı bir yarıçap belirler (Örn: 3 km).

Özel Bölge Sınırı (Poligon): Satıcı harita üzerinde tıklayarak dükkanının teslimat yapacağı sınırları bir poligon (alan) olarak çizebilir. Bu poligon koordinatlarını array olarak kaydedebileceği bir altyapı sun.

⭐ 6. ADIM: Tüketici Favorilerim Ekranı Onarımı

Sorun: "Favorilerim" ekranında hiçbir favori ürünün listelenmemesi.

Çözüm: apps/consumer_app içerisindeki favori ekranı controller'ını incele. Favoriye eklenen ürünlerin ID'lerine göre veritabanından güncel ürün bilgilerini join ederek çektiğinden ve arayüze doğru şekilde listelediğinden emin ol.

📢 DOĞRULAMA PLANI

cd backend && npx tsc --noEmit çalıştırılarak hata olmadığından emin olunacak.

apps/consumer_app ve apps/merchant_app üzerinde flutter analyze çalıştırılarak statik analiz doğrulaması yapılacak.
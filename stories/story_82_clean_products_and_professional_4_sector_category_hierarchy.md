# Story 82: Profesyonel Ürün/Görsel Temizliği ve 4 Ana Sektör (Market, Restoran, Su, Çiçek) Hiyerarşik Kategori Mimarisi

## 1. Genel Bakış ve Amaç
Hoppa platformundaki tüm test ürünleri, geçici görseller ve eski karmaşık ürün kayıtları temizlenecek; platformun 4 ana operasyonel sektörü (**Market, Restoran, Su, Çiçek**) için profesyonel, sektörel standartlara ve modern e-ticaret/hızlı teslimat normlarına (Migros, Getir, Yemeksepeti vb.) tam uyumlu **Kategori ve Alt Kategori Ağacı** sıfırdan ve eksiksiz inşa edilecektir.

---

## 2. Kapsam ve 4 Ana Sektör Kategori Mimarisi

### 2.1. 🛒 1. MARKET (Süpermarket & Hızlı Market) - `shopType: "MARKET"`
1. **Meyve & Sebze**
   - *Alt Kategoriler:* Taze Meyveler, Taze Sebzeler, Yeşillikler & Otlar, Egzotik Meyveler, Organik & Doğal
2. **Süt & Kahvaltılık**
   - *Alt Kategoriler:* Süt & Yoğurt, Peynir Çeşitleri, Yumurta, Tereyağı & Margarin, Zeytin & Reçel & Bal, Kahvaltılık Gevrek & Ezmeler
3. **Fırın & Unlu Mamuller**
   - *Alt Kategoriler:* Ekmek Çeşitleri, Simit & Poğaça & Börek, Paket Ekmekler & Lavaş, Unlu Tatlılar
4. **Et, Tavuk & Şarküteri**
   - *Alt Kategoriler:* Kırmızı Et (Dana/Kuzu), Beyaz Et (Tavuk/Hindi), Salam & Sucuk & Sosis, Pastırma & Kavurma, Deniz Ürünleri
5. **Temel Gıda & Bakliyat**
   - *Alt Kategoriler:* Pirinç & Bulgur & Bakliyat, Sıvı Yağlar & Zeytinyağı, Makarna & Erişte, Un & İrmik & Şeker & Tuz, Salça & Konserve & Soslar
6. **Atıştırmalık & Tatlı**
   - *Alt Kategoriler:* Çikolata & Gofret, Bisküvi & Kek, Cips & Çerez, Şekerleme & Sakız, Dondurma
7. **İçecekler**
   - *Alt Kategoriler:* Gazlı İçecekler, Su & Maden Suyu, Meyve Suyu & Soğuk Çay, Çay & Kahve, Ayran & Kefir & Şalgam
8. **Donuk & Hazır Gıda**
   - *Alt Kategoriler:* Dondurulmuş Sebze & Meyve, Hazır Yemekler & Pizza & Hamur, Donuk Et & Balık
9. **Deterjan & Ev Temizliği**
   - *Alt Kategoriler:* Çamaşır Yıkama, Bulaşık Yıkama, Ev & Yüzey Temizleyiciler, Kağıt Ürünleri, Oda Kokusu & Temizlik Gereçleri
10. **Kişisel Bakım & Kozmetik**
    - *Alt Kategoriler:* Şampuan & Saç Bakımı, Duş Jeli & Sabun, Ağız & Diş Bakımı, Tıraş & Deodorant, Cilt & Vücut Bakımı
11. **Bebek Dünyası**
    - *Alt Kategoriler:* Bebek Bezi & Islak Mendil, Bebek Maması & Ek Gıda, Bebek Bakım & Şampuan
12. **Evcil Hayvan**
    - *Alt Kategoriler:* Kedi Maması & Kumu, Köpek Maması & Ödüller, Kuş & Kemirgen Yemleri

---

### 2.2. 🍔 2. RESTORAN / YEMEK (Yemek & Restoran Menüleri) - `shopType: "RESTAURANT"`
1. **Burger & Sandviç**
   - *Alt Kategoriler:* Gurme Burgerler, Tavuk Burgerler, Sandviç & Tost, Mini / Slider Burgerler
2. **Pizza & İtalyan**
   - *Alt Kategoriler:* Klasik Pizzalar, Gurme / Özel Pizzalar, Makarnalar & Penne, Calzone & Focaccia
3. **Kebap, Döner & Izgara**
   - *Alt Kategoriler:* Dürüm Döner & Porsiyon Döner, Adana & Urfa Kebap, Tavuk Şiş & Kanat, Köfte & Karışık Izgara
4. **Pide & Lahmacun**
   - *Alt Kategoriler:* Lahmacunlar, Kıymalı & Kaşarlı Pideler, Kuşbaşılı Pide, Trabzon / Kapalı Pide
5. **Ev Yemekleri & Çorbalar**
   - *Alt Kategoriler:* Günün Çorbaları, Sulu & Zeytinyağlı Yemekler, Pilavlar & Makarnalar, Meze & Yan Ürünler
6. **Salata & Sağlıklı Beslenme**
   - *Alt Kategoriler:* Fit / Diyet Salatalar, Tavuklu & Ton Balıklı Salata, Bowl & Sağlıklı Tabaklar, Detoks İçecekleri
7. **Dünya Mutfağı & Sokak Lezzetleri**
   - *Alt Kategoriler:* Taco & Meksika, Noodle & Asya, Çıtır Tavuk Kovaları, Çiğ Köfte & Dürümler
8. **Tatlılar & Waffle**
   - *Alt Kategoriler:* Waffle & Krep, Şerbetli Tatlılar & Baklava, Sütlü Tatlılar & Cheesecake, Sufle & Pasta
9. **Kafe, İçecek & Kahve**
   - *Alt Kategoriler:* Sıcak & Soğuk Kahveler, Taze Sıkma Meyve Suları, Milkshake & Smoothie, Meşrubatlar

---

### 2.3. 💧 3. SU & İÇECEK (Damacana, Maden Suyu & Toptan İçecek) - `shopType: "WATER"`
1. **Damacana Su**
   - *Alt Kategoriler:* 19L Polikarbon Damacana, 15L / 19L Cam Damacana, Boş Damacana Değişimi
2. **Pet Şişe & Çoklu Paketler**
   - *Alt Kategoriler:* 0.33L & 0.5L Koli Su, 1.5L & 5L Su Paketleri, 10L Pratik Su
3. **Doğal Maden Suyu & Soda**
   - *Alt Kategoriler:* Sade Doğal Maden Suyu, Meyve Aromalı Maden Suyu, Gazoz & Tonik
4. **Koli & Toptan Meşrubat**
   - *Alt Kategoriler:* Koli Gazlı İçecekler, Koli Meyve Suyu & Soğuk Çay, Koli Ayran & İçecekler
5. **Su Pompası & Ekipmanlar**
   - *Alt Kategoriler:* Manuel El Pompası, Şarjlı / Otomatik Damacana Pompası, Su Sebili & Aksesuarlar

---

### 2.4. 🌹 4. ÇİÇEK & HEDİYE (Tasarım Çiçekler, Bitkiler & Hediyelik) - `shopType: "FLOWER"`
1. **Tasarım Buketler**
   - *Alt Kategoriler:* Gül Buketleri, Papatya & Kır Çiçekleri, Lilyum & Şakayık, Karışık Tasarım Buketler
2. **Saksı Çiçekleri & İç Mekan Bitkileri**
   - *Alt Kategoriler:* Orkide Çeşitleri, Sukulent & Kaktüs, Barış Çiçeği & Bonsai, Salon Bitkileri
3. **Kutuda & Vazoda Çiçekler**
   - *Alt Kategoriler:* Silindir Kutuda Güller, Cam Vazoda Aranjmanlar, Işıklı / Özel Ahşap Kutulu Çiçekler
4. **Hediye & Özel Gün Setleri**
   - *Alt Kategoriler:* Çikolatalı Çiçek Sepetleri, Peluş Oyuncak & Çiçek, Doğum Günü & Tebrik Setleri, Hediye Kartları
5. **Kurutulmuş & Solmayan Çiçekler**
   - *Alt Kategoriler:* Şoklanmış Solmayan Güller, Kuru Çiçek Aranjmanları, Teraryum Tasarımları

---

## 3. Veritabanı Temizleme ve Seeding Protokolü
1. **Eski Verilerin Temizlenmesi:**
   - `ProductOptionGroup`, `ProductOption`, `Product`, `GlobalProduct` tablolarındaki tüm eski test kayıtları silinecek.
   - Eski/çakışan `Category` kayıtları temizlenecek.
2. **Yeni Kategori Ağacının Tohumlanması:**
   - 4 ana sektör için tüm ana ve alt kategoriler hiyerarşik `parentId` ilişkileriyle veritabanına yazılacak.
   - Her ana kategori için modern ikon ve estetik renk paleti tanımlanacak.
3. **Doğrulama:**
   - `npx prisma db seed` ve `npx tsc --noEmit` başarıyla geçecek.

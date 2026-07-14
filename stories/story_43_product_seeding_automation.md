# Story 43: Market ve Restoran Ürünleri Otomasyonu (100+ Gerçek Resimli Ürün)

## 🎯 1. KULLANICI HİKAYESİ (USER STORY)

"Bir Hoppa yöneticisi olarak; uygulamamızı test ederken, gösterim yaparken ve kullanıcı deneyimini iyileştirirken hem Market hem Restoran kategorilerinde bol miktarda ve gerçek resimli ürünlerin olmasını istiyorum. Bu amaçla, hem market hem de restoran dükkanlarımıza en az 100'er adet gerçek görseli olan ürün ekleyecek bir tohumlama (seeding) otomasyonunun hazırlanmasını istiyorum."

---

## 🛠️ 2. TEKNİK TASARIM VE İŞ MANTISI (TECHNICAL DESIGN)

### A. Otomasyon Çözüm Yaklaşımı
* `backend/prisma/` altında `seed_real_data.ts` isminde yeni bir tohumlama betiği (script) hazırlanacaktır.
* Bu betik, `package.json` dosyasına bir script (`npm run seed:real-data`) olarak eklenecek ve tek bir komutla çalıştırılabilir olacaktır.
* Betik, veritabanındaki mevcut kategori ve ölçü birimi (Unit) yapısını koruyarak çalışacaktır.

### B. Hedef Dükkanlar (Target Shops)
1. **Market Dükkanı:**
   * Mevcut dükkan: `Test Süpermarket` (type: `MARKET`, id: `75add0fc-ee26-4082-bf68-430dd57e7d34`)
   * Sahibi: `market@test.com` (businessName: `Test Süpermarket`)
2. **Restoran Dükkanı:**
   * Mevcut dükkan: `Test Süpermarket` (type: `RESTAURANT`, id: `666d363f-5325-48b2-ad8d-ba7f09e9067b`)
   * Bu dükkanın adı kafa karışıklığını önlemek için `"Test Kebap & Lahmacun"` olarak güncellenecektir (Merchant adı da zaten `Test Kebap & Lahmacun`'dur).

### C. Ürün Verisi ve Gerçek Görseller
1. **Market Ürünleri (100+ Adet):**
   * Süt & Kahvaltılık, Atıştırmalık, Temel Gıda, Fırın, İçecekler ve Temizlik kategorilerinde popüler Türk market ürünleri seçilecektir.
   * Her ürün için gerçek ve yüksek kaliteli Unsplash/Migros görsel bağlantıları (URL) tanımlanacaktır.
2. **Restoran Ürünleri (100+ Adet):**
   * Kebaplar & Izgaralar, Pide & Lahmacun, Pizza & Fast Food, Ev Yemekleri & Çorbalar, Tatlılar ve İçecekler kategorilerinde Türk ve dünya mutfağından zengin bir menü hazırlanacaktır.
   * Her yemek için gerçeğe uygun, iştah açıcı ve yüksek çözünürlüklü Unsplash gıda görsel bağlantıları kullanılacaktır.

### D. Veri Modeli Uyumluluğu
* Eklenen ürünler hem `GlobalProduct` (merkezi katalog) hem de `Product` (dükkana özel ürün ezmeleri) tablolarına yazılacaktır.
* `discountRate` alanları rastgele veya önceden belirlenmiş oranlarda (%0 - %25) ayarlanarak indirimli ürün filtrelerinin de test edilmesi sağlanacaktır.
* `price` ve `regularPrice` alanları tutarlı şekilde (indirim varsa `regularPrice > price`, yoksa `regularPrice == price`) hesaplanacaktır.

---

## 📢 3. ADIM ADIM DOĞRULAMA VE ÇALIŞTIRMA PLANI

1. **Prisma Şema ve Bütünlük Kontrolü:**
   ```bash
   npx prisma generate
   ```
2. **Otomasyon Scriptini Çalıştırma:**
   ```bash
   npm run seed:real-data
   ```
3. **Ürün Sayısı Doğrulama:**
   * `check_db_js.js` betiği güncellenerek dükkanlardaki ürün sayıları ve görsel durumları doğrulanacaktır.

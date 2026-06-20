# Hoppa E2E Canlı Test Planı (E2E Live Test Plan)

Bu döküman, Hoppa uygulamasının hem Satıcı (Merchant - Tablet/Emülatör) hem de Tüketici (Consumer - Telefon/Emülatör) uygulamalarının fiziksel cihazlar üzerinde birbiriyle entegre şekilde test edilmesi için adım adım kılavuz sağlar.

---

## 🛠️ Bölüm 0: Hazırlık & Ağ Bağlantıları

Fiziksel cihazların veya emülatörlerin yerel geliştirme sunucunuzla (Local Host) haberleşebilmesi ve veritabanı bağlantılarının doğrulanması için aşağıdaki adımları uygulayın.

### 1. ADB Port Yönlendirme (TCP Reverse)
Uygulamaların yerel ağdaki Node.js API sunucunuza (port `3000`) erişebilmesi için USB hata ayıklama modu açık olan cihazlarınızı bilgisayara bağlayın ve aşağıdaki komutları çalıştırın:

```bash
# 1. Tüketici (Consumer) Cihazı için port yönlendirme:
adb -s <consumer_device_id> reverse tcp:3000 tcp:3000

# 2. Satıcı (Merchant) Cihazı için port yönlendirme:
adb -s <merchant_device_id> reverse tcp:3000 tcp:3000
```
> [!TIP]
> Tek cihaz bağlıysa doğrudan `adb reverse tcp:3000 tcp:3000` komutunu çalıştırmanız yeterlidir.

### 2. Supabase / Prisma Bağlantı Teyidi
Backend sunucusunun Supabase remote veritabanına bağlı olduğunu doğrulamak için `backend/.env` dosyanızda şu alanların doğru şekilde Supabase URI'larını işaret ettiğinden emin olun:
- `DATABASE_URL` (Supabase Transaction Connection Pooling URI)
- `DIRECT_URL` (Supabase Direct Connection URI)

---

## 🏬 Senaryo 1: Onboarding ve Dükkan Aktivasyonu

Bu senaryo, yeni satıcıların sisteme katılımını (Lazy Onboarding) ve eksik bilgileri tamamlayarak dükkanlarını aktif hale getirme süreçlerini test eder.

### Adım Adım Akış:
1. **Satıcı Kaydı (Register):** Satıcı uygulamasını açın ve "Yeni Dükkan Kaydı" sayfasına gidin. Temel bilgileri (E-posta, şifre, işletme adı) doldurarak kaydı tamamlayın.
2. **Lazy Onboarding Kısıtlaması (Durum Kontrolü):**
   - Kayıt sonrası ana panelde dükkanı aktif etmek için düğmeyi (`isActive` switch) kaydırmaya çalışın.
   - Sistem, **"Eksik dükkan bilgileri bulunuyor (VKN, Adres vb.). Lütfen profilden tamamlayın."** uyarısını vermeli ve aktivasyona izin vermemelidir.
3. **Bilgilerin Tamamlanması:**
   - Ayarlar/Profil sayfasına gidin.
   - Şirket Kayıt Numarası (MS Number), Vergi Numarası (VKN/Tax Number), Telefon Numarası, İlçe ve Açık Adres alanlarını doldurup kaydedin.
4. **Dükkan Aktivasyonu:**
   - Bilgileri kaydettikten sonra ana panele dönüp dükkanı aktif etme anahtarını açın.
   - Switch'in başarıyla aktif olduğunu (`isActive: true`) ve dükkanın sipariş alabilir duruma geçtiğini doğrulayın.

---

## 🛒 Senaryo 2: Katalog ve "Altın Kural" (Single Shop Basket)

Bu senaryo, tüketicilerin yalnızca tek bir dükkandan ürün ekleyebilmesi kuralını (Altın Kural) ve farklı dükkandan ürün ekleme durumunda tetiklenen onay mekanizmasını test eder.

### Adım Adım Akış:
1. **Dükkan A'dan Ürün Ekleme:**
   - Tüketici uygulamasını açın ve aktif olan **Dükkan A** kataloğuna girin.
   - Sepete 1 veya daha fazla ürün ekleyin. Sepet badge'inde ürün sayısının ve toplam fiyatın güncellendiğini teyit edin.
2. **Dükkan B'ye Geçiş ve Ürün Ekleme Teşebbüsü:**
   - Geri dönüp listeden **Dükkan B** kataloğuna giriş yapın.
   - Herhangi bir ürünü sepete eklemek için "+" butonuna basın.
3. **Altın Kural UX Onay Dialogu Kontrolü:**
   - Ekranda şu içerikle bir `AlertDialog` belirlemelidir:
     - **Başlık:** *Farklı Dükkan*
     - **Mesaj:** *"Sepetinizde başka bir dükkana ait ürünler var. Sepeti temizleyip bu dükkandan devam etmek ister misiniz?"*
     - **Butonlar:** *"İptal"* ve *"Sepeti Temizle ve Ekle"*
4. **Senaryo Dallanmaları:**
   - **İptal:** Butona basıldığında dialog kapanmalı, sepet değişmemeli (Dükkan A ürünleri korunmalı) ve yeni ürün sepete eklenmemelidir.
   - **Sepeti Temizle ve Ekle:** Butona basıldığında Dükkan A'ya ait tüm eski ürünler temizlenmeli, sepet sıfırlanmalı ve Dükkan B'den seçilen yeni ürün sepete başarıyla eklenmelidir.

---

## 💳 Senaryo 3: Mükerrer Sipariş (Double Submit) Koruması & Başarılı Ödeme

Bu senaryo, siparişin backend API aracılığıyla Supabase veritabanına atomik olarak yazılmasını ve ağ gecikmelerinde mükerrer işlem yapılmasını engelleyen kullanıcı arayüzü korumalarını test eder.

### Adım Adım Akış:
1. **Sepet Onayına Geçiş:**
   - Tüketici uygulamasında sepeti açın. Minimum sepet tutarı sağlandıysa "Sepeti Onayla" butonuna basın.
   - Adres ve İletişim bilgilerini seçerek "Ödemeye Geç" aşamasına gelin.
2. **Sipariş Notu ve Ödeme Seçimi:**
   - Sipariş notu alanına test için bir açıklama yazın. Kapıda Nakit/Kart seçeneklerinden birini seçin.
3. **Double Submit Koruması (Loading State):**
   - **"Siparişi Tamamla"** butonuna basın.
   - Butona basıldığı anda:
     - Buton metninin yerine bir `CircularProgressIndicator` (yükleme göstergesi) gelmelidir.
     - Buton tıklanamaz (disabled) hale gelmeli ve kullanıcının art arda tıklayarak iki kez sipariş oluşturması engellenmelidir.
4. **Veritabanı (Prisma $transaction) Teyidi:**
   - API isteği başarıyla döndüğünde Supabase veritabanını (Prisma Studio veya SQL editörü ile) kontrol edin:
     - `Order` tablosunda yeni bir satır oluştuğunu, `deliveryAddress` alanında teslimat adresinin anlık snapshot'ının (`Başlık: Adres detayları...`) doğru yazıldığını teyit edin.
     - `OrderItem` tablosunda sipariş kalemlerinin, birim fiyatlarının ve miktarlarının `Order` ile ilişkili biçimde eksiksiz oluşturulduğunu teyit edin.
5. **Sipariş Sonrası Temizlik:**
   - Sipariş tamamlandıktan sonra uygulamanın ana sayfaya döndüğünü ve yerel sepetin otomatik olarak sıfırlandığını (badge'in temizlendiğini) doğrulayın.

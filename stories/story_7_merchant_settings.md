Epic: Merchant App Settings (Satıcı Ayarları)
Task: Story 7 - Adres Alanının Teslimat Sekmesine Taşınması ve GPS Entegrasyonu

Kullanıcı Hikayesi: "Bir satıcı olarak, dükkanımın fiziksel adresini Profil sekmesinde değil Teslimat sekmesinde görmek ve bu adresi uzun uzun yazmak yerine 'Konumum' butonuna basarak (veya otomatik olarak) cihazımın mevcut GPS konumundan çekmek istiyorum."

Bu görevde hem UI mimarisini düzenleyeceğiz hem de geolocator ve geocoding kütüphanelerini kullanarak Merchant App (Satıcı Uygulaması) içerisinde konum yeteneklerini geliştireceğiz. Lütfen aşağıdaki adımları sırayla uygula:

1. UI Düzenlemesi: Adresi Profilden Teslimata Taşıma

apps/merchant_app/lib/... dizininde Satıcı "Profil" ayarları sayfasını (örn: profile_settings_tab.dart veya shop_profile_page.dart) bul. İçerisindeki "Dükkan Adresi" (TextField ve ilgili state/controller logic) kısmını TAMAMEN KALDIR.

Satıcı "Teslimat" ayarları sayfasını (örn: delivery_settings_tab.dart) bul ve bu Adres alanını buraya EKLE.

2. Kütüphanelerin Eklenmesi ve İzin (Permission) Ayarları

apps/merchant_app dizininde terminali açıp paketleri ekle: flutter pub add geolocator geocoding

Android: apps/merchant_app/android/app/src/main/AndroidManifest.xml dosyasına şu izinleri ekle:
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

iOS: apps/merchant_app/ios/Runner/Info.plist dosyasına şu anahtarı ekle:
<key>NSLocationWhenInUseUsageDescription</key>
<string>Dükkanınızın adresini otomatik belirleyebilmemiz için konum izninize ihtiyacımız var.</string>

3. Location Service ve Riverpod Provider Kurulumu

merchant_app içerisinde uygun bir dizine (örn: controllers veya services) merchant_location_controller.dart oluştur.

İçerisinde şu işlemleri yapan bir AsyncNotifier (Örn: merchantLocationProvider) yaz:

Geolocator.checkPermission() ve Geolocator.requestPermission() ile cihaz izinlerini kontrol et.

İzin verildiyse Geolocator.getCurrentPosition() ile enlem ve boylamı al.

placemarkFromCoordinates(lat, lng) metodunu kullanarak bu koordinatları açık adrese çevir (Sokak, Mahalle, İlçe, Şehir) ve String olarak döndür.

4. Teslimat Sekmesi GPS Entegrasyonu (UX Detayları)

"Teslimat" sekmesindeki yeni Adres TextField'ının yanına (veya suffixIcon olarak) bir "Konumum" (Icons.my_location) butonu ekle.

Sayfa ilk açıldığında eğer dükkan adresi alanı boşsa, otomatik olarak konum çekme işlemini tetikle.

Konum aranırken butonun yerinde (veya text field içinde) küçük bir CircularProgressIndicator göster.

Konum başarıyla bulunduğunda, TextField'ın içeriğini otomatik olarak bu bulunan adres ile doldur (Satıcı dilerse sonradan manuel müdahale edip düzeltebilsin).

Kullanıcı konum izni vermezse veya hata oluşursa, TextField boş kalsın ve Snackbar ile "Konum alınamadı, lütfen adresi manuel giriniz veya seçiniz." uyarısı göster.

Lütfen bu geliştirmeyi tamamla. İşlem bitince native (Android/iOS) tarafında izinleri güncellediğini ve kodun statik analizden (flutter analyze) hatasız geçtiğini raporla.
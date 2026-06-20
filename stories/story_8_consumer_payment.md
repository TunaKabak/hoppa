Epic: Checkout & User Experience (Ödeme ve Kullanıcı Deneyimi)
Task: Story 8 - Consumer App Otomatik Konum Bulma ve Adres Entegrasyonu

Kullanıcı Hikayesi: "Bir tüketici olarak, sipariş verirken adresimi uzun uzun yazmak yerine 'Konumumu Bul' butonuna basarak cihazımın mevcut GPS konumunun otomatik olarak açık adrese dönüştürülmesini istiyorum."

Merchant uygulamasında edindiğimiz tecrübeleri Consumer (Tüketici) uygulamasına entegre edeceğiz. Lütfen apps/consumer_app dizininde aşağıdaki adımları sırayla uygula:

1. İzin (Permission) ve Kütüphane Ayarları

consumer_app/pubspec.yaml dosyasına geolocator ve geocoding paketlerinin eklendiğinden emin ol.

Android: consumer_app/android/app/src/main/AndroidManifest.xml dosyasına şu izinleri ekle (Eğer yoksa):
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

iOS: consumer_app/ios/Runner/Info.plist dosyasına şu anahtarı ekle:
<key>NSLocationWhenInUseUsageDescription</key>
<string>Siparişinizi size en hızlı şekilde ulaştırabilmemiz için konum izninize ihtiyacımız var.</string>

2. Konum Servisi ve "Unnamed Road" Filtresi

lib/src/features/orders/presentation/controllers/ (veya ilgili dizin) altına consumer_location_controller.dart oluştur.

İçerisinde AsyncNotifier veya FutureProvider kullanarak bir konum sağlayıcı (consumerLocationProvider) yaz:

Geolocator.checkPermission() ve requestPermission() işlemlerini yap.

İzin varsa Geolocator.getCurrentPosition() ile koordinatları al.

placemarkFromCoordinates ile açık adresi oluştururken; Eğer sokağın (placemark.thoroughfare veya street) içinde "Unnamed Road" geçiyorsa, bu kısmı yoksay. Önceliği Semt ve Şehre ver. (Örn: ${placemark.subLocality}, ${placemark.locality}).

3. Sepet / Ödeme (Checkout) UI Entegrasyonu

Tüketici uygulamasındaki sipariş tamamlama sayfasını (cart_page.dart veya payment_page.dart) aç.

deliveryAddress'in girildiği TextField'ın yanına veya içine (suffixIcon olarak) bir "Konumumu Bul" (Icons.my_location) butonu ekle.

UX Detayları:

Sayfa açıldığında otomatik konum çekmeyi DENEME (Tüketici kayıtlı adresini kullanmak isteyebilir). Sadece butona basıldığında konumu çek.

Konum aranırken butonun yerinde CircularProgressIndicator göster.

Konum başarıyla bulunduğunda TextField'ın içeriğini güncel adres ile doldur (Üzerinde manuel değişiklik yapabilsin).

Konum izni reddedilirse veya hata olursa kullanıcıya SnackBar ile "Konum alınamadı, lütfen manuel giriniz." mesajı göster.

Lütfen bu geliştirmeyi tamamla. İşlem bitince native (Android/iOS) tarafında izinleri güncellediğini ve kodun statik analizden (flutter analyze) hatasız geçtiğini raporla.
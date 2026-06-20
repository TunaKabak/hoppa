Epic: Merchant App Settings (Satıcı Ayarları)
Task: Bugfix - Ayarlar Sayfasından Kalan Firebase Bağımlılıklarının Temizlenmesi

Sorun: Satıcı uygulamasında "Ayarlar" menüsüne tıklandığında W/Firestore: [WatchStream] Stream closed hatası alınıyor. Projemizi REST API + Supabase yapısına geçirdiğimiz için bu sayfada unutulan eski Firebase Firestore kodları sayfanın çökmesine neden oluyor.

Lütfen apps/merchant_app dizininde şu adımları uygula:

Dosya Tespiti: Satıcı "Ayarlar", "Profil" veya "Teslimat" sekmelerini barındıran dosyaları (settings_page.dart, profile_tab.dart, delivery_settings_tab.dart vb.) bul.

Firebase Temizliği: Bu dosyalardaki tüm cloud_firestore veya firebase_core importlarını SİL.

StreamBuilder Temizliği: Eski StreamBuilder veya FirebaseFirestore.instance.doc().snapshots() gibi veri dinleme yapılarını tamamen kaldır.

Riverpod Entegrasyonu: Eğer sayfada satıcı/dükkan verisi (isim, adres vb.) gösterilmesi gerekiyorsa, bunu REST API'mize bağlı olan Riverpod provider'ları (Örn: shopProvider veya authProvider) üzerinden ref.watch ile alacak şekilde refactor et.

Statik Analiz: flutter analyze çalıştırarak hiçbir Firebase kalıntısı veya derleme hatası kalmadığından emin ol.

Lütfen bu temizliği yap ve uygulamanın Ayarlar sayfasının hatasız açıldığını onayla.
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Uygulamanın genel yapılandırma ve çevre değişkenlerini yöneten sınıf.
/// SRP (Single Responsibility Principle) gereği sadece konfigürasyondan sorumludur.
class AppConfig {
  // Uygulama sadece lokalde çalışacağı için şimdilik hep false kabul ediliyor.
  static const bool isProduction = false;

  /// Flutter'ın çalıştığı platformu tespit edip doğru lokal IP'yi döndürür.
  static String get localHostIp {
    // Web platformunda çalışıyorsa (Platform.is... çağrıları web'de hata fırlatır)
    if (kIsWeb) {
      return "127.0.0.1";
    }

    // Web değilse, işletim sistemini kontrol edebiliriz
    if (Platform.isAndroid) {
      return "192.168.31.116"; // <-- GÜNCEL IP BURAYA YAZILMALI
    } else if (Platform.isIOS) {
      return "127.0.0.1";
    }

    // Diğer (masaüstü vs) platformlar için varsayılan
    return "127.0.0.1";
  }

  /// İşletme API url'sini döner.
  /// Test cihazına (Android/iOS/Web) göre doğru yerel ağ IP'sini kullanarak
  /// Firebase Emulator HTTP URL'ini oluşturur.
  static String get merchantApiBaseUrl {
    return "http://$localHostIp:5001/kktc-market-dfda7/us-central1/api/api/business";
  }
}

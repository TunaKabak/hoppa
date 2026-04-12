import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../shared/core/config/app_config.dart';

/// B2B (İşletme) giriş ve yetkilendirme süreçlerini yöneten servis.
/// Dependency Injection (DI) kullanılarak test edilebilir ve esnek hale getirilmiştir.
class MerchantAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final http.Client _httpClient;
  final String _baseUrl;

  /// Constructor üzerinden bağımlılıkları alıyoruz (DI).
  /// Verilmezse default olarak kendi instance'larını ve [AppConfig.merchantApiBaseUrl] değerini kullanır.
  MerchantAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    http.Client? httpClient,
    String? baseUrl,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance,
       _httpClient = httpClient ?? http.Client(),
       _baseUrl = baseUrl ?? AppConfig.merchantApiBaseUrl;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    if (_auth.currentUser == null) return const Stream.empty();
    return _db
        .collection('business_users')
        .doc(_auth.currentUser!.uid)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_auth.currentUser == null) return null;
    try {
      final doc = await _db
          .collection('business_users')
          .doc(_auth.currentUser!.uid)
          .get();
      return doc.data();
    } catch (e) {
      print("Merchant Data Fetch Error: $e");
      return null;
    }
  }

  Stream<Map<String, dynamic>?> getUserDataStream() {
    if (_auth.currentUser == null) return Stream.value(null);
    return _db
        .collection('business_users')
        .doc(_auth.currentUser!.uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Kullanıcı adı ve şifre ile işletme girişi yapar.
  /// Hatalar [AuthException] olarak fırlatılır.
  Future<void> loginWithCredentials(String username, String password) async {
    final String loginUrl = "$_baseUrl/auth/login";

    try {
      // .timeout() ekleyerek ağ sorunlarına karşı önlem alıyoruz.
      final response = await _httpClient
          .post(
            Uri.parse(loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          // Başarılı giriş: Custom Token'ı Firebase SDK'ya ver.
          final customToken = data['token'];
          await _auth.signInWithCustomToken(customToken);
        } else {
          throw AuthException(
            data['message'] ?? 'Kayıt bulunamadı veya yetkisiz erişim.',
          );
        }
      } else {
        // 200 harici bir kod döndüyse private error handler'a yönlendir.
        _handleApiError(response);
      }
    } on TimeoutException {
      throw AuthTimeoutException(
        'Sunucu yanıt vermedi (Timeout). Lütfen bağlantınızı kontrol edin. URL: $loginUrl',
      );
    } catch (e) {
      if (e is AuthException ||
          e is AuthTimeoutException ||
          e is FirebaseAuthException) {
        rethrow;
      }
      throw AuthException('Giriş başarısız. Beklenmeyen hata: $e');
    }
  }

  /// Yeni işletme (merchant) kaydını gerçekleştirir.
  Future<void> registerMerchant({
    required String email,
    required String password,
    required String businessName,
    required String msNumber,
    required String taxNumber,
    required String phone,
    required String district,
    required String fullAddress,
  }) async {
    final String registerUrl = "$_baseUrl/auth/register";

    try {
      final response = await _httpClient
          .post(
            Uri.parse(registerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'businessName': businessName,
              'msNumber': msNumber,
              'taxNumber': taxNumber,
              'phone': phone,
              'district': district,
              'fullAddress': fullAddress,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw AuthException(
            data['message'] ?? 'Kayıt işlemi başarısız oldu.',
          );
        }
      } else {
        _handleApiError(response);
      }
    } on TimeoutException {
      throw AuthTimeoutException(
        'Sunucu yanıt vermedi (Timeout). Lütfen bağlantınızı kontrol edin.',
      );
    } catch (e) {
      if (e is AuthException || e is AuthTimeoutException) {
        rethrow;
      }
      throw AuthException('Kayıt başarısız. Beklenmeyen hata: $e');
    }
  }

  /// Revizyon işlemi istendiğinde kayıt düzeltmek için kullanılır.
  Future<void> submitRevision({
    required String uid,
    required String businessName,
    required String msNumber,
    required String taxNumber,
    required String phone,
    required String district,
    required String fullAddress,
  }) async {
    final String url = "$_baseUrl/auth/submit-revision";

    try {
      final response = await _httpClient
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'uid': uid,
              'businessName': businessName,
              'msNumber': msNumber,
              'taxNumber': taxNumber,
              'phone': phone,
              'district': district,
              'fullAddress': fullAddress,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw AuthException(
            data['message'] ?? 'İşlem başarısız.',
          );
        }
      } else {
        _handleApiError(response);
      }
    } on TimeoutException {
      throw AuthTimeoutException(
        'Sunucu yanıt vermedi (Timeout). Lütfen bağlantınızı kontrol edin.',
      );
    } catch (e) {
      if (e is AuthException || e is AuthTimeoutException) {
        rethrow;
      }
      throw AuthException('Güncelleme başarısız. Beklenmeyen hata: $e');
    }
  }

  /// API'den dönen hataları işleyip okunaklı bir [AuthException] fırlatır.
  void _handleApiError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      throw AuthException(
        data['message'] ?? 'Sunucu Hatası: ${response.statusCode}',
      );
    } catch (decodeError) {
      // Body decode edilemezse düz string veya statusCode fırlat.
      if (decodeError is AuthException) rethrow; // İç içe fırlatmayı engelle
      throw AuthException(
        'Sunucu Hatası: ${response.statusCode} - ${response.body}',
      );
    }
  }
}

/// Özel Kimlik Doğrulama Hatası sınıfı.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Zaman aşımı durumu için özel sınıf.
class AuthTimeoutException implements Exception {
  final String message;
  AuthTimeoutException(this.message);

  @override
  String toString() => message;
}

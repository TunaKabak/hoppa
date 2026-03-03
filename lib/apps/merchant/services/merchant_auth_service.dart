import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MerchantAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // --- API GİRİŞİ (Username & Password) ---
  Future<void> loginWithCredentials(String username, String password) async {
    // Emulator URL (10.0.2.2 for Android emulator) or Production URL
    // TODO: Update URL for production
    const String apiUrl =
        "http://10.0.2.2:5001/kktc-market-49df0/us-central1/api/api/business/auth/login";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Firebase Custom Token ile giriş yap
        final customToken = data['token'];
        await _auth.signInWithCustomToken(customToken);
      } else {
        // Hata durumunu fırlat (B2B auth standartlarında jenerik hata)
        throw Exception(data['message'] ?? 'Kullanıcı adı veya şifre hatalı');
      }
    } catch (e) {
      // Bağlantı kopması vs.
      if (e is FirebaseAuthException) {
        rethrow;
      }
      throw Exception('Giriş başarısız. Lütfen bilgilerinizi kontrol ediniz.');
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    if (_auth.currentUser == null) return const Stream.empty();
    return _db.collection('users').doc(_auth.currentUser!.uid).snapshots();
  }

  Future<bool> checkUserExists(String phoneNumber) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Merchant Check Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_auth.currentUser == null) return null;
    try {
      final doc = await _db
          .collection('users')
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
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  // --- TELEFON GİRİŞİ (OTP) - Merchant Only ---
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) codeSent,
    required Function(FirebaseAuthException) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<User?> signInWithSmsCode(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

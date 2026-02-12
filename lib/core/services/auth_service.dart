import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // --- KULLANICI KONTROLÜ ---
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
      print("User Check Error: $e");
      // Eğer yetki hatası varsa vs. false dön veya yönet
      return false;
    }
  }

  // --- KULLANICI BİLGİSİ KAYDETME ---
  Future<void> saveUserToFirestore(
    User user, {
    String? name,
    String? surname,
  }) async {
    // Kullanıcı zaten varsa üzerine yazma (merge: true)
    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      'phone': user.phoneNumber,
      'uid': user.uid,
      'marketId': 'market_1', // Kullanıcının varsayılan marketi
      'name': ?name,
      'surname': ?surname,
      'last_login': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- GOOGLE GİRİŞİ ---
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // İptal edildi

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // İsim soyisim Google'dan gelir
        List<String> names = (user.displayName ?? "").split(" ");
        String name = names.isNotEmpty ? names.first : "";
        String surname = names.length > 1 ? names.last : "";
        await saveUserToFirestore(user, name: name, surname: surname);
      }

      return user;
    } catch (e) {
      print("Google Giriş Hatası: $e");
      rethrow;
    }
  }

  // --- TELEFON GİRİŞİ (OTP) ---
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

  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

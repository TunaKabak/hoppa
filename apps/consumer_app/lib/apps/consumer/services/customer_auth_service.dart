import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // --- KULLANICI KONTROLÜ ---
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    final user = _auth.currentUser;
    if (user == null || user.uid.trim().isEmpty) return const Stream.empty();
    return _db.collection('users').doc(user.uid).snapshots();
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
      return false;
    }
  }

  // --- KULLANICI BİLGİSİ KAYDETME ---
  Future<void> saveUserToFirestore(
    User user, {
    String? name,
    String? surname,
  }) async {
    if (user.uid.trim().isEmpty) return;
    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      'phone': user.phoneNumber,
      'uid': user.uid,
      'name': name,
      'surname': surname,
      'last_login': FieldValue.serverTimestamp(),
      'role': 'user', // Sabit: Sadece user
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null || user.uid.trim().isEmpty) return null;
    try {
      final doc = await _db
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data();
    } catch (e) {
      print("User Data Fetch Error: $e");
      return null;
    }
  }

  Stream<Map<String, dynamic>?> getUserDataStream() {
    final user = _auth.currentUser;
    if (user == null || user.uid.trim().isEmpty) return Stream.value(null);
    return _db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  // --- GOOGLE GİRİŞİ ---
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

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
      // Misafirler için rol varsayılan user kalacak
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/core/services/auth_service.dart';
import 'package:hoppa/models/address.dart';

class AddressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  // Koleksiyon Referansı (Kullanıcıya özel)
  CollectionReference get _addressRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Kullanıcı girişi yapılmamış!");
    return _db.collection('users').doc(uid).collection('addresses');
  }

  // Adres Ekle
  Future<void> addAddress(Address address) async {
    await _addressRef.add(address.toMap());
  }

  // Adresleri Getir
  Stream<List<Address>> getUserAddresses() {
    // Giriş yapmamışsa boş liste dön (Misafir kontrolü)
    if (_auth.currentUser == null) return Stream.value([]);

    return _addressRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Address.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Adres Sil
  Future<void> deleteAddress(String id) async {
    await _addressRef.doc(id).delete();
  }

  // Adres Güncelle
  Future<void> updateAddress(Address address) async {
    if (address.id.isEmpty) {
      throw Exception("Güncellenecek adresin ID'si eksik!");
    }
    await _addressRef.doc(address.id).update(address.toMap());
  }
}

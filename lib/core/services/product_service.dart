import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/models/product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tüm ürünleri canlı olarak (Stream) getir
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data());
      }).toList();
    });
  }

  // İşletme ürününü güncelle (Stok, Durum)
  Future<void> updateBusinessProduct(
    String businessProductId, {
    bool? isAvailable,
    double? stock,
  }) async {
    final Map<String, dynamic> data = {};
    if (isAvailable != null) data['isAvailable'] = isAvailable;
    if (stock != null) data['stock'] = stock;

    if (data.isNotEmpty) {
      await _db
          .collection('business_products')
          .doc(businessProductId)
          .update(data);
    }
  }
}

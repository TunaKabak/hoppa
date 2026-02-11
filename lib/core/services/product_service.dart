import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kktc_market/models/product.dart';

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
}

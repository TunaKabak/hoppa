import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/shared/models/product.dart';
import 'package:hoppa/shared/models/business_product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // GLOBAL: Barkod veya İsim ile ürün ara
  Future<List<Product>> searchGlobalProducts(String query) async {
    if (query.isEmpty) return [];

    // 1. Barkod araması (Tam eşleşme)
    final barcodeSnapshot = await _db
        .collection('products')
        .where('barcode', isEqualTo: query)
        .get();

    if (barcodeSnapshot.docs.isNotEmpty) {
      return barcodeSnapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList();
    }

    // 2. İsim araması (Basit 'startWith' mantığı)
    // Not: Gerçek projede Algolia veya ElasticSearch önerilir.
    // Burada 'name' alanına göre sıralayıp range query yapıyoruz.
    final nameSnapshot = await _db
        .collection('products')
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();

    return nameSnapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
  }

  // GLOBAL: Yeni Ürün Oluştur (Custom Product)
  Future<void> createGlobalProduct(Product product) async {
    // Barkod kontrolü
    final existing = await _db
        .collection('products')
        .doc(product.barcode)
        .get();

    if (existing.exists) {
      throw Exception('Bu barkod ile zaten bir ürün var.');
    }

    await _db.collection('products').doc(product.barcode).set(product.toMap());
  }

  // BUSINESS: Envantere Ürün Ekle
  Future<void> addProductToInventory({
    required String businessId,
    required Product product,
    required double price,
    required double stock,
  }) async {
    // Benzersiz ID oluştur (BusinessID_Barcode)
    final docId = '${businessId}_${product.barcode}';

    final businessProductData = {
      'businessId': businessId,
      'productBarcode': product.barcode,
      'price': price,
      'stock': stock,
      'isAvailable': true,
      'updatedAt': FieldValue.serverTimestamp(),
      // Denormalizasyon: Ürün detaylarını da kaydediyoruz ki
      // listelerken tekrar join yapmak zorunda kalmayalım.
      'product_details': product.toMap(),
    };

    await _db
        .collection('business_products')
        .doc(docId)
        .set(businessProductData);
  }

  // BUSINESS: Mevcut envanter ürününü güncelle
  Future<void> updateBusinessProduct(
    String businessProductId, {
    bool? isAvailable,
    double? stock,
    double? price,
    bool? isWeighted,
  }) async {
    final Map<String, dynamic> data = {};
    if (isAvailable != null) data['isAvailable'] = isAvailable;
    if (stock != null) data['stock'] = stock;
    if (price != null) data['price'] = price;
    if (isWeighted != null) data['product_details.isWeighted'] = isWeighted;

    if (data.isNotEmpty) {
      await _db
          .collection('business_products')
          .doc(businessProductId)
          .update(data);
    }
  }

  // BUSINESS: İşletmenin ürünlerini getir (Stream)
  Stream<QuerySnapshot> getBusinessProductsStream(String businessId) {
    return _db
        .collection('business_products')
        .where('businessId', isEqualTo: businessId)
        .snapshots();
  }

  // BUSINESS: Kritik Stoktaki Ürünleri Getir (Limitli)
  Stream<List<BusinessProduct>> getLowStockProducts(
    String businessId, {
    int limit = 10,
  }) {
    return _db
        .collection('business_products')
        .where('businessId', isEqualTo: businessId)
        .where('stock', isLessThan: 5) // Kritik stok eşiği
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BusinessProduct.fromMap(doc.data(), doc.id);
          }).toList();
          // Create batch and iterate through chunks
          // This is a simple implementation, if there are many docs we might
          // need multiple batches (1 batch = max 500 ops)
        });
  }

  // BUSINESS: Toplu Ürün Silme
  Future<void> bulkDeleteBusinessProducts(List<String> docIds) async {
    if (docIds.isEmpty) return;

    // Firestore batch has a limit of 500 operations. We'll chunk the list.
    final int chunkSize = 500;
    for (int i = 0; i < docIds.length; i += chunkSize) {
      final chunk = docIds.sublist(
        i,
        i + chunkSize > docIds.length ? docIds.length : i + chunkSize,
      );
      final WriteBatch batch = _db.batch();
      for (final id in chunk) {
        final docRef = _db.collection('business_products').doc(id);
        batch.delete(docRef);
      }
      await batch.commit();
    }
  }

  // BUSINESS: Toplu Durum Güncelleme
  Future<void> bulkUpdateBusinessProductsStatus(
    List<String> docIds,
    bool isAvailable,
  ) async {
    if (docIds.isEmpty) return;

    final int chunkSize = 500;
    for (int i = 0; i < docIds.length; i += chunkSize) {
      final chunk = docIds.sublist(
        i,
        i + chunkSize > docIds.length ? docIds.length : i + chunkSize,
      );
      final WriteBatch batch = _db.batch();
      for (final id in chunk) {
        final docRef = _db.collection('business_products').doc(id);
        batch.update(docRef, {'isAvailable': isAvailable});
      }
      await batch.commit();
    }
  }
}

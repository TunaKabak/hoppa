import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kktc_market/features/cart/cart_provider.dart';
import 'package:kktc_market/models/order.dart' as model; // Alias added

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Business ID artık parametre olarak veya sepetten gelmeli
  // Burada sepetten gelen businessId'yi kullanacağız

  Future<void> createOrder({
    required String userId,
    required String userPhone,
    required String address,
    required String deliveryTime,
    required List<CartItem> items,
    required double totalAmount,
    required bool isPickUp,
  }) async {
    if (items.isEmpty) return;

    // Sepetteki ilk ürünün business ID'sini al (Hepsi aynı işletme olmalı)
    String businessId = items.first.businessProduct.businessId;

    try {
      final orderData = {
        'business_id': businessId, // Dinamik Business ID
        'user_id': userId,
        'user_phone': userPhone,
        'user_address': address,
        'delivery_time': deliveryTime,
        'total_amount': totalAmount,
        'payment_method': 'cash_on_delivery',
        'is_pickup': isPickUp,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'items': items.map((item) {
          // BusinessProduct'tan verileri alıp düzleştiriyoruz (Flatten)
          return {
            'product_id': item.businessProduct.productBarcode, // Barkod
            'name': item.businessProduct.product.name,
            'price': item.businessProduct.price, // İşletme Fiyatı
            'quantity': item.quantity,
          };
        }).toList(),
      };

      await _db.collection('orders').add(orderData);
    } catch (e) {
      print("Sipariş oluşturma hatası: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({'status': newStatus});
  }

  Stream<QuerySnapshot> getIncomingOrders({String? businessId}) {
    // Eğer businessId verilmezse varsayılanı kullan (veya tümünü getir)
    // Gerçekte işletme sahibi login olduğunda kendi ID'sini gönderir.
    Query query = _db.collection('orders');

    if (businessId != null) {
      query = query.where('business_id', isEqualTo: businessId);
    }

    return query
        .where(
          'status',
          whereIn: ['pending', 'preparing', 'on_way', 'ready_for_pickup'],
        )
        .snapshots();
  }

  // Stream<model.Order?> getActiveOrderStream(String userId) {
  //   return _db
  //       .collection('orders')
  //       .where('user_id', isEqualTo: userId)
  //       .where('status', whereIn: ['pending', 'preparing', 'on_way'])
  //       .orderBy('created_at', descending: true)
  //       .limit(1)
  //       .snapshots()
  //       .map((snapshot) {
  //         if (snapshot.docs.isNotEmpty) {
  //           final doc = snapshot.docs.first;
  //           return model.Order.fromMap(doc.data(), doc.id);
  //         }
  //         return null;
  //       });
  // }

  Stream<model.Order?> getActiveOrderStream(String userId) {
    return _db
        .collection('orders')
        .where('user_id', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'preparing', 'on_way'])
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            return model.Order.fromMap(doc.data(), doc.id);
          }
          return null;
        });
  }
}

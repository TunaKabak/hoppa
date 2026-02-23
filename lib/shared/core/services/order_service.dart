import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/apps/consumer/cart/cart_provider.dart';
import 'package:hoppa/shared/models/order.dart' as model; // Alias added
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/shared/core/utils/location_utils.dart';

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
    String deliveryMethod = 'delivery', // NEW: 'delivery' or 'pickup'
    String orderNote = '', // NEW: User's order note
    bool dontRingBell = false, // NEW: Doorbell preference
    double addressLatitude = 0.0, // NEW: Address latitude
    double addressLongitude = 0.0, // NEW: Address longitude
  }) async {
    if (items.isEmpty) return;

    // Sepetteki ilk ürünün business ID'sini al (Hepsi aynı işletme olmalı)
    String businessId = items.first.businessProduct.businessId;

    try {
      // --- SERVER-SIDE DOĞRULAMA (Mesafe & Minimum Tutar) ---
      final businessDoc = await _db
          .collection('businesses')
          .doc(businessId)
          .get();
      if (businessDoc.exists) {
        final business = Business.fromMap(businessDoc.data()!, businessDoc.id);

        double requiredMinAmount = business.minBasketAmount;

        if (business.deliveryTiers.isNotEmpty &&
            addressLatitude != 0.0 &&
            addressLongitude != 0.0) {
          final distanceKm = LocationUtils.calculateDistanceInKm(
            lat1: addressLatitude,
            lon1: addressLongitude,
            lat2: business.latitude,
            lon2: business.longitude,
          );

          final sortedTiers = List.of(business.deliveryTiers)
            ..sort((a, b) => a.maxDistance.compareTo(b.maxDistance));

          bool tierFound = false;
          for (var tier in sortedTiers) {
            if (distanceKm <= tier.maxDistance) {
              requiredMinAmount = tier.minAmount;
              tierFound = true;
              break;
            }
          }

          if (!tierFound && sortedTiers.isNotEmpty) {
            requiredMinAmount = sortedTiers.last.minAmount;
          }
        }

        // Ana ürün toplamı (teslimat ücreti vs. hariç)
        // Burada totalAmount sepetteki ürünlerin toplamı olarak varsayılıyor
        if (totalAmount < requiredMinAmount) {
          throw Exception(
            "Minimum sipariş tutarı sağlanamadı. Gerekli tutar: ${requiredMinAmount.toStringAsFixed(2)} ₺",
          );
        }
      }
      // --- SON ---
      final orderData = {
        'business_id': businessId, // Dinamik Business ID
        'user_id': userId,
        'user_phone': userPhone,
        'user_address': address, // Clean address, no prefixes or notes
        'delivery_time': deliveryTime,
        'total_amount': totalAmount,
        'payment_method': 'cash_on_delivery',
        'delivery_method': deliveryMethod, // NEW: Separate field
        'order_note': orderNote, // NEW: Separate field
        'dont_ring_bell': dontRingBell, // NEW: Separate field
        'address_latitude': addressLatitude, // NEW: Location field
        'address_longitude': addressLongitude, // NEW: Location field
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

  Stream<model.Order?> getActiveOrderStream(
    String userId, {
    String? businessId,
  }) {
    Query query = _db.collection('orders').where('user_id', isEqualTo: userId);

    // Filter by businessId if provided
    if (businessId != null) {
      query = query.where('business_id', isEqualTo: businessId);
    }

    return query
        .where(
          'status',
          whereIn: ['pending', 'preparing', 'on_way', 'ready_for_pickup'],
        )
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            return model.Order.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }
          return null;
        });
  }

  Stream<QuerySnapshot> getDailyOrdersStream({String? businessId}) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    Query query = _db
        .collection('orders')
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        );

    if (businessId != null) {
      query = query.where('business_id', isEqualTo: businessId);
    }

    return query.snapshots();
  }

  // --- HAFTALIK SİPARİŞLER (Grafik İçin) ---
  Future<List<Map<String, dynamic>>> getWeeklyOrders(String businessId) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Firestore Timestamp başlangıcı
    final startTimestamp = Timestamp.fromDate(
      DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day),
    );

    final snapshot = await _db
        .collection('orders')
        .where('business_id', isEqualTo: businessId)
        .where('created_at', isGreaterThanOrEqualTo: startTimestamp)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // --- ANALİTİK İÇİN TARİH ARALIĞINA GÖRE SİPARİŞLER ---
  Future<List<Map<String, dynamic>>> getOrdersInRange({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    final snapshot = await _db
        .collection('orders')
        .where('business_id', isEqualTo: businessId)
        .where('status', isEqualTo: 'delivered') // Sadece tamamlananlar
        .where('created_at', isGreaterThanOrEqualTo: startTimestamp)
        .where('created_at', isLessThanOrEqualTo: endTimestamp)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}

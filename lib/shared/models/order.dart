import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/shared/models/order_status.dart';

class Order {
  final String id;
  final String userId;
  final String businessId;
  final String status;
  final double totalAmount;
  final String userAddress;
  final List<OrderItem> items;
  final DateTime createdAt;
  final String deliveryTime;
  final String note; // Deprecated: Use orderNote instead

  // NEW FIELDS for proper data separation
  final String deliveryMethod; // 'delivery' or 'pickup'
  final String orderNote; // User's order note
  final bool dontRingBell; // Doorbell preference
  final double addressLatitude; // Delivery address latitude
  final double addressLongitude; // Delivery address longitude

  Order({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.status,
    required this.totalAmount,
    required this.userAddress,
    required this.items,
    required this.createdAt,
    required this.deliveryTime,
    this.note = '',
    this.deliveryMethod = 'delivery', // Default to delivery
    this.orderNote = '',
    this.dontRingBell = false,
    this.addressLatitude = 0.0,
    this.addressLongitude = 0.0,
  });

  factory Order.fromMap(Map<String, dynamic> data, String id) {
    // Extract basic fields
    String userAddress = data['user_address'] ?? '';

    // Try new format first
    String deliveryMethod = data['delivery_method'] ?? '';
    String orderNote = data['order_note'] ?? '';
    bool dontRingBell = data['dont_ring_bell'] ?? false;

    // Backward compatibility: Parse old format if new fields are empty
    if (deliveryMethod.isEmpty) {
      // Determine delivery method from old format
      deliveryMethod = userAddress.contains('[GEL AL]') ? 'pickup' : 'delivery';

      // Clean up address from old prefix
      userAddress = userAddress
          .replaceFirst(RegExp(r'^\[GEL AL\]\s*', caseSensitive: false), '')
          .trim();

      // Extract note from old format: "Address (Not: note text)"
      if (userAddress.contains('Not:')) {
        List<String> parts = userAddress.split('Not:');
        if (parts.length > 1) {
          userAddress = parts[0].trim();
          String extractedNote = parts[1].replaceAll(')', '').trim();

          // Check for doorbell flag in note
          if (extractedNote.contains('[ZİLİ ÇALMA!]')) {
            dontRingBell = true;
            extractedNote = extractedNote
                .replaceAll('[ZİLİ ÇALMA!]', '')
                .replaceAll(' - ', '')
                .trim();
          }

          orderNote = extractedNote;
        }
      }
    }

    return Order(
      id: id,
      userId: data['user_id'] ?? '',
      businessId: data['business_id'] ?? '',
      status: data['status'] ?? OrderStatus.pending.value,
      totalAmount: (data['total_amount'] ?? 0.0).toDouble(),
      userAddress: userAddress,
      deliveryTime: data['delivery_time'] ?? '',
      note: data['note'] ?? '', // Keep for backward compatibility
      deliveryMethod: deliveryMethod,
      orderNote: orderNote,
      dontRingBell: dontRingBell,
      addressLatitude: (data['address_latitude'] ?? 0.0).toDouble(),
      addressLongitude: (data['address_longitude'] ?? 0.0).toDouble(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromMap(item))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'business_id': businessId,
      'status': status,
      'total_amount': totalAmount,
      'user_address': userAddress,
      'delivery_time': deliveryTime,
      'note': note, // Keep for backward compatibility
      'delivery_method': deliveryMethod,
      'order_note': orderNote,
      'dont_ring_bell': dontRingBell,
      'address_latitude': addressLatitude,
      'address_longitude': addressLongitude,
      'created_at': Timestamp.fromDate(createdAt),
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final double quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['product_id'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: (data['quantity'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}

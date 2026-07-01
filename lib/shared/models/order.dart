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
  final bool leaveAtDoor; // Kapıya bırak preference
  final double addressLatitude; // Delivery address latitude
  final double addressLongitude; // Delivery address longitude
  final String paymentMethod; // Payment Method
  final String? courierId; // Assigned courier's ID
  final int? estimatedDeliveryDuration;
  final String? consumerPhone;
  final String? courierPhone;
  final String? courierName;
  final String? courierVehiclePlate;
  final Map<String, dynamic>? review;
 
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
    this.leaveAtDoor = false,
    this.addressLatitude = 0.0,
    this.addressLongitude = 0.0,
    this.paymentMethod = 'CASH_ON_DELIVERY',
    this.courierId,
    this.estimatedDeliveryDuration,
    this.consumerPhone,
    this.courierPhone,
    this.courierName,
    this.courierVehiclePlate,
    this.review,
  });

  factory Order.fromMap(Map<String, dynamic> data, String id) {
    // Extract basic fields with support for both REST API and Firestore
    String userAddress = data['deliveryAddress'] ?? data['user_address'] ?? '';
    String deliveryMethod = data['delivery_method'] ?? '';
    String orderNote = data['customerNote'] ?? data['order_note'] ?? '';
    bool dontRingBell = data['dontRingBell'] ?? data['dont_ring_bell'] ?? false;
    bool leaveAtDoor = data['leaveAtDoor'] ?? data['leave_at_door'] ?? false;

    final consumerPhone = data['consumer'] != null ? data['consumer']['phone'] as String? : null;
    final courierPhone = data['courier'] != null ? data['courier']['phoneNumber'] as String? : null;
    final courierName = data['courier'] != null ? data['courier']['name'] as String? : null;
    final courierVehiclePlate = data['courier'] != null ? data['courier']['vehiclePlate'] as String? : null;
    final review = data['review'] as Map<String, dynamic>?;

    // Backward compatibility: Parse old format if new fields are empty
    if (deliveryMethod.isEmpty) {
      deliveryMethod = userAddress.contains('[GEL AL]') ? 'pickup' : 'delivery';
      userAddress = userAddress
          .replaceFirst(RegExp(r'^\[GEL AL\]\s*', caseSensitive: false), '')
          .trim();

      if (userAddress.contains('Not:')) {
        List<String> parts = userAddress.split('Not:');
        if (parts.length > 1) {
          userAddress = parts[0].trim();
          String extractedNote = parts[1].replaceAll(')', '').trim();

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

    DateTime parsedCreatedAt;
    final rawCreatedAt = data['createdAt'] ?? data['created_at'];
    if (rawCreatedAt == null) {
      parsedCreatedAt = DateTime.now();
    } else if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now();
    }

    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final parsedItems = itemsRaw.map((item) {
      final itemMap = Map<String, dynamic>.from(item);
      final productId = itemMap['productId'] ?? itemMap['product_id'] ?? '';
      
      // REST API format has nested product name: product: { name }
      String name = itemMap['name'] ?? '';
      if (itemMap['product'] != null && itemMap['product'] is Map) {
        name = itemMap['product']['name'] ?? name;
      }
      
      final price = itemMap['unitPrice'] != null 
          ? (double.tryParse(itemMap['unitPrice'].toString()) ?? 0.0)
          : (double.tryParse((itemMap['price'] ?? 0.0).toString()) ?? 0.0);
          
      final quantity = (double.tryParse((itemMap['quantity'] ?? 0.0).toString()) ?? 0.0);
      
      return OrderItem(
        productId: productId,
        name: name,
        price: price,
        quantity: quantity,
      );
    }).toList();

    return Order(
      id: id,
      userId: data['consumerId'] ?? data['user_id'] ?? '',
      businessId: data['shopId'] ?? data['business_id'] ?? '',
      status: OrderStatus.fromString(data['status']?.toString() ?? '').value,
      totalAmount: data['totalAmount'] != null 
          ? (double.tryParse(data['totalAmount'].toString()) ?? 0.0)
          : (double.tryParse((data['total_amount'] ?? 0.0).toString()) ?? 0.0),
      userAddress: userAddress,
      deliveryTime: data['delivery_time'] ?? '',
      note: data['note'] ?? '',
      deliveryMethod: deliveryMethod,
      orderNote: orderNote,
      dontRingBell: dontRingBell,
      leaveAtDoor: leaveAtDoor,
      addressLatitude: data['address_latitude'] != null 
          ? (data['address_latitude'] as num).toDouble() 
          : (data['address'] != null && data['address']['latitude'] != null 
              ? (data['address']['latitude'] as num).toDouble() 
              : 0.0),
      addressLongitude: data['address_longitude'] != null 
          ? (data['address_longitude'] as num).toDouble() 
          : (data['address'] != null && data['address']['longitude'] != null 
              ? (data['address']['longitude'] as num).toDouble() 
              : 0.0),
      paymentMethod: data['paymentMethod'] ?? data['payment_method'] ?? 'CASH_ON_DELIVERY',
      courierId: data['courierId'] ?? data['courier_id'],
      estimatedDeliveryDuration: data['estimatedDeliveryDuration'] != null 
          ? int.tryParse(data['estimatedDeliveryDuration'].toString())
          : (data['estimated_delivery_duration'] != null 
              ? int.tryParse(data['estimated_delivery_duration'].toString())
              : null),
      createdAt: parsedCreatedAt,
      items: parsedItems,
      consumerPhone: consumerPhone,
      courierPhone: courierPhone,
      courierName: courierName,
      courierVehiclePlate: courierVehiclePlate,
      review: review,
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
      'leave_at_door': leaveAtDoor,
      'address_latitude': addressLatitude,
      'address_longitude': addressLongitude,
      'courier_id': courierId,
      'estimated_delivery_duration': estimatedDeliveryDuration,
      'created_at': Timestamp.fromDate(createdAt),
      'items': items.map((item) => item.toMap()).toList(),
      if (consumerPhone != null) 'consumer': {'phone': consumerPhone},
      if (courierPhone != null || courierName != null || courierVehiclePlate != null)
        'courier': {
          'phoneNumber': courierPhone,
          'name': courierName,
          'vehiclePlate': courierVehiclePlate,
        },
      if (review != null) 'review': review,
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

import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory Order.fromMap(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      userId: data['user_id'] ?? '',
      businessId: data['business_id'] ?? '',
      status: data['status'] ?? 'pending',
      totalAmount: (data['total_amount'] ?? 0.0).toDouble(),
      userAddress: data['user_address'] ?? '',
      deliveryTime: data['delivery_time'] ?? '',
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

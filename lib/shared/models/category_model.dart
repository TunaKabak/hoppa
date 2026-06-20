import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  final int order;
  final bool isActive;
  final bool isFeatured;
  final String? backgroundImage;
  final String? badge; // "new", "popular", "promo", "closed"
  final int businessCount;
  final String avgDeliveryTime;
  final String? subtitle;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.order,
    this.isActive = true,
    this.isFeatured = false,
    this.backgroundImage,
    this.badge,
    this.businessCount = 0,
    this.avgDeliveryTime = '20-30 dk',
    this.subtitle,
    this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map, String id) {
    return Category(
      id: id,
      name: map['name'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'shopping_basket',
      colorHex: map['colorHex'] as String? ?? '#4CAF50',
      order: map['order'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      isFeatured: map['isFeatured'] as bool? ?? false,
      backgroundImage: map['backgroundImage'] as String?,
      badge: map['badge'] as String?,
      businessCount: map['businessCount'] as int? ?? 0,
      avgDeliveryTime: map['avgDeliveryTime'] as String? ?? '20-30 dk',
      subtitle: map['subtitle'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Category.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return Category.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconName': iconName,
      'colorHex': colorHex,
      'order': order,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'backgroundImage': backgroundImage,
      'badge': badge,
      'businessCount': businessCount,
      'avgDeliveryTime': avgDeliveryTime,
      'subtitle': subtitle,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    int? order,
    bool? isActive,
    bool? isFeatured,
    String? backgroundImage,
    String? badge,
    int? businessCount,
    String? avgDeliveryTime,
    String? subtitle,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      badge: badge ?? this.badge,
      businessCount: businessCount ?? this.businessCount,
      avgDeliveryTime: avgDeliveryTime ?? this.avgDeliveryTime,
      subtitle: subtitle ?? this.subtitle,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

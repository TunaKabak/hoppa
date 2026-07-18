import 'package:core_shared/shared/models/business_type.dart';
import 'package:core_shared/shared/models/delivery_tier.dart';

class Business {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String logoUrl;
  final String headerImageUrl;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final BusinessType type; // YENİ: Tekil tür
  final List<String> categories; // Mevcut detaylı kategori listesi korunabilir
  final String openingTime;
  final String closingTime;
  final double minBasketAmount;
  final String averageDeliveryTime;
  final double deliveryRadius;
  final Map<String, dynamic> workingHours;
  final List<DeliveryTier> deliveryTiers; // YENİ: Mesafe bazlı min tutar kuralları
  final double baseDeliveryFee;
  final double? freeDeliveryThreshold;
  final double averageRating;
  final int reviewCount;
  final List<String> allowedPaymentMethods;
  final List<String> allowedFulfillmentModels;
  final List<String> tags; // YENİ: Dinamik işletme etiketleri
  final String? campaignText;

  Business({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.logoUrl,
    required this.headerImageUrl,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isOpen = true,
    this.type = BusinessType.market,
    this.categories = const [],
    this.openingTime = "08:00",
    this.closingTime = "22:00",
    this.minBasketAmount = 0.0,
    this.averageDeliveryTime = "30-45 dk",
    this.deliveryRadius = 5.0,
    this.workingHours = const {},
    this.deliveryTiers = const [],
    this.baseDeliveryFee = 30.0,
    this.freeDeliveryThreshold,
    this.averageRating = 5.0,
    this.reviewCount = 0,
    this.allowedPaymentMethods = const ['CASH_ON_DELIVERY', 'CARD_ON_DELIVERY', 'ONLINE_PAYMENT'],
    this.allowedFulfillmentModels = const ['PLATFORM_DELIVERY', 'PICKUP'],
    this.tags = const [],
    this.campaignText,
  });

  factory Business.fromMap(Map<String, dynamic> data, String id) {
    return Business(
      id: id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      headerImageUrl: data['headerImageUrl'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      isOpen: data['isOpen'] ?? true,
      type: BusinessType.fromString(data['type'] ?? 'market'),
      categories: List<String>.from(data['categories'] ?? []),
      openingTime: data['openingTime'] ?? "08:00",
      closingTime: data['closingTime'] ?? "22:00",
      minBasketAmount: (data['minBasketAmount'] ?? 0.0).toDouble(),
      averageDeliveryTime: data['averageDeliveryTime'] ?? "30-45 dk",
      deliveryRadius: (data['deliveryRadius'] ?? 5.0).toDouble(),
      workingHours: Map<String, dynamic>.from(data['workingHours'] ?? {}),
      deliveryTiers:
          (data['deliveryTiers'] as List<dynamic>?)
              ?.map((t) => DeliveryTier.fromMap(Map<String, dynamic>.from(t)))
              .toList() ??
          [],
      baseDeliveryFee: (data['baseDeliveryFee'] ?? 30.0).toDouble(),
      freeDeliveryThreshold: data['freeDeliveryThreshold'] != null 
          ? (data['freeDeliveryThreshold']).toDouble() 
          : null,
      averageRating: (data['averageRating'] ?? 5.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      allowedPaymentMethods: List<String>.from(data['allowedPaymentMethods'] ?? const ['CASH_ON_DELIVERY', 'CARD_ON_DELIVERY', 'ONLINE_PAYMENT']),
      allowedFulfillmentModels: List<String>.from(data['allowedFulfillmentModels'] ?? const ['PLATFORM_DELIVERY', 'PICKUP']),
      tags: List<String>.from(data['tags'] ?? []),
      campaignText: data['campaignText'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'logoUrl': logoUrl,
      'headerImageUrl': headerImageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'isOpen': isOpen,
      'type': type.name,
      'categories': categories,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'minBasketAmount': minBasketAmount,
      'averageDeliveryTime': averageDeliveryTime,
      'deliveryRadius': deliveryRadius,
      'workingHours': workingHours,
      'deliveryTiers': deliveryTiers.map((t) => t.toMap()).toList(),
      'baseDeliveryFee': baseDeliveryFee,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'allowedPaymentMethods': allowedPaymentMethods,
      'allowedFulfillmentModels': allowedFulfillmentModels,
      'tags': tags,
      'campaignText': campaignText,
    };
  }

  Business copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? logoUrl,
    String? headerImageUrl,
    double? latitude,
    double? longitude,
    bool? isOpen,
    BusinessType? type,
    List<String>? categories,
    String? openingTime,
    String? closingTime,
    double? minBasketAmount,
    String? averageDeliveryTime,
    double? deliveryRadius,
    Map<String, dynamic>? workingHours,
    List<DeliveryTier>? deliveryTiers,
    double? baseDeliveryFee,
    double? freeDeliveryThreshold,
    double? averageRating,
    int? reviewCount,
    List<String>? allowedPaymentMethods,
    List<String>? allowedFulfillmentModels,
    List<String>? tags,
    String? campaignText,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      logoUrl: logoUrl ?? this.logoUrl,
      headerImageUrl: headerImageUrl ?? this.headerImageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOpen: isOpen ?? this.isOpen,
      type: type ?? this.type,
      categories: categories ?? this.categories,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      minBasketAmount: minBasketAmount ?? this.minBasketAmount,
      averageDeliveryTime: averageDeliveryTime ?? this.averageDeliveryTime,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      workingHours: workingHours ?? this.workingHours,
      deliveryTiers: deliveryTiers ?? this.deliveryTiers,
      baseDeliveryFee: baseDeliveryFee ?? this.baseDeliveryFee,
      freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      allowedPaymentMethods: allowedPaymentMethods ?? this.allowedPaymentMethods,
      allowedFulfillmentModels: allowedFulfillmentModels ?? this.allowedFulfillmentModels,
      tags: tags ?? this.tags,
      campaignText: campaignText ?? this.campaignText,
    );
  }
}

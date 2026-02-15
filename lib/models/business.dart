import 'package:hoppa/models/business_type.dart';

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
    };
  }
}

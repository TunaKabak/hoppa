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
    this.type = BusinessType.market, // Varsayılan
    this.categories = const [],
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
      'type': type.name, // Enum adı string olarak
      'categories': categories,
    };
  }
}

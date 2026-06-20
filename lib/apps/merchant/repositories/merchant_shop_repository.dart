import 'package:core_network/core_network.dart';

class MerchantShop {
  final String id;
  final String merchantId;
  final String name;
  final String? description;
  final String? address;
  final String? taxNumber;
  final bool isActive;
  final String? imageUrl;
  final String? headerImageUrl;
  final double? latitude;
  final double? longitude;
  final double? deliveryRadiusKm;
  final Map<String, dynamic>? workingHours;
  final double? minOrderAmount;
  final String? businessPhone;
  final String? identityNumber;
  final String type;

  MerchantShop({
    required this.id,
    required this.merchantId,
    required this.name,
    this.description,
    this.address,
    this.taxNumber,
    this.isActive = false,
    this.imageUrl,
    this.headerImageUrl,
    this.latitude,
    this.longitude,
    this.deliveryRadiusKm,
    this.workingHours,
    this.minOrderAmount,
    this.businessPhone,
    this.identityNumber,
    this.type = 'OTHER',
  });

  factory MerchantShop.fromMap(Map<String, dynamic> map) {
    final merchantMap = map['merchant'] as Map<String, dynamic>?;
    return MerchantShop(
      id: map['id'] ?? '',
      merchantId: map['merchantId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      address: map['address'],
      taxNumber: map['taxNumber'] ?? merchantMap?['taxNumber'],
      isActive: map['isActive'] ?? false,
      imageUrl: map['imageUrl'],
      headerImageUrl: map['headerImageUrl'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      deliveryRadiusKm: map['deliveryRadiusKm'] != null ? (map['deliveryRadiusKm'] as num).toDouble() : null,
      workingHours: map['workingHours'] != null ? Map<String, dynamic>.from(map['workingHours']) : null,
      minOrderAmount: map['minOrderAmount'] != null ? double.tryParse(map['minOrderAmount'].toString()) : null,
      businessPhone: merchantMap?['businessPhone'],
      identityNumber: merchantMap?['identityNumber'],
      type: map['type'] ?? 'OTHER',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'taxNumber': taxNumber,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'headerImageUrl': headerImageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'deliveryRadiusKm': deliveryRadiusKm,
      'workingHours': workingHours,
      'minOrderAmount': minOrderAmount,
      'businessPhone': businessPhone,
      'identityNumber': identityNumber,
      'type': type,
    };
  }
}

class MerchantShopRepository {
  final ApiClient _apiClient;

  MerchantShopRepository(this._apiClient);

  Future<MerchantShop?> getShop() async {
    try {
      final response = await _apiClient.get('/api/merchant/shop');
      if (response['data'] != null) {
        return MerchantShop.fromMap(response['data']);
      }
      return null;
    } catch (e) {
      if (e is AppException && e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<MerchantShop> updateShop(Map<String, dynamic> data) async {
    final response = await _apiClient.put('/api/merchant/shop', body: data);
    return MerchantShop.fromMap(response['data']);
  }

  Future<MerchantShop> toggleStatus(bool isActive) async {
    final response = await _apiClient.post('/api/merchant/shop/toggle-status', body: {'isActive': isActive});
    return MerchantShop.fromMap(response['data']);
  }
}

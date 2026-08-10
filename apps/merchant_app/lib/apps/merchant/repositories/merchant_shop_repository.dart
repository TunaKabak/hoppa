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
  
  // Yeni teslimat alanları
  final String? deliveryTime;
  final String? deliveryPricingType;
  final double? baseDeliveryFee;
  final double? deliveryFeePerKm;
  final double? freeDeliveryThreshold;
  final List<dynamic>? deliveryPolygon;
  final List<String>? allowedPaymentMethods;
  final List<String>? allowedFulfillmentModels;
  final String? campaignText;

  // Story 49 Sponsorluk ve Sepet Limiti Alanları
  final double? minimumOrderLimit;
  final double? activeCommissionRate;
  final List<dynamic>? activePromotions;

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
    this.deliveryTime,
    this.deliveryPricingType = 'FIXED',
    this.baseDeliveryFee,
    this.deliveryFeePerKm,
    this.freeDeliveryThreshold,
    this.deliveryPolygon,
    this.allowedPaymentMethods,
    this.allowedFulfillmentModels,
    this.campaignText,
    this.minimumOrderLimit,
    this.activeCommissionRate,
    this.activePromotions,
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
      deliveryTime: map['deliveryTime'],
      deliveryPricingType: map['deliveryPricingType'] ?? 'FIXED',
      baseDeliveryFee: map['baseDeliveryFee'] != null ? (map['baseDeliveryFee'] as num).toDouble() : null,
      deliveryFeePerKm: map['deliveryFeePerKm'] != null ? (map['deliveryFeePerKm'] as num).toDouble() : null,
      freeDeliveryThreshold: map['freeDeliveryThreshold'] != null ? (map['freeDeliveryThreshold'] as num).toDouble() : null,
      deliveryPolygon: map['deliveryPolygon'] != null ? List<dynamic>.from(map['deliveryPolygon']) : null,
      allowedPaymentMethods: map['allowedPaymentMethods'] != null ? List<String>.from(map['allowedPaymentMethods']) : null,
      allowedFulfillmentModels: map['allowedFulfillmentModels'] != null ? List<String>.from(map['allowedFulfillmentModels']) : null,
      campaignText: map['campaignText'],
      minimumOrderLimit: map['minimumOrderLimit'] != null ? double.tryParse(map['minimumOrderLimit'].toString()) : null,
      activeCommissionRate: map['activeCommissionRate'] != null ? (map['activeCommissionRate'] as num).toDouble() : null,
      activePromotions: map['activePromotions'] != null ? List<dynamic>.from(map['activePromotions']) : null,
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
      'deliveryTime': deliveryTime,
      'deliveryPricingType': deliveryPricingType,
      'baseDeliveryFee': baseDeliveryFee,
      'deliveryFeePerKm': deliveryFeePerKm,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'deliveryPolygon': deliveryPolygon,
      'allowedPaymentMethods': allowedPaymentMethods,
      'allowedFulfillmentModels': allowedFulfillmentModels,
      'campaignText': campaignText,
      'minimumOrderLimit': minimumOrderLimit,
      'activeCommissionRate': activeCommissionRate,
      'activePromotions': activePromotions,
    };
  }
}

class MerchantShopRepository {
  final ApiClient _apiClient;

  MerchantShopRepository(this._apiClient);

  Future<MerchantShop?> getShop({String? shopId}) async {
    try {
      final path = shopId != null && shopId.isNotEmpty ? '/api/merchant/shop?shopId=$shopId' : '/api/merchant/shop';
      final response = await _apiClient.get(path);
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

  Future<MerchantShop> updateShop(Map<String, dynamic> data, {String? shopId}) async {
    final path = shopId != null && shopId.isNotEmpty ? '/api/merchant/shop?shopId=$shopId' : '/api/merchant/shop';
    final response = await _apiClient.put(path, body: data);
    return MerchantShop.fromMap(response['data']);
  }

  Future<MerchantShop> toggleStatus(bool isActive, {String? shopId}) async {
    final path = shopId != null && shopId.isNotEmpty ? '/api/merchant/shop/toggle-status?shopId=$shopId' : '/api/merchant/shop/toggle-status';
    final response = await _apiClient.post(path, body: {'isActive': isActive});
    return MerchantShop.fromMap(response['data']);
  }

  Future<MerchantShop> createPromotion(String promoType) async {
    final response = await _apiClient.post('/api/merchant/promotions', body: {'promoType': promoType});
    return MerchantShop.fromMap(response['data']);
  }

  Future<MerchantShop> cancelPromotion(String promoType) async {
    final response = await _apiClient.post('/api/merchant/promotions/cancel', body: {'promoType': promoType});
    return MerchantShop.fromMap(response['data']);
  }

  Future<List<dynamic>> getShopCampaigns() async {
    final response = await _apiClient.get('/api/merchant/campaigns');
    return response['data'] ?? [];
  }

  Future<dynamic> createShopCampaign({
    required String title,
    required String description,
    required String imageUrl,
    required String targetArea,
    required bool designService,
    List<String>? targetProducts,
  }) async {
    final response = await _apiClient.post(
      '/api/merchant/campaigns',
      body: {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'targetArea': targetArea,
        'designService': designService,
        'targetProducts': targetProducts ?? [],
      },
    );
    return response['data'];
  }
}

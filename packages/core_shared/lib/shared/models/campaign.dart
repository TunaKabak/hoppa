import 'package:cloud_firestore/cloud_firestore.dart';

enum CampaignType { percentage, fixedPrice }

class Campaign {
  final String id;
  final String vendorId;
  final String name;
  final CampaignType type;
  final List<String> targetProducts; // List of BusinessProduct IDs or Barcodes
  final double discountValue; // Percentage (e.g., 20.0) or Fixed Price (e.g. 50.0)
  final DateTime startDate;
  final DateTime endDate;
  final String imageUrl;
  final String description;
  final bool isActive;
  final String? externalUrl;
  final String targetArea;
  final String sourceType; // SYSTEM, SHOP, AD
  final String? discountType;
  final double minOrderAmount;

  Campaign({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.type,
    required this.targetProducts,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
    this.description = '',
    this.isActive = true,
    this.externalUrl,
    this.targetArea = 'MAIN_SLIDER',
    this.sourceType = 'SYSTEM',
    this.discountType,
    this.minOrderAmount = 0.0,
  });

  factory Campaign.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return Campaign(
      id: documentId,
      vendorId: data['vendorId'] ?? data['shopId'] ?? '',
      name: data['name'] ?? data['title'] ?? 'Adsız Kampanya',
      type: data['type'] == 'fixed_price' || data['type'] == 'CampaignType.fixedPrice'
          ? CampaignType.fixedPrice
          : CampaignType.percentage,
      targetProducts: List<String>.from(data['targetProducts'] ?? []),
      discountValue: (data['discountValue'] ?? 0.0).toDouble(),
      startDate: parseDate(data['startDate'] ?? data['createdAt']),
      endDate: parseDate(data['endDate'] ?? data['finishDate']),
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      externalUrl: data['externalUrl'],
      targetArea: data['targetArea'] ?? 'MAIN_SLIDER',
      sourceType: data['sourceType'] ?? data['type'] ?? 'SYSTEM',
      discountType: data['discountType'],
      minOrderAmount: (data['minOrderAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'name': name,
      'type': type == CampaignType.fixedPrice ? 'fixed_price' : 'percentage',
      'targetProducts': targetProducts,
      'discountValue': discountValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'imageUrl': imageUrl,
      'description': description,
      'isActive': isActive,
      'externalUrl': externalUrl,
      'targetArea': targetArea,
      'sourceType': sourceType,
      'discountType': discountType,
      'minOrderAmount': minOrderAmount,
    };
  }

  // Yardımcı Metod: Ürün fiyatını hesapla
  double calculateDiscountedPrice(double originalPrice) {
    if (type == CampaignType.percentage) {
      return originalPrice * (1 - (discountValue / 100));
    } else {
      return discountValue;
    }
  }

  Campaign copyWith({
    String? id,
    String? vendorId,
    String? name,
    CampaignType? type,
    List<String>? targetProducts,
    double? discountValue,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    String? description,
    bool? isActive,
    String? externalUrl,
    String? targetArea,
    String? sourceType,
    String? discountType,
    double? minOrderAmount,
  }) {
    return Campaign(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      type: type ?? this.type,
      targetProducts: targetProducts ?? this.targetProducts,
      discountValue: discountValue ?? this.discountValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      externalUrl: externalUrl ?? this.externalUrl,
      targetArea: targetArea ?? this.targetArea,
      sourceType: sourceType ?? this.sourceType,
      discountType: discountType ?? this.discountType,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
    );
  }
}

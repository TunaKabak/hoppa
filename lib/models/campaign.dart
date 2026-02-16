import 'package:cloud_firestore/cloud_firestore.dart';

enum CampaignType { percentage, fixedPrice }

class Campaign {
  final String id;
  final String vendorId;
  final String name;
  final CampaignType type;
  final List<String> targetProducts; // List of BusinessProduct IDs or Barcodes
  final double
  discountValue; // Percentage (e.g., 20.0) or Fixed Price (e.g. 50.0)
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Campaign({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.type,
    required this.targetProducts,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  factory Campaign.fromMap(Map<String, dynamic> data, String documentId) {
    return Campaign(
      id: documentId,
      vendorId: data['vendorId'] ?? '',
      name: data['name'] ?? 'Adsız Kampanya',
      type: data['type'] == 'fixed_price'
          ? CampaignType.fixedPrice
          : CampaignType.percentage,
      targetProducts: List<String>.from(data['targetProducts'] ?? []),
      discountValue: (data['discountValue'] ?? 0.0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
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
      'isActive': isActive,
    };
  }

  // Yardımcı Metod: Ürün fiyatını hesapla
  double calculateDiscountedPrice(double originalPrice) {
    if (type == CampaignType.percentage) {
      return originalPrice * (1 - (discountValue / 100));
    } else {
      // Sabit fiyat indirimi (Direkt satış fiyatı buysa)
      // Veya indirim miktarı (original - discount) ise: return originalPrice - discountValue;
      // İster: "Sabit Fiyat" genelde "Bu ürün 50 TL" demek olur.
      return discountValue;
    }
  }
}

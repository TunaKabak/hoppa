import 'package:hoppa/shared/models/product.dart';

class BusinessProduct {
  final String id; // Envanter ID'si
  final String businessId;
  final String productBarcode;
  final double price;
  final double stock;
  final bool isAvailable; // YENİ: Ürün satışa açık mı?
  final bool trackStock; // YENİ: Stok takibi var mı?
  final int stockQuantity; // YENİ: Stok miktarı
  final double regularPrice; // YENİ
  final int discountRate; // YENİ
  final Product product; // Global ürün detaylarını içinde taşır (Performans için)

  BusinessProduct({
    required this.id,
    required this.businessId,
    required this.productBarcode,
    required this.price,
    required this.stock,
    this.isAvailable = true,
    this.trackStock = false,
    this.stockQuantity = 0,
    required this.regularPrice,
    this.discountRate = 0,
    required this.product,
  });

  factory BusinessProduct.fromMap(Map<String, dynamic> data, String id) {
    final trackStock = data['trackStock'] as bool? ?? false;
    final stockQuantity = data['stockQuantity'] as int? ?? 0;
    final double priceVal = (data['price'] ?? 0.0).toDouble();
    return BusinessProduct(
      id: id,
      businessId: data['businessId'] ?? '',
      productBarcode: data['productBarcode'] ?? '',
      price: priceVal,
      stock: trackStock ? stockQuantity.toDouble() : 9999.0,
      isAvailable: data['isAvailable'] ?? true,
      trackStock: trackStock,
      stockQuantity: stockQuantity,
      regularPrice: (data['regularPrice'] ?? priceVal).toDouble(),
      discountRate: data['discountRate'] as int? ?? 0,
      product: Product.fromMap(data['product_details'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'productBarcode': productBarcode,
      'price': price,
      'stock': stock,
      'isAvailable': isAvailable,
      'trackStock': trackStock,
      'stockQuantity': stockQuantity,
      'regularPrice': regularPrice,
      'discountRate': discountRate,
      'product_details': product.toMap(),
    };
  }
}

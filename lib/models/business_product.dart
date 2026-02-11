import 'package:kktc_market/models/product.dart';

class BusinessProduct {
  final String id; // Envanter ID'si
  final String businessId;
  final String productBarcode;
  final double price;
  final double stock;
  final Product
  product; // Global ürün detaylarını içinde taşır (Performans için)

  BusinessProduct({
    required this.id,
    required this.businessId,
    required this.productBarcode,
    required this.price,
    required this.stock,
    required this.product,
  });

  factory BusinessProduct.fromMap(Map<String, dynamic> data, String id) {
    return BusinessProduct(
      id: id,
      businessId: data['businessId'] ?? '',
      productBarcode: data['productBarcode'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      stock: (data['stock'] ?? 0.0).toDouble(),
      // Ürün detayları map içinde 'details' objesi olarak saklanırsa:
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
      'product_details': product.toMap(),
    };
  }
}

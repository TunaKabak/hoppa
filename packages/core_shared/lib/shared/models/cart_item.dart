import 'package:core_shared/shared/models/business_product.dart';

class CartItem {
  final BusinessProduct businessProduct;
  final double quantity;

  CartItem({
    required this.businessProduct,
    this.quantity = 1.0,
  });

  CartItem copyWith({
    BusinessProduct? businessProduct,
    double? quantity,
  }) {
    return CartItem(
      businessProduct: businessProduct ?? this.businessProduct,
      quantity: quantity ?? this.quantity,
    );
  }
}

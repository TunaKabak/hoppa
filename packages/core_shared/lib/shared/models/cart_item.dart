import 'package:core_shared/shared/models/business_product.dart';
import 'package:core_shared/shared/models/product.dart';

class CartItem {
  final BusinessProduct businessProduct;
  final double quantity;
  final List<SelectedProductOption> selectedOptions;

  CartItem({
    required this.businessProduct,
    this.quantity = 1.0,
    this.selectedOptions = const [],
  });

  double get unitPrice {
    double base = businessProduct.price;
    double extras = 0.0;
    for (var opt in selectedOptions) {
      if (opt.actionType == 'REMOVE') continue;
      extras += opt.price * opt.quantity;
    }
    return base + extras;
  }

  double get itemTotal => unitPrice * quantity;

  CartItem copyWith({
    BusinessProduct? businessProduct,
    double? quantity,
    List<SelectedProductOption>? selectedOptions,
  }) {
    return CartItem(
      businessProduct: businessProduct ?? this.businessProduct,
      quantity: quantity ?? this.quantity,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }
}

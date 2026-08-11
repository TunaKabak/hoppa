import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:core_shared/shared/models/business_product.dart';
import 'package:core_shared/shared/core/services/campaign_service.dart';
import 'package:core_shared/shared/models/campaign.dart';
import 'package:core_shared/shared/models/business.dart';
import 'package:core_shared/shared/models/address.dart';
import 'package:core_shared/shared/core/utils/location_utils.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:core_shared/shared/core/utils/quantity_formatter.dart';
import 'package:core_shared/shared/models/cart_item.dart';

import 'package:core_shared/shared/models/product.dart';

class BusinessCart {
  final String businessId;
  final String businessName;
  final String? businessLogoUrl;
  final List<CartItem> items;

  BusinessCart({
    required this.businessId,
    required this.businessName,
    this.businessLogoUrl,
    required this.items,
  });

  double get subtotal {
    double total = 0.0;
    for (var item in items) {
      total += item.itemTotal;
    }
    return total;
  }

  int get totalItemCount {
    int total = 0;
    for (var item in items) {
      total += item.quantity.ceil();
    }
    return total;
  }

  BusinessCart copyWith({
    String? businessId,
    String? businessName,
    String? businessLogoUrl,
    List<CartItem>? items,
  }) {
    return BusinessCart(
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      items: items ?? this.items,
    );
  }
}

class CartState {
  final Map<String, BusinessCart> carts;
  final String? activeBusinessId;

  CartState({
    required this.carts,
    this.activeBusinessId,
  });

  BusinessCart? get activeCart {
    if (activeBusinessId != null && carts.containsKey(activeBusinessId)) {
      return carts[activeBusinessId];
    }
    return carts.isNotEmpty ? carts.values.first : null;
  }

  // Backward compatibility getters (Active selected business cart)
  List<CartItem> get items => activeCart?.items ?? [];
  String? get currentBusinessId => activeCart?.businessId;
  double get totalAmount => activeCart?.subtotal ?? 0.0;

  // Multi-cart specific getters
  double get grandTotal {
    double total = 0.0;
    for (var cart in carts.values) {
      total += cart.subtotal;
    }
    return total;
  }

  int get totalItemCountAllCarts {
    int total = 0;
    for (var cart in carts.values) {
      total += cart.totalItemCount;
    }
    return total;
  }

  int get activeCartCount => carts.length;
  bool get hasMultipleCarts => carts.length > 1;

  CartState copyWith({
    Map<String, BusinessCart>? carts,
    String? activeBusinessId,
  }) {
    return CartState(
      carts: carts ?? this.carts,
      activeBusinessId: activeBusinessId ?? this.activeBusinessId,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;

  CartNotifier(this.ref) : super(CartState(carts: {}));

  void addToCart(BusinessProduct product) {
    final businessId = product.businessId;

    // Dükkan aktiflik ve bilgi alma kontrolü
    final shopsAsync = ref.read(consumerShopsProvider);
    final shops = shopsAsync.value ?? [];
    String shopName = "İşletme";
    String? shopLogoUrl;

    if (shops.isNotEmpty) {
      try {
        final shop = shops.firstWhere((s) => s.id == businessId);
        if (!shop.isOpen) {
          throw Exception("Bu dükkan kapalı olduğu için sepetinize ürün eklenemez.");
        }
        shopName = shop.name;
        shopLogoUrl = shop.logoUrl;
      } catch (_) {}
    }

    if (!product.isAvailable) {
      throw Exception("Ürün şu anda temin edilemiyor.");
    }

    final newCarts = Map<String, BusinessCart>.from(state.carts);
    final existingCart = newCarts[businessId];
    final items = existingCart != null ? List<CartItem>.from(existingCart.items) : <CartItem>[];

    final index = items.indexWhere(
      (item) => item.businessProduct.id == product.id,
    );

    final step = product.product.stepSize;
    final minQty = product.product.minQuantity;
    double currentQty = index >= 0 ? items[index].quantity : 0.0;

    double newQty;
    if (currentQty <= 0.0) {
      newQty = minQty;
    } else {
      newQty = QuantityFormatter.roundDouble(currentQty + step);
    }

    if (product.trackStock && newQty > product.stock) {
      throw Exception("Stok yetersiz!");
    }

    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: newQty);
    } else {
      items.add(CartItem(
        businessProduct: product,
        quantity: newQty,
      ));
    }

    final updatedCart = BusinessCart(
      businessId: businessId,
      businessName: existingCart?.businessName ?? shopName,
      businessLogoUrl: existingCart?.businessLogoUrl ?? shopLogoUrl,
      items: items,
    );

    newCarts[businessId] = updatedCart;

    state = state.copyWith(
      carts: newCarts,
      activeBusinessId: businessId,
    );
  }

  void addToCartWithOptions(
    BusinessProduct product,
    List<SelectedProductOption> options,
    double quantity,
  ) {
    final businessId = product.businessId;

    final shopsAsync = ref.read(consumerShopsProvider);
    final shops = shopsAsync.value ?? [];
    String shopName = "İşletme";
    String? shopLogoUrl;

    if (shops.isNotEmpty) {
      try {
        final shop = shops.firstWhere((s) => s.id == businessId);
        if (!shop.isOpen) {
          throw Exception("Bu dükkan kapalı olduğu için sepetinize ürün eklenemez.");
        }
        shopName = shop.name;
        shopLogoUrl = shop.logoUrl;
      } catch (_) {}
    }

    if (!product.isAvailable) {
      throw Exception("Ürün şu anda temin edilemiyor.");
    }

    final newCarts = Map<String, BusinessCart>.from(state.carts);
    final existingCart = newCarts[businessId];
    final items = existingCart != null ? List<CartItem>.from(existingCart.items) : <CartItem>[];

    items.add(CartItem(
      businessProduct: product,
      quantity: quantity,
      selectedOptions: options,
    ));

    final updatedCart = BusinessCart(
      businessId: businessId,
      businessName: existingCart?.businessName ?? shopName,
      businessLogoUrl: existingCart?.businessLogoUrl ?? shopLogoUrl,
      items: items,
    );

    newCarts[businessId] = updatedCart;

    state = state.copyWith(
      carts: newCarts,
      activeBusinessId: businessId,
    );
  }

  void removeFromCart(String productId, [String? targetBusinessId]) {
    String? businessId = targetBusinessId;

    if (businessId == null) {
      for (var entry in state.carts.entries) {
        if (entry.value.items.any((item) => item.businessProduct.id == productId)) {
          businessId = entry.key;
          break;
        }
      }
    }

    if (businessId == null || !state.carts.containsKey(businessId)) return;

    final newCarts = Map<String, BusinessCart>.from(state.carts);
    final existingCart = newCarts[businessId]!;
    final items = List<CartItem>.from(existingCart.items);

    final index = items.indexWhere(
      (item) => item.businessProduct.id == productId,
    );

    if (index >= 0) {
      final item = items[index];
      final step = item.businessProduct.product.stepSize;
      final minQty = item.businessProduct.product.minQuantity;

      if (QuantityFormatter.roundDouble(item.quantity - step) >= minQty - 0.001) {
        items[index] = item.copyWith(
          quantity: QuantityFormatter.roundDouble(item.quantity - step),
        );
        newCarts[businessId] = existingCart.copyWith(items: items);
      } else {
        items.removeAt(index);
        if (items.isEmpty) {
          newCarts.remove(businessId);
        } else {
          newCarts[businessId] = existingCart.copyWith(items: items);
        }
      }

      String? newActiveId = state.activeBusinessId;
      if (!newCarts.containsKey(newActiveId)) {
        newActiveId = newCarts.isNotEmpty ? newCarts.keys.first : null;
      }

      state = CartState(
        carts: newCarts,
        activeBusinessId: newActiveId,
      );
    }
  }

  void selectActiveCart(String businessId) {
    if (state.carts.containsKey(businessId)) {
      state = state.copyWith(activeBusinessId: businessId);
    }
  }

  void clearCart([String? targetBusinessId]) {
    if (targetBusinessId != null) {
      final newCarts = Map<String, BusinessCart>.from(state.carts)..remove(targetBusinessId);
      String? newActiveId = state.activeBusinessId;
      if (newActiveId == targetBusinessId || !newCarts.containsKey(newActiveId)) {
        newActiveId = newCarts.isNotEmpty ? newCarts.keys.first : null;
      }
      state = CartState(
        carts: newCarts,
        activeBusinessId: newActiveId,
      );
    } else {
      state = CartState(carts: {}, activeBusinessId: null);
    }
  }

  void removeGroup(String groupBy, String groupName, [String? targetBusinessId]) {
    final businessId = targetBusinessId ?? state.activeBusinessId;
    if (businessId == null || !state.carts.containsKey(businessId)) return;

    final existingCart = state.carts[businessId]!;
    final newItems = existingCart.items.where((item) {
      final key = groupBy == 'brand'
          ? item.businessProduct.product.brand
          : item.businessProduct.product.category;
      return key != groupName;
    }).toList();

    final newCarts = Map<String, BusinessCart>.from(state.carts);
    if (newItems.isEmpty) {
      newCarts.remove(businessId);
    } else {
      newCarts[businessId] = existingCart.copyWith(items: newItems);
    }

    String? newActiveId = state.activeBusinessId;
    if (!newCarts.containsKey(newActiveId)) {
      newActiveId = newCarts.isNotEmpty ? newCarts.keys.first : null;
    }

    state = CartState(
      carts: newCarts,
      activeBusinessId: newActiveId,
    );
  }

  double getItemQuantity(String productId) {
    for (var cart in state.carts.values) {
      for (var item in cart.items) {
        if (item.businessProduct.id == productId) {
          return item.quantity;
        }
      }
    }
    return 0.0;
  }
}

// Riverpod Providers
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

final cartCampaignsProvider = StreamProvider<List<Campaign>>((ref) {
  final cartState = ref.watch(cartProvider);
  final businessId = cartState.currentBusinessId;
  if (businessId == null) {
    return const Stream.empty();
  }
  return CampaignService().getActiveCampaigns(businessId);
});

double getRequiredMinAmount(Business? business, Address? userAddress) {
  if (business == null) return 0.0;

  // Fallback to default minimum amount
  double requiredAmount = business.minBasketAmount;

  // If tiers exist and we have user coordinates
  if (business.deliveryTiers.isNotEmpty && userAddress != null) {
    if (userAddress.latitude != 0.0 &&
        userAddress.longitude != 0.0 &&
        business.latitude != 0.0 &&
        business.longitude != 0.0) {
      final distanceKm = LocationUtils.calculateDistanceInKm(
        lat1: userAddress.latitude,
        lon1: userAddress.longitude,
        lat2: business.latitude,
        lon2: business.longitude,
      );

      // Sort tiers by maxDistance ascending
      final sortedTiers = List.of(business.deliveryTiers)
        ..sort((a, b) => a.maxDistance.compareTo(b.maxDistance));

      bool tierFound = false;
      for (var tier in sortedTiers) {
        if (distanceKm <= tier.maxDistance) {
          requiredAmount = tier.minAmount;
          tierFound = true;
          break;
        }
      }

      if (!tierFound && sortedTiers.isNotEmpty) {
        requiredAmount = sortedTiers.last.minAmount;
      }
    }
  }

  return requiredAmount;
}



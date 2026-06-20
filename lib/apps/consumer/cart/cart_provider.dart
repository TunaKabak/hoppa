import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hoppa/shared/models/business_product.dart';
import 'package:hoppa/shared/core/services/campaign_service.dart';
import 'package:hoppa/shared/models/campaign.dart';
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/shared/models/address.dart';
import 'package:hoppa/shared/core/utils/location_utils.dart';

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

class CartState {
  final List<CartItem> items;
  final String? currentBusinessId;

  CartState({
    required this.items,
    this.currentBusinessId,
  });

  double get totalAmount {
    double total = 0.0;
    for (var item in items) {
      total += item.businessProduct.price * item.quantity;
    }
    return total;
  }

  CartState copyWith({
    List<CartItem>? items,
    String? currentBusinessId,
  }) {
    return CartState(
      items: items ?? this.items,
      currentBusinessId: currentBusinessId ?? this.currentBusinessId,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState(items: []));

  void addToCart(BusinessProduct product) {
    final businessId = product.businessId;

    // ALTIN KURAL: Farklı dükkan kontrolü
    if (state.items.isNotEmpty && state.currentBusinessId != null) {
      if (state.currentBusinessId != businessId) {
        throw Exception("Farklı bir dükkandan ürün eklemek için sepeti temizlemelisiniz");
      }
    }

    if (!product.isAvailable) {
      throw Exception("Ürün şu anda temin edilemiyor.");
    }

    final index = state.items.indexWhere(
      (item) => item.businessProduct.id == product.id,
    );

    double increment = product.product.isWeighted ? 0.5 : 1.0;
    double currentQty = index >= 0 ? state.items[index].quantity : 0.0;
    double newQty = currentQty + increment;

    if (newQty > product.stock) {
      throw Exception("Stok yetersiz!");
    }

    final newItems = List<CartItem>.from(state.items);
    if (index >= 0) {
      newItems[index] = state.items[index].copyWith(quantity: newQty);
    } else {
      newItems.add(CartItem(
        businessProduct: product,
        quantity: increment,
      ));
    }

    state = CartState(
      items: newItems,
      currentBusinessId: businessId,
    );
  }

  void removeFromCart(String productId) {
    final index = state.items.indexWhere(
      (item) => item.businessProduct.id == productId,
    );

    if (index >= 0) {
      final item = state.items[index];
      double decrement = item.businessProduct.product.isWeighted ? 0.5 : 1.0;

      final newItems = List<CartItem>.from(state.items);
      if (item.quantity > decrement + 0.01) {
        newItems[index] = item.copyWith(quantity: item.quantity - decrement);
      } else {
        newItems.removeAt(index);
      }

      state = CartState(
        items: newItems,
        currentBusinessId: newItems.isEmpty ? null : state.currentBusinessId,
      );
    }
  }

  void clearCart() {
    state = CartState(items: [], currentBusinessId: null);
  }

  void removeGroup(String groupBy, String groupName) {
    final newItems = state.items.where((item) {
      final key = groupBy == 'brand'
          ? item.businessProduct.product.brand
          : item.businessProduct.product.category;
      return key != groupName;
    }).toList();

    state = CartState(
      items: newItems,
      currentBusinessId: newItems.isEmpty ? null : state.currentBusinessId,
    );
  }
}

// Riverpod Providers
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
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


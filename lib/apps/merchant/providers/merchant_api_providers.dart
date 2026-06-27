import 'package:flutter_riverpod/flutter_riverpod.dart';
// Note: apiClientProvider comes from core_auth but since merchant app uses it we can define or import it.
// Assuming core_auth is imported in merchant_main_layout or we can import it.
import 'package:core_auth/core_auth.dart'; 

import '../repositories/merchant_shop_repository.dart';
import '../repositories/merchant_product_repository.dart';

// --- Repositories ---
final merchantShopRepositoryProvider = Provider<MerchantShopRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MerchantShopRepository(apiClient);
});

final merchantProductRepositoryProvider = Provider<MerchantProductRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MerchantProductRepository(apiClient);
});


// --- Shop Controller ---
class ShopController extends AsyncNotifier<MerchantShop?> {
  @override
  Future<MerchantShop?> build() async {
    return await _fetchShop();
  }

  Future<MerchantShop?> _fetchShop() async {
    final repo = ref.read(merchantShopRepositoryProvider);
    return await repo.getShop();
  }

  Future<void> updateShop(Map<String, dynamic> data) async {
    final currentVal = state.value;
    state = const AsyncLoading();
    try {
      final repo = ref.read(merchantShopRepositoryProvider);

      final payload = Map<String, dynamic>.from(data);

      final updatedShop = await repo.updateShop(payload);
      state = AsyncData(updatedShop);
    } catch (e, st) {
      if (currentVal != null) {
        state = AsyncData(currentVal);
      } else {
        state = AsyncError(e, st);
      }
      rethrow;
    }
  }

  Future<void> toggleStatus(bool isActive) async {
    final currentVal = state.value;
    state = const AsyncLoading();
    try {
      final repo = ref.read(merchantShopRepositoryProvider);
      final updatedShop = await repo.toggleStatus(isActive);
      state = AsyncData(updatedShop);
    } catch (e, st) {
      // Revert on error
      if (currentVal != null) {
        state = AsyncData(currentVal);
      } else {
        state = AsyncError(e, st);
      }
      rethrow;
    }
  }
}

final shopControllerProvider = AsyncNotifierProvider<ShopController, MerchantShop?>(
  ShopController.new,
);


// --- Product Controller ---
class ProductController extends AsyncNotifier<List<MerchantProduct>> {
  @override
  Future<List<MerchantProduct>> build() async {
    return await _fetchProducts();
  }

  Future<List<MerchantProduct>> _fetchProducts() async {
    final repo = ref.read(merchantProductRepositoryProvider);
    return await repo.getProducts();
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    // Optimistic or strict? Strict for now.
    state = const AsyncLoading();
    try {
      final repo = ref.read(merchantProductRepositoryProvider);
      final payload = Map<String, dynamic>.from(data);

      await repo.createProduct(payload);
      // Refetch
      state = AsyncData(await _fetchProducts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addProductFromCatalog(String barcode, double price, int? stock, bool trackStock) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(merchantProductRepositoryProvider);
      await repo.addFromCatalog(barcode, price, stock, trackStock);
      state = AsyncData(await _fetchProducts());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> bulkAddProductFromCatalog(List<Map<String, dynamic>> items) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(merchantProductRepositoryProvider);
      await repo.bulkAddFromCatalog(items);
      state = AsyncData(await _fetchProducts());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(merchantProductRepositoryProvider);
      final payload = Map<String, dynamic>.from(data);

      await repo.updateProduct(id, payload);
      state = AsyncData(await _fetchProducts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteProduct(String id) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(merchantProductRepositoryProvider);
      await repo.deleteProduct(id);
      state = AsyncData(await _fetchProducts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleProductStatus(String id, bool isActive) async {
    try {
      final repo = ref.read(merchantProductRepositoryProvider);
      await repo.updateProduct(id, {'isActive': isActive});
      
      // Update local state without full refetch for speed
      if (state.hasValue) {
        final products = state.value!.map((p) {
          if (p.id == id) {
            return MerchantProduct(
              id: p.id,
              shopId: p.shopId,
              categoryId: p.categoryId,
              name: p.name,
              description: p.description,
              price: p.price,
              discountPrice: p.discountPrice,
              stock: p.stock,
              imageUrl: p.imageUrl,
              isActive: isActive,
              barcode: p.barcode,
              brand: p.brand,
              stockQuantity: p.stockQuantity,
              weightOrVolume: p.weightOrVolume,
              preparationTime: p.preparationTime,
              hasDeposit: p.hasDeposit,
              depositPrice: p.depositPrice,
              unit: p.unit,
              minQuantity: p.minQuantity,
              stepSize: p.stepSize,
              trackStock: p.trackStock,
            );
          }
          return p;
        }).toList();
        state = AsyncData(products);
      }
    } catch (e) {
      rethrow;
    }
  }
}

final productControllerProvider = AsyncNotifierProvider<ProductController, List<MerchantProduct>>(
  ProductController.new,
);

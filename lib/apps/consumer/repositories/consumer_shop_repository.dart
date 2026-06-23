import 'package:core_network/core_network.dart';
import 'package:core_auth/core_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/shared/models/business_product.dart';

class ConsumerShopRepository {
  final ApiClient _apiClient;

  ConsumerShopRepository(this._apiClient);

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Future<List<Business>> getShops() async {
    final response = await _apiClient.get('/api/consumer/shops');
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data.map((json) {
      final id = json['id'] as String? ?? '';
      final map = Map<String, dynamic>.from(json);

      // Map API field differences and apply image URL validation fallbacks
      map['logoUrl'] = _isValidImageUrl(json['imageUrl'])
          ? json['imageUrl']
          : 'https://via.placeholder.com/150';
      map['headerImageUrl'] = _isValidImageUrl(json['headerImageUrl'])
          ? json['headerImageUrl']
          : 'https://via.placeholder.com/150';
      map['isOpen'] = json['isActive'] ?? true;
      map['minBasketAmount'] = json['minOrderAmount'] != null ? double.tryParse(json['minOrderAmount'].toString()) ?? 0.0 : 0.0;
      map['deliveryRadius'] = json['deliveryRadiusKm'] != null ? (json['deliveryRadiusKm'] as num).toDouble() : 5.0;

      if (json['type'] != null) {
        map['type'] = json['type'].toString().toLowerCase();
      }

      return Business.fromMap(map, id);
    }).toList();
  }

  Future<List<BusinessProduct>> getShopProducts(String shopId) async {
    final response = await _apiClient.get('/api/consumer/shops/$shopId/products');
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data.map((json) {
      final id = json['id'] as String? ?? '';
      final name = json['name'] as String? ?? '';
      final description = json['description'] as String? ?? '';
      final price = json['price'] != null ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0;
      final stock = json['stock'] != null ? (int.tryParse(json['stock'].toString()) ?? 0).toDouble() : 0.0;
      final isActive = json['isActive'] as bool? ?? true;
      
      final imageUrl = json['imageUrl'] as String? ?? '';
      final validImageUrl = _isValidImageUrl(imageUrl)
          ? imageUrl
          : 'https://via.placeholder.com/150';

      final categoryName = json['category'] != null ? (json['category']['name'] as String? ?? 'Genel') : 'Genel';

      final productMap = {
        'barcode': id,
        'name': name,
        'brand': 'Hoppa',
        'category': categoryName,
        'subCategory': 'Tümü',
        'imageUrl': validImageUrl,
        'isWeighted': false,
        'description': description,
      };

      final map = {
        'businessId': shopId,
        'productBarcode': id,
        'price': price,
        'stock': stock,
        'isAvailable': isActive,
        'product_details': productMap,
      };

      return BusinessProduct.fromMap(map, id);
    }).toList();
  }
}

// Riverpod Providers
final consumerShopRepositoryProvider = Provider<ConsumerShopRepository>((ref) {
  return ConsumerShopRepository(ref.watch(apiClientProvider));
});

// App Lifecycle Listener for auto-refreshing shops when app resumes
final shopLifecyclePollingProvider = Provider.autoDispose<void>((ref) {
  final listener = AppLifecycleListener(
    onResume: () {
      ref.invalidate(consumerShopsProvider);
    },
  );
  ref.onDispose(() => listener.dispose());
});

final consumerShopsProvider = FutureProvider<List<Business>>((ref) async {
  return ref.watch(consumerShopRepositoryProvider).getShops();
});

final shopProductsProvider = FutureProvider.family<List<BusinessProduct>, String>((ref, shopId) async {
  return ref.watch(consumerShopRepositoryProvider).getShopProducts(shopId);
});

// Catalog Filtering, Sorting and Searching State Providers
final selectedCatalogCategoryProvider = StateProvider<String>((ref) => 'Tümü');
final selectedCatalogSubCategoryProvider = StateProvider<String>((ref) => 'Tümü');
final selectedCatalogSortOptionProvider = StateProvider<String>((ref) => 'Önerilen');
final catalogSearchQueryProvider = StateProvider<String>((ref) => '');

// Combined Filtered and Sorted Products Provider
final filteredShopProductsProvider = Provider.family<AsyncValue<List<BusinessProduct>>, String>((ref, shopId) {
  final productsAsync = ref.watch(shopProductsProvider(shopId));
  final category = ref.watch(selectedCatalogCategoryProvider);
  final subCategory = ref.watch(selectedCatalogSubCategoryProvider);
  final sortOption = ref.watch(selectedCatalogSortOptionProvider);
  final searchQuery = ref.watch(catalogSearchQueryProvider);

  return productsAsync.whenData((allProducts) {
    var list = allProducts;
    
    // If searching, ignore category and subcategory filters to search globally
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((p) {
        final prod = p.product;
        return prod.name.toLowerCase().contains(query) ||
               prod.brand.toLowerCase().contains(query) ||
               prod.category.toLowerCase().contains(query) ||
               prod.subCategory.toLowerCase().contains(query);
      }).toList();
    } else {
      // 1. Filter by category
      if (category != 'Tümü') {
        list = list.where((p) => p.product.category == category).toList();
      }
      
      // 2. Filter by subcategory
      if (subCategory != 'Tümü') {
        list = list.where((p) => p.product.subCategory == subCategory).toList();
      }
    }

    // 4. Sort products
    list = List<BusinessProduct>.from(list);
    switch (sortOption) {
      case 'Fiyat Artan':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Fiyat Azalan':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'İsim A-Z':
        list.sort((a, b) => a.product.name.compareTo(b.product.name));
        break;
      case 'İsim Z-A':
        list.sort((a, b) => b.product.name.compareTo(a.product.name));
        break;
    }
    return list;
  });
});


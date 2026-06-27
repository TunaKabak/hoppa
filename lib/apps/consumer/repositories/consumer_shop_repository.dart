import 'package:core_network/core_network.dart';
import 'package:core_auth/core_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/shared/models/business_product.dart';
import 'package:hoppa/shared/models/shop_category_data.dart';

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

      String categoryName = 'Genel';
      String subCategoryName = 'Tümü';

      if (json['category'] != null) {
        print("DEBUG CATEGORY: ${json['category']}");
        final cat = json['category'];
        if (cat['parent'] != null) {
          categoryName = cat['parent']['name'] as String? ?? 'Genel';
          subCategoryName = cat['name'] as String? ?? 'Tümü';
        } else {
          categoryName = cat['name'] as String? ?? 'Genel';
        }
      } else {
        print("DEBUG CATEGORY: null");
      }

      final trackStock = json['trackStock'] as bool? ?? false;
      final stockQuantity = json['stockQuantity'] as int? ?? 0;

      final productMap = {
        'barcode': json['barcode'] ?? id,
        'name': name,
        'brand': json['brand'] ?? 'Hoppa',
        'category': categoryName,
        'subCategory': subCategoryName,
        'imageUrl': validImageUrl,
        'isWeighted': json['unit'] == 'KG' || json['unit'] == 'LITRE' || json['unit'] == 'GR' || (json['isWeighted'] == true),
        'description': description,
        'unit': json['unit'] ?? 'ADET',
        'minQuantity': json['minQuantity'] != null ? double.tryParse(json['minQuantity'].toString()) : null,
        'stepSize': json['stepSize'] != null ? double.tryParse(json['stepSize'].toString()) : null,
      };

      final map = {
        'businessId': shopId,
        'productBarcode': json['barcode'] ?? id,
        'price': price,
        'stock': stock,
        'isAvailable': isActive,
        'trackStock': trackStock,
        'stockQuantity': stockQuantity,
        'product_details': productMap,
      };

      return BusinessProduct.fromMap(map, id);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getFavoriteProducts(List<String> productIds) async {
    if (productIds.isEmpty) return [];
    
    final response = await _apiClient.post('/api/consumer/favorites/products', body: {
      'productIds': productIds
    });
    
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    
    return data.map((item) {
      final productJson = item['product'];
      final isAvailable = item['isAvailable'] as bool? ?? false;
      
      final id = productJson['id'] as String? ?? '';
      final shopId = productJson['shopId'] as String? ?? '';
      final name = productJson['name'] as String? ?? '';
      final description = productJson['description'] as String? ?? '';
      final price = productJson['price'] != null ? double.tryParse(productJson['price'].toString()) ?? 0.0 : 0.0;
      final stock = productJson['stock'] != null ? (int.tryParse(productJson['stock'].toString()) ?? 0).toDouble() : 0.0;
      final isActive = productJson['isActive'] as bool? ?? true;
      
      final imageUrl = productJson['imageUrl'] as String? ?? '';
      final validImageUrl = _isValidImageUrl(imageUrl)
          ? imageUrl
          : 'https://via.placeholder.com/150';

      String categoryName = 'Genel';
      String subCategoryName = 'Tümü';

      if (productJson['category'] != null) {
        final cat = productJson['category'];
        if (cat['parent'] != null) {
          categoryName = cat['parent']['name'] as String? ?? 'Genel';
          subCategoryName = cat['name'] as String? ?? 'Tümü';
        } else {
          categoryName = cat['name'] as String? ?? 'Genel';
        }
      }

      final trackStock = productJson['trackStock'] as bool? ?? false;
      final stockQuantity = productJson['stockQuantity'] as int? ?? 0;

      final productMap = {
        'barcode': productJson['barcode'] ?? id,
        'name': name,
        'brand': productJson['brand'] ?? 'Hoppa',
        'category': categoryName,
        'subCategory': subCategoryName,
        'imageUrl': validImageUrl,
        'isWeighted': productJson['unit'] == 'KG' || productJson['unit'] == 'LITRE' || productJson['unit'] == 'GR' || (productJson['isWeighted'] == true),
        'description': description,
        'unit': productJson['unit'] ?? 'ADET',
        'minQuantity': productJson['minQuantity'] != null ? double.tryParse(productJson['minQuantity'].toString()) : null,
        'stepSize': productJson['stepSize'] != null ? double.tryParse(productJson['stepSize'].toString()) : null,
      };

      final map = {
        'businessId': shopId,
        'productBarcode': productJson['barcode'] ?? id,
        'price': price,
        'stock': stock,
        'isAvailable': isActive,
        'trackStock': trackStock,
        'stockQuantity': stockQuantity,
        'product_details': productMap,
      };

      final bp = BusinessProduct.fromMap(map, id);
      return {
        'product': bp,
        'isAvailable': isAvailable,
      };
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

final shopCategoriesProvider = FutureProvider.family<List<ShopCategoryData>, String>((ref, shopId) async {
  final repo = ref.watch(consumerShopRepositoryProvider);
  final response = await repo._apiClient.get('/api/consumer/shops/$shopId/categories');
  final data = response['data'] as List<dynamic>?;
  if (data == null) return [];
  
  return data.map((c) {
    final catMap = Map<String, dynamic>.from(c);
    final subList = catMap['children'] as List<dynamic>? ?? [];
    final subNames = ['Tümü'] + subList.map((s) => s['name'] as String).toList();
    
    return ShopCategoryData(
      id: catMap['id'] as String? ?? '',
      name: catMap['name'] as String? ?? '',
      iconName: catMap['iconName'] as String? ?? 'shopping_basket',
      subCategories: subNames,
    );
  }).toList();
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


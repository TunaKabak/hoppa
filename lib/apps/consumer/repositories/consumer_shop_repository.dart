import 'package:core_network/core_network.dart';
import 'package:core_auth/core_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/shared/models/business_product.dart';
import 'package:hoppa/shared/models/shop_category_data.dart';
import 'package:hoppa/shared/models/category_model.dart';
import 'package:hoppa/shared/models/campaign.dart';

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
      map['minBasketAmount'] = json['minOrderAmount'] != null
          ? double.tryParse(json['minOrderAmount'].toString()) ?? 0.0
          : 0.0;
      map['deliveryRadius'] = json['deliveryRadiusKm'] != null
          ? (json['deliveryRadiusKm'] as num).toDouble()
          : 5.0;
      map['averageRating'] = json['averageRating'] != null
          ? double.tryParse(json['averageRating'].toString()) ?? 5.0
          : 5.0;
      map['reviewCount'] = json['reviewCount'] as int? ?? 0;

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

      final double regularPriceVal = json['regularPrice'] != null ? (double.tryParse(json['regularPrice'].toString()) ?? price) : price;
      final int discountRateVal = json['discountRate'] as int? ?? 0;

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
        'regularPrice': regularPriceVal,
        'shownPrice': price,
        'discountRate': discountRateVal,
        'sku': json['sku'],
        'prettyName': json['prettyName'],
      };

      final map = {
        'businessId': shopId,
        'productBarcode': json['barcode'] ?? id,
        'price': price,
        'stock': stock,
        'isAvailable': isActive,
        'trackStock': trackStock,
        'stockQuantity': stockQuantity,
        'regularPrice': regularPriceVal,
        'discountRate': discountRateVal,
        'product_details': productMap,
      };

      return BusinessProduct.fromMap(map, id);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getFavoriteProducts(List<String> productIds) async {
    try {
      final response = await _apiClient.get('/api/consumer/favorites/products');
      
      final data = response['data'] as List<dynamic>?;
      if (data == null) return [];
      
      return data.map((item) {
        final productJson = item['product'] ?? item;
        final isAvailable = item['isAvailable'] as bool? ?? productJson['isActive'] as bool? ?? true;
        
        final id = productJson['id'] as String? ?? '';
        final shopId = productJson['shopId'] as String? ?? '';
        final name = productJson['name'] as String? ?? '';
        final description = productJson['description'] as String? ?? '';
        
        double price = 0.0;
        if (productJson['price'] != null) {
          price = double.tryParse(productJson['price'].toString()) ?? 0.0;
        }

        double stock = 0.0;
        if (productJson['stock'] != null) {
          stock = (int.tryParse(productJson['stock'].toString()) ?? 0).toDouble();
        }

        final isActive = productJson['isActive'] as bool? ?? true;
        
        final imageUrl = productJson['imageUrl'] as String? ?? '';
        final validImageUrl = _isValidImageUrl(imageUrl)
            ? imageUrl
            : 'https://via.placeholder.com/150';

        String categoryName = 'Genel';
        String subCategoryName = 'Tümü';

        if (productJson['category'] != null) {
          final cat = productJson['category'];
          categoryName = cat is Map ? (cat['name'] as String? ?? 'Genel') : cat.toString();
        }
        if (productJson['subCategory'] != null) {
          final sub = productJson['subCategory'];
          subCategoryName = sub is Map ? (sub['name'] as String? ?? 'Tümü') : sub.toString();
        }

        final trackStock = productJson['trackStock'] as bool? ?? false;
        final stockQuantity = productJson['stockQuantity'] as int? ?? 0;

        final unitVal = productJson['unit'];
        final unitCode = unitVal is Map ? (unitVal['code'] as String? ?? 'ADET') : (unitVal as String? ?? 'ADET');
        final isWeighted = unitCode == 'KG' || unitCode == 'LITRE' || unitCode == 'GR' || (productJson['isWeighted'] == true);

        final brandVal = productJson['brand'];
        final brandName = brandVal is Map ? (brandVal['name'] as String? ?? 'Hoppa') : (brandVal as String? ?? 'Hoppa');

        final double regularPriceVal = productJson['regularPrice'] != null ? (double.tryParse(productJson['regularPrice'].toString()) ?? price) : price;
        final int discountRateVal = productJson['discountRate'] as int? ?? 0;

        final productMap = {
          'barcode': productJson['barcode'] ?? id,
          'name': name,
          'brand': brandName,
          'category': categoryName,
          'subCategory': subCategoryName,
          'imageUrl': validImageUrl,
          'isWeighted': isWeighted,
          'description': description,
          'unit': unitCode,
          'minQuantity': productJson['minQuantity'] != null ? double.tryParse(productJson['minQuantity'].toString()) : null,
          'stepSize': productJson['stepSize'] != null ? double.tryParse(productJson['stepSize'].toString()) : null,
          'regularPrice': regularPriceVal,
          'shownPrice': price,
          'discountRate': discountRateVal,
          'sku': productJson['sku'],
          'prettyName': productJson['prettyName'],
        };

        final map = {
          'businessId': shopId,
          'productBarcode': productJson['barcode'] ?? id,
          'price': price,
          'stock': trackStock ? stockQuantity.toDouble() : stock,
          'isAvailable': isActive,
          'trackStock': trackStock,
          'stockQuantity': stockQuantity,
          'regularPrice': regularPriceVal,
          'discountRate': discountRateVal,
          'product_details': productMap,
        };

        final bp = BusinessProduct.fromMap(map, id);
        return {
          'product': bp,
          'isAvailable': isAvailable,
        };
      }).toList();
    } catch (e) {
      print("Favori ürünleri çekme hatası (Flutter): $e");
      return [];
    }
  }

  Future<List<Campaign>> getCampaigns() async {
    try {
      final response = await _apiClient.get('/api/consumer/campaigns');
      final data = response['data'] as List<dynamic>?;
      if (data == null) return [];
      return data.map((json) {
        final id = json['id']?.toString() ?? '';
        final map = Map<String, dynamic>.from(json);
        map['vendorId'] = json['vendorId'] ?? '';
        map['name'] = json['title'] ?? json['name'] ?? 'Adsız Kampanya';
        map['type'] = json['type'] == 'PERCENTAGE_DISCOUNT' ? 'percentage' : 'fixed_price';
        map['discountValue'] = json['discountValue'] != null ? double.tryParse(json['discountValue'].toString()) ?? 0.0 : 0.0;
        map['startDate'] = json['createdAt'] ?? DateTime.now().toIso8601String();
        map['endDate'] = json['finishDate'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String();
        map['imageUrl'] = json['imageUrl'] ?? '';
        map['description'] = json['description'] ?? '';
        map['isActive'] = json['isActive'] ?? true;
        return Campaign.fromMap(map, id);
      }).toList();
    } catch (e) {
      print("Error fetching campaigns from REST: $e");
      return [];
    }
  }
}

// Riverpod Providers
final consumerShopRepositoryProvider = Provider<ConsumerShopRepository>((ref) {
  return ConsumerShopRepository(ref.watch(apiClientProvider));
});

final activeCampaignsProvider = FutureProvider<List<Campaign>>((ref) async {
  return ref.watch(consumerShopRepositoryProvider).getCampaigns();
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

final shopCategoryTreeProvider = FutureProvider.family<List<Category>, String>((ref, shopId) async {
  final repo = ref.watch(consumerShopRepositoryProvider);
  final response = await repo._apiClient.get('/api/consumer/shops/$shopId/categories');
  final data = response['data'] as List<dynamic>?;
  if (data == null) return [];
  
  return data.map((c) {
    final catMap = Map<String, dynamic>.from(c);
    return Category.fromMap(catMap, catMap['id']?.toString() ?? '');
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


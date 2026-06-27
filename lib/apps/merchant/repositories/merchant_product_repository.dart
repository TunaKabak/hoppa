import 'package:core_network/core_network.dart';

class MerchantProduct {
  final String id;
  final String shopId;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final double? discountPrice;
  final int? stock;
  final String? imageUrl;
  final bool isActive;
  final String? barcode;
  final String? brand;
  final int? stockQuantity;
  final String? weightOrVolume;
  final int? preparationTime;
  final bool? hasDeposit;
  final double? depositPrice;
  final String unit;
  final double minQuantity;
  final double stepSize;
  final bool trackStock; // YENİ

  MerchantProduct({
    required this.id,
    required this.shopId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.discountPrice,
    this.stock,
    this.imageUrl,
    this.isActive = true,
    this.barcode,
    this.brand,
    this.stockQuantity = 0,
    this.weightOrVolume,
    this.preparationTime,
    this.hasDeposit = false,
    this.depositPrice,
    this.unit = "ADET",
    this.minQuantity = 1.0,
    this.stepSize = 1.0,
    this.trackStock = false,
  });

  factory MerchantProduct.fromMap(Map<String, dynamic> map) {
    return MerchantProduct(
      id: map['id'] ?? '',
      shopId: map['shopId'] ?? '',
      categoryId: map['categoryId'],
      name: map['name'] ?? '',
      description: map['description'],
      price: map['price'] != null ? double.tryParse(map['price'].toString()) ?? 0.0 : 0.0,
      discountPrice: map['discountPrice'] != null ? double.tryParse(map['discountPrice'].toString()) : null,
      stock: map['stock'] != null ? int.tryParse(map['stock'].toString()) : null,
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      barcode: map['barcode'],
      brand: map['brand'],
      stockQuantity: map['stockQuantity'] != null ? int.tryParse(map['stockQuantity'].toString()) : null,
      weightOrVolume: map['weightOrVolume'],
      preparationTime: map['preparationTime'] != null ? int.tryParse(map['preparationTime'].toString()) : null,
      hasDeposit: map['hasDeposit'] ?? false,
      depositPrice: map['depositPrice'] != null ? double.tryParse(map['depositPrice'].toString()) : null,
      unit: map['unit'] ?? "ADET",
      minQuantity: map['minQuantity'] != null ? double.tryParse(map['minQuantity'].toString()) ?? 1.0 : 1.0,
      stepSize: map['stepSize'] != null ? double.tryParse(map['stepSize'].toString()) ?? 1.0 : 1.0,
      trackStock: map['trackStock'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'stock': stock,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'barcode': barcode,
      'brand': brand,
      'stockQuantity': stockQuantity,
      'weightOrVolume': weightOrVolume,
      'preparationTime': preparationTime,
      'hasDeposit': hasDeposit,
      'depositPrice': depositPrice,
      'unit': unit,
      'minQuantity': minQuantity,
      'stepSize': stepSize,
      'trackStock': trackStock,
    };
  }
}

class CatalogFilters {
  final List<String> categories;
  final List<String> brands;

  CatalogFilters({required this.categories, required this.brands});

  factory CatalogFilters.fromMap(Map<String, dynamic> map) {
    return CatalogFilters(
      categories: List<String>.from(map['categories'] ?? []),
      brands: List<String>.from(map['brands'] ?? []),
    );
  }
}

class CatalogProduct {
  final String id;
  final String barcode;
  final String name;
  final String brand;
  final String category;
  final String? subCategory;
  final String imageUrl;
  final bool isWeighted;
  final String? description;
  final String unit;
  final double minQuantity;
  final double stepSize;

  CatalogProduct({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    this.subCategory,
    required this.imageUrl,
    this.isWeighted = false,
    this.description,
    this.unit = "ADET",
    this.minQuantity = 1.0,
    this.stepSize = 1.0,
  });

  factory CatalogProduct.fromMap(Map<String, dynamic> map) {
    return CatalogProduct(
      id: map['id'] ?? '',
      barcode: map['barcode'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'],
      imageUrl: map['imageUrl'] ?? '',
      isWeighted: map['isWeighted'] ?? false,
      description: map['description'],
      unit: map['unit'] ?? "ADET",
      minQuantity: map['minQuantity'] != null ? double.tryParse(map['minQuantity'].toString()) ?? 1.0 : 1.0,
      stepSize: map['stepSize'] != null ? double.tryParse(map['stepSize'].toString()) ?? 1.0 : 1.0,
    );
  }
}

class MerchantProductRepository {
  final ApiClient _apiClient;

  MerchantProductRepository(this._apiClient);

  Future<List<MerchantProduct>> getProducts() async {
    final response = await _apiClient.get('/api/merchant/products');
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    
    return data.map((json) => MerchantProduct.fromMap(json)).toList();
  }

  Future<MerchantProduct> createProduct(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/api/merchant/products', body: data);
    return MerchantProduct.fromMap(response['data']);
  }

  Future<MerchantProduct> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/api/merchant/products/$id', body: data);
    return MerchantProduct.fromMap(response['data']);
  }

  Future<void> deleteProduct(String id) async {
    await _apiClient.delete('/api/merchant/products/$id');
  }

  // Global katalogda arama ve filtreleme yapar
  Future<List<CatalogProduct>> searchCatalog(String query, {String? category, String? brand, int page = 1, int limit = 20}) async {
    String url = '/api/merchant/products/catalog?page=$page&limit=$limit';
    if (query.isNotEmpty) {
      url += '&q=${Uri.encodeComponent(query)}';
    }
    if (category != null && category.isNotEmpty) {
      url += '&category=${Uri.encodeComponent(category)}';
    }
    if (brand != null && brand.isNotEmpty) {
      url += '&brand=${Uri.encodeComponent(brand)}';
    }
    
    final response = await _apiClient.get(url);
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];

    return data.map((json) => CatalogProduct.fromMap(json)).toList();
  }

  // Katalog filtrelerini (kategori ve markaları) çeker
  Future<CatalogFilters> getCatalogFilters() async {
    final response = await _apiClient.get('/api/merchant/products/catalog/filters');
    return CatalogFilters.fromMap(response['data'] ?? {});
  }

  // Katalogdan dükkan envanterine tekil ürün kopyalar
  Future<void> addFromCatalog(String barcode, double price, int? stock, bool trackStock) async {
    await _apiClient.post(
      '/api/merchant/products/catalog/add',
      body: {
        'barcode': barcode,
        'price': price,
        'stock': stock,
        'trackStock': trackStock,
      },
    );
  }

  // Katalogdan dükkan envanterine toplu ürün ekler
  Future<void> bulkAddFromCatalog(List<Map<String, dynamic>> items) async {
    await _apiClient.post(
      '/api/merchant/products/catalog/bulk-add',
      body: {
        'items': items,
      },
    );
  }
}

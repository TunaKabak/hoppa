class ProductOption {
  final String id;
  final String name;
  final double price;
  final bool isActive;

  ProductOption({
    required this.id,
    required this.name,
    required this.price,
    this.isActive = true,
  });

  factory ProductOption.fromMap(Map<String, dynamic> map) {
    return ProductOption(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] != null ? (double.tryParse(map['price'].toString()) ?? 0.0) : 0.0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isActive': isActive,
    };
  }
}

class ProductOptionGroup {
  final String id;
  final String name;
  final int minSelections;
  final int maxSelections;
  final List<ProductOption> options;

  ProductOptionGroup({
    required this.id,
    required this.name,
    required this.minSelections,
    required this.maxSelections,
    required this.options,
  });

  factory ProductOptionGroup.fromMap(Map<String, dynamic> map) {
    var rawOpts = map['options'] as List<dynamic>? ?? [];
    List<ProductOption> parsedOpts = rawOpts
        .map((o) => ProductOption.fromMap(Map<String, dynamic>.from(o)))
        .toList();

    return ProductOptionGroup(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      minSelections: map['minSelections'] as int? ?? 0,
      maxSelections: map['maxSelections'] as int? ?? 1,
      options: parsedOpts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'minSelections': minSelections,
      'maxSelections': maxSelections,
      'options': options.map((o) => o.toMap()).toList(),
    };
  }
}

class Product {
  final String barcode; // ID yerine Barkod
  final String name;
  final String brand;
  final String category;
  final String subCategory;
  final String imageUrl;
  final bool isWeighted;
  final String description; // YENİ
  final String unit; // YENİ: e.g. "KG", "ADET"
  final double minQuantity; // YENİ: e.g. 0.5
  final double stepSize; // YENİ: e.g. 0.25
  final double? regularPrice; // YENİ
  final double? shownPrice; // YENİ
  final int discountRate; // YENİ
  final String? sku; // YENİ
  final String? prettyName; // YENİ
  final List<ProductOptionGroup> optionGroups; // YENİ: Seçenek Grupları

  Product({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    required this.subCategory,
    required this.imageUrl,
    required this.isWeighted,
    this.description = '', // Varsayılan boş
    this.unit = 'ADET',
    this.minQuantity = 1.0,
    this.stepSize = 1.0,
    this.regularPrice,
    this.shownPrice,
    this.discountRate = 0,
    this.sku,
    this.prettyName,
    this.optionGroups = const [],
  });

  factory Product.fromMap(Map<String, dynamic> data) {
    final isWeighted = data['isWeighted'] ?? false;
    final defaultMinQty = isWeighted ? 0.5 : 1.0;
    final defaultStep = isWeighted ? 0.5 : 1.0;

    // 1. Görsel Fallback Zinciri (Local -> Global -> Placeholder)
    final String? localImage = data['imageUrl'] as String?;
    final String? globalImage = data['globalProduct'] != null 
        ? data['globalProduct']['imageUrl'] as String? 
        : null;

    // 2. Birim Tip Güvenliği Kontrolü (String veya Map gelebilir)
    String parsedUnit = "ADET";
    if (data['unit'] != null) {
      if (data['unit'] is Map) {
        parsedUnit = (data['unit']['code'] as String?) ?? "ADET";
      } else {
        parsedUnit = data['unit'] as String;
      }
    }

    // 3. Seçenek Grupları Çözümleme
    var rawGroups = data['optionGroups'] as List<dynamic>? ?? [];
    List<ProductOptionGroup> parsedGroups = rawGroups
        .map((g) => ProductOptionGroup.fromMap(Map<String, dynamic>.from(g)))
        .toList();

    return Product(
      barcode: data['barcode'] ?? '',
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['subCategory'] ?? '',
      imageUrl: localImage ?? globalImage ?? "https://placehold.co/150",
      isWeighted: isWeighted,
      description: data['description'] ?? '',
      unit: parsedUnit,
      minQuantity: data['minQuantity'] != null
          ? (double.tryParse(data['minQuantity'].toString()) ?? defaultMinQty)
          : defaultMinQty,
      stepSize: data['stepSize'] != null
          ? (double.tryParse(data['stepSize'].toString()) ?? defaultStep)
          : defaultStep,
      regularPrice: data['regularPrice'] != null ? double.tryParse(data['regularPrice'].toString()) : null,
      shownPrice: data['shownPrice'] != null ? double.tryParse(data['shownPrice'].toString()) : null,
      discountRate: data['discountRate'] as int? ?? 0,
      sku: data['sku'] as String?,
      prettyName: data['prettyName'] as String?,
      optionGroups: parsedGroups,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'category': category,
      'subCategory': subCategory,
      'imageUrl': imageUrl,
      'isWeighted': isWeighted,
      'description': description,
      'unit': unit,
      'minQuantity': minQuantity,
      'stepSize': stepSize,
      'regularPrice': regularPrice,
      'shownPrice': shownPrice,
      'discountRate': discountRate,
      'sku': sku,
      'prettyName': prettyName,
      'optionGroups': optionGroups.map((g) => g.toMap()).toList(),
    };
  }
}

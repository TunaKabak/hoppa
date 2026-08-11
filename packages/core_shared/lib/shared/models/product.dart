enum OptionGroupType {
  variation,
  ingredient,
  sideProduct,
  extra,
}

enum SelectionType {
  radio,
  checkbox,
  counter,
}

enum OptionAction {
  add,
  remove,
}

class ProductOption {
  final String id;
  final String name;
  final double price;
  final bool isDefault;
  final bool isRemovable;
  final int maxQuantity;
  final String? linkedProductId;
  final int displayOrder;
  final bool isActive;

  ProductOption({
    required this.id,
    required this.name,
    required this.price,
    this.isDefault = false,
    this.isRemovable = false,
    this.maxQuantity = 1,
    this.linkedProductId,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory ProductOption.fromMap(Map<String, dynamic> map) {
    return ProductOption(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] != null ? (double.tryParse(map['price'].toString()) ?? 0.0) : 0.0,
      isDefault: map['isDefault'] ?? false,
      isRemovable: map['isRemovable'] ?? false,
      maxQuantity: map['maxQuantity'] as int? ?? 1,
      linkedProductId: map['linkedProductId'] as String?,
      displayOrder: map['displayOrder'] as int? ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isDefault': isDefault,
      'isRemovable': isRemovable,
      'maxQuantity': maxQuantity,
      'linkedProductId': linkedProductId,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }
}

class ProductOptionGroup {
  final String id;
  final String name;
  final String? description;
  final String type; // VARIATION, INGREDIENT, SIDE_PRODUCT, EXTRA
  final String selectionType; // RADIO, CHECKBOX, COUNTER
  final int minSelections;
  final int maxSelections;
  final int freeSelectionsCount;
  final int displayOrder;
  final List<ProductOption> options;

  ProductOptionGroup({
    required this.id,
    required this.name,
    this.description,
    this.type = 'EXTRA',
    this.selectionType = 'CHECKBOX',
    required this.minSelections,
    required this.maxSelections,
    this.freeSelectionsCount = 0,
    this.displayOrder = 0,
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
      description: map['description'] as String?,
      type: (map['type'] as String?)?.toUpperCase() ?? 'EXTRA',
      selectionType: (map['selectionType'] as String?)?.toUpperCase() ?? 'CHECKBOX',
      minSelections: map['minSelections'] as int? ?? 0,
      maxSelections: map['maxSelections'] as int? ?? 1,
      freeSelectionsCount: map['freeSelectionsCount'] as int? ?? 0,
      displayOrder: map['displayOrder'] as int? ?? 0,
      options: parsedOpts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'selectionType': selectionType,
      'minSelections': minSelections,
      'maxSelections': maxSelections,
      'freeSelectionsCount': freeSelectionsCount,
      'displayOrder': displayOrder,
      'options': options.map((o) => o.toMap()).toList(),
    };
  }
}

class SelectedProductOption {
  final String? optionId;
  final String groupName;
  final String name;
  final double price;
  final int quantity;
  final String actionType; // ADD, REMOVE

  SelectedProductOption({
    this.optionId,
    required this.groupName,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.actionType = 'ADD',
  });

  factory SelectedProductOption.fromMap(Map<String, dynamic> map) {
    return SelectedProductOption(
      optionId: map['optionId'] as String?,
      groupName: map['groupName'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] != null ? (double.tryParse(map['price'].toString()) ?? 0.0) : 0.0,
      quantity: map['quantity'] as int? ?? 1,
      actionType: map['actionType'] ?? 'ADD',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'optionId': optionId,
      'groupName': groupName,
      'name': name,
      'price': price,
      'quantity': quantity,
      'actionType': actionType,
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

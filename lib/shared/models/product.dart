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
    };
  }
}

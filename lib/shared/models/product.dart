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

    return Product(
      barcode: data['barcode'] ?? '',
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['subCategory'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isWeighted: isWeighted,
      description: data['description'] ?? '',
      unit: data['unit'] ?? 'ADET',
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

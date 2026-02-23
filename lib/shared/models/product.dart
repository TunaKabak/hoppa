class Product {
  final String barcode; // ID yerine Barkod
  final String name;
  final String brand;
  final String category;
  final String subCategory;
  final String imageUrl;
  final bool isWeighted;
  final String description; // YENİ

  Product({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    required this.subCategory,
    required this.imageUrl,
    required this.isWeighted,
    this.description = '', // Varsayılan boş
  });

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      barcode: data['barcode'] ?? '',
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['subCategory'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isWeighted: data['isWeighted'] ?? false,
      description: data['description'] ?? '',
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
    };
  }
}

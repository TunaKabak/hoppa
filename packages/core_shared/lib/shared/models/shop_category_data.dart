class ShopCategoryData {
  final String id;
  final String name;
  final String iconName;
  final String? backgroundImage;
  final List<String> subCategories;

  ShopCategoryData({
    required this.id,
    required this.name,
    required this.iconName,
    this.backgroundImage,
    required this.subCategories,
  });
}

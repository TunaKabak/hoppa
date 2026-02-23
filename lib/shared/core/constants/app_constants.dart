class AppConstants {
  // Firebase
  static const String marketId = 'market_01';
  static const String defaultCurrency = '₺';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String categoriesCollection = 'categories';

  // Pagination
  static const int itemsPerPage = 20;

  // Timeouts
  static const int connectTimeout = 10;
  static const int receiveTimeout = 10;

  // Phone Number
  static const String countryCode = '+90';
  static const String phoneRegex = r'^[0-9]{10}$';

  // Order ID Prefix
  static const String orderIdPrefix = 'ord_';

  // Product Categories
  static const List<String> defaultCategories = [
    'Su & İçecek',
    'Gıda',
    'Temizlik Ürünleri',
    'Kişisel Bakım',
    'Diğer',
  ];
}

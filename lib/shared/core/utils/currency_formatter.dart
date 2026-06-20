import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
  );

  /// Format price to currency string
  /// Example: 150.50 -> "₺150,50"
  static String formatPrice(double price) {
    return _currencyFormat.format(price);
  }

  /// Parse currency string to double
  static double parsePrice(String price) {
    return double.tryParse(price.replaceAll('₺', '').replaceAll(',', '.')) ?? 0;
  }

  /// Format price with 2 decimal places
  static String formatPriceSimple(double price) {
    return '₺${price.toStringAsFixed(2)}';
  }
}

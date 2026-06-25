import 'dart:math' as math;

class QuantityFormatter {
  /// Round a double to a certain number of decimal places to avoid floating point precision issues.
  static double roundDouble(double val, {int places = 2}) {
    double mod = math.pow(10.0, places).toDouble();
    return ((val * mod).round().toDouble() / mod);
  }

  /// Format a quantity with unit, respecting integer vs decimal representations.
  /// Example: 1.5 KG, 2 ADET
  static String format(double qty, String unit) {
    final rounded = roundDouble(qty);
    if (rounded == rounded.roundToDouble()) {
      return "${rounded.toInt()} $unit";
    }
    return "${rounded.toStringAsFixed(2)} $unit";
  }

  /// Format quantity as a value only, avoiding floating point weirdness.
  /// Example: "1.5", "2"
  static String formatValueOnly(double qty) {
    final rounded = roundDouble(qty);
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(2);
  }
}

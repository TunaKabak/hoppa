import 'dart:math';

class LocationUtils {
  /// Calculate the distance between two geographical points using the Haversine formula
  /// Returns the distance in kilometers.
  static double calculateDistanceInKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const int earthRadiusKm = 6371;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    lat1 = _degreesToRadians(lat1);
    lat2 = _degreesToRadians(lat2);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Formats distance in km or meters:
  /// - If distance is less than 1.0 km, formats in meters (e.g., "350 m")
  /// - If distance is 1.0 km or more, formats in kilometers (e.g., "1.2 km")
  static String formatDistance(double km) {
    if (km <= 0) return '0 m';
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}

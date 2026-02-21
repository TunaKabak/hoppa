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
}

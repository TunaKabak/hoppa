import 'dart:math' as math;

/// Calculates the great-circle distance between two coordinates in kilometers
/// using the Haversine formula.
double calculateDistanceKm({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const double earthRadiusKm = 6371.0;

  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);

  final double radLat1 = _degreesToRadians(lat1);
  final double radLat2 = _degreesToRadians(lat2);

  final double a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(radLat1) *
          math.cos(radLat2) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;

/// Formats distance in meters when below 1 km (e.g. "350 m") and in
/// kilometers with one decimal place otherwise (e.g. "2.4 km").
String formatDistance(double km) {
  if (km <= 0) return '0 m';
  if (km < 1.0) {
    return '${(km * 1000).round()} m';
  }
  return '${km.toStringAsFixed(1)} km';
}

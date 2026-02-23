class Address {
  final String id;
  final String title;
  final String city;
  final String district;
  final String fullDetails;
  // YENİ ALANLAR:
  final double latitude;
  final double longitude;

  Address({
    required this.id,
    required this.title,
    required this.city,
    required this.district,
    required this.fullDetails,
    this.latitude = 0.0, // Varsayılan
    this.longitude = 0.0,
  });

  factory Address.fromMap(Map<String, dynamic> data, String id) {
    return Address(
      id: id,
      title: data['title'] ?? 'Adresim',
      city: data['city'] ?? '',
      district: data['district'] ?? '',
      fullDetails: data['fullDetails'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'city': city,
      'district': district,
      'fullDetails': fullDetails,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get formattedAddress => "$district, $city - $fullDetails";
}

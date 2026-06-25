class CourierLocation {
  final String id;
  final String courierId;
  final double latitude;
  final double longitude;
  final double bearing;
  final DateTime updatedAt;

  CourierLocation({
    required this.id,
    required this.courierId,
    required this.latitude,
    required this.longitude,
    required this.bearing,
    required this.updatedAt,
  });

  factory CourierLocation.fromJson(Map<String, dynamic> json) {
    return CourierLocation(
      id: json['id']?.toString() ?? '',
      courierId: json['courierId']?.toString() ?? json['courier_id']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      bearing: double.tryParse(json['bearing']?.toString() ?? '') ?? 0.0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courierId': courierId,
      'latitude': latitude,
      'longitude': longitude,
      'bearing': bearing,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

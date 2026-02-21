class DeliveryTier {
  /// The maximum distance (in kilometers) this tier applies to.
  final double maxDistance;

  /// The minimum basket amount required for this tier.
  final double minAmount;

  DeliveryTier({required this.maxDistance, required this.minAmount});

  factory DeliveryTier.fromMap(Map<String, dynamic> data) {
    return DeliveryTier(
      maxDistance: (data['maxDistance'] ?? 0.0).toDouble(),
      minAmount: (data['minAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'maxDistance': maxDistance, 'minAmount': minAmount};
  }

  DeliveryTier copyWith({double? maxDistance, double? minAmount}) {
    return DeliveryTier(
      maxDistance: maxDistance ?? this.maxDistance,
      minAmount: minAmount ?? this.minAmount,
    );
  }
}

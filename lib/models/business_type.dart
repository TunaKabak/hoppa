enum BusinessType {
  market,
  restaurant,
  cafe,
  butcher, // Kasap
  greengrocer, // Manav
  bakery, // Fırın
  water, // Su
  nuts, // Kuruyemiş
  florist, // Çiçekçi
  other;

  String get label {
    switch (this) {
      case BusinessType.market:
        return 'Market';
      case BusinessType.restaurant:
        return 'Restoran';
      case BusinessType.cafe:
        return 'Cafe';
      case BusinessType.butcher:
        return 'Kasap';
      case BusinessType.greengrocer:
        return 'Manav';
      case BusinessType.bakery:
        return 'Fırın';
      case BusinessType.water:
        return 'Su';
      case BusinessType.nuts:
        return 'Kuruyemiş';
      case BusinessType.florist:
        return 'Çiçek';
      case BusinessType.other:
        return 'Diğer';
    }
  }

  static BusinessType fromString(String value) {
    return BusinessType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BusinessType.other,
    );
  }
}

class BusinessCategory {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String? badge;
  final String? avgDeliveryTime;
  final String? subtitle;
  final bool isActive;
  final int order;

  BusinessCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.badge,
    this.avgDeliveryTime,
    this.subtitle,
    this.isActive = true,
    this.order = 0,
  });

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      color: json['color'] as String? ?? '#00A651',
      badge: json['badge'] as String?,
      avgDeliveryTime: json['avgDeliveryTime'] as String?,
      subtitle: json['subtitle'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'badge': badge,
      'avgDeliveryTime': avgDeliveryTime,
      'subtitle': subtitle,
      'isActive': isActive,
      'order': order,
    };
  }
}

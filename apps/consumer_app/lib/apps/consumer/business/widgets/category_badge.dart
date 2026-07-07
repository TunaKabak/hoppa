import 'package:flutter/material.dart';

class CategoryBadge extends StatelessWidget {
  final String badgeType; // "new", "popular", "promo", "closed"

  const CategoryBadge({super.key, required this.badgeType});

  @override
  Widget build(BuildContext context) {
    final badgeData = _getBadgeData();

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeData.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: badgeData.backgroundColor.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeData.icon != null) ...[
              Icon(badgeData.icon, size: 12, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              badgeData.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _BadgeData _getBadgeData() {
    switch (badgeType.toLowerCase()) {
      case 'new':
      case 'yeni':
        return _BadgeData(
          label: 'YENİ',
          backgroundColor: Colors.purple,
          icon: Icons.star,
        );
      case 'popular':
      case 'popüler':
        return _BadgeData(
          label: 'POPÜLER',
          backgroundColor: Colors.orange,
          icon: Icons.local_fire_department,
        );
      case 'promo':
      case 'kampanyalı':
        return _BadgeData(
          label: 'KAMPANYA',
          backgroundColor: Colors.red,
          icon: Icons.local_offer,
        );
      case 'closed':
      case 'kapalı':
        return _BadgeData(
          label: 'KAPALI',
          backgroundColor: Colors.grey,
          icon: Icons.do_not_disturb,
        );
      default:
        return _BadgeData(
          label: badgeType.toUpperCase(),
          backgroundColor: Colors.blue,
        );
    }
  }
}

class _BadgeData {
  final String label;
  final Color backgroundColor;
  final IconData? icon;

  _BadgeData({required this.label, required this.backgroundColor, this.icon});
}

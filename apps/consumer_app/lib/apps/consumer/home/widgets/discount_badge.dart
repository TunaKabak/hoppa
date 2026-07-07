import 'package:flutter/material.dart';

/// Consumer'a özel indirim rozeti.
/// Ürün kartlarında ve kampanya etiketlerinde kullanılır.
class DiscountBadge extends StatelessWidget {
  final String text;
  final bool isLarge;

  const DiscountBadge({super.key, required this.text, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondary,
            colorScheme.secondary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer_rounded,
            color: Colors.white,
            size: isLarge ? 16 : 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: isLarge ? 14 : 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

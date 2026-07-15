import 'package:flutter/material.dart';

class ShopBadge extends StatelessWidget {
  final String label;
  final bool isOnImage;

  const ShopBadge({
    super.key,
    required this.label,
    this.isOnImage = false,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color displayColor;
    String tooltip;

    switch (label) {
      case 'Hoppa Kuryesi':
        icon = Icons.motorcycle_rounded;
        displayColor = const Color(0xFF008744);
        tooltip = "Hoppa anlaşmalı kuryeler ile hızlı ve güvenli teslimat";
        break;
      case 'Gel-Al':
        icon = Icons.shopping_bag_outlined;
        displayColor = const Color(0xFF7B1FA2);
        tooltip = "Siparişinizi hazırlayalım, dükkandan kendiniz teslim alın";
        break;
      case 'Hızlı Teslimat':
        icon = Icons.flash_on_rounded;
        displayColor = const Color(0xFFE65100);
        tooltip = "Ortalama teslimat süresi kısa ve hızı yüksek dükkan";
        break;
      case 'Müşteri Favorisi':
        icon = Icons.favorite_rounded;
        displayColor = const Color(0xFFC62828);
        tooltip = "Müşterilerimizden en yüksek puanları alan favori dükkan";
        break;
      case 'Yeni':
        icon = Icons.auto_awesome_rounded;
        displayColor = const Color(0xFF00838F);
        tooltip = "Platformumuza yeni katılan, keşfedilmeyi bekleyen dükkan";
        break;
      case 'Esnaf Teslimatı':
        icon = Icons.local_shipping_outlined;
        displayColor = const Color(0xFFD84315);
        tooltip = "İşletmenin kendi kuryeleri tarafından yapılan teslimat";
        break;
      default:
        icon = Icons.label_outline_rounded;
        displayColor = const Color(0xFF008744);
        tooltip = label;
    }

    final Color bgColor = isOnImage 
        ? Colors.white.withValues(alpha: 0.95)
        : displayColor.withValues(alpha: 0.08);

    final Border border = isOnImage
        ? Border.all(
            color: Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          )
        : Border.all(
            color: displayColor.withValues(alpha: 0.15),
            width: 1,
          );

    final List<BoxShadow>? shadow = isOnImage
        ? const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 1.5),
            )
          ]
        : null;

    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap, // Mobile friendly tap trigger
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30), // Capsule pill shape
          border: border,
          boxShadow: shadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: displayColor,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: displayColor,
                fontSize: 10,
                fontWeight: FontWeight.w700, // Make text bolder for better readability
              ),
            ),
          ],
        ),
      ),
    );
  }
}

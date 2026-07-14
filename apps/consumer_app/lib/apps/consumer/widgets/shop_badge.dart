import 'package:flutter/material.dart';

class ShopBadge extends StatelessWidget {
  final String label;

  const ShopBadge({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String tooltip;

    switch (label) {
      case 'Hoppa Kuryesi':
        icon = Icons.motorcycle_rounded;
        color = const Color(0xFF00A651);
        tooltip = "Hoppa anlaşmalı kuryeler ile hızlı ve güvenli teslimat";
        break;
      case 'Gel-Al':
        icon = Icons.shopping_bag_outlined;
        color = Colors.purple;
        tooltip = "Siparişinizi hazırlayalım, dükkandan kendiniz teslim alın";
        break;
      case 'Hızlı Teslimat':
        icon = Icons.flash_on_rounded;
        color = Colors.amber.shade800;
        tooltip = "Ortalama teslimat süresi kısa ve hızı yüksek dükkan";
        break;
      case 'Müşteri Favorisi':
        icon = Icons.favorite_rounded;
        color = Colors.redAccent;
        tooltip = "Müşterilerimizden en yüksek puanları alan favori dükkan";
        break;
      case 'Yeni':
        icon = Icons.auto_awesome_rounded;
        color = Colors.cyan.shade700;
        tooltip = "Platformumuza yeni katılan, keşfedilmeyi bekleyen dükkan";
        break;
      case 'Esnaf Teslimatı':
        icon = Icons.local_shipping_outlined;
        color = Colors.orange;
        tooltip = "İşletmenin kendi kuryeleri tarafından yapılan teslimat";
        break;
      default:
        icon = Icons.label_outline_rounded;
        color = const Color(0xFF00A651);
        tooltip = label;
    }

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 11,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

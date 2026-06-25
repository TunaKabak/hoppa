import 'package:flutter/material.dart';

class CompactDeliveryStatus extends StatelessWidget {
  final double currentCartTotal;
  final double minOrderLimit;
  final double freeDeliveryLimit;

  const CompactDeliveryStatus({
    super.key,
    required this.currentCartTotal,
    required this.minOrderLimit,
    required this.freeDeliveryLimit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMinLimitPassed = currentCartTotal >= minOrderLimit;
    final isFreeDeliveryPassed = currentCartTotal >= freeDeliveryLimit;

    if (minOrderLimit <= 0 && freeDeliveryLimit <= 0) {
      return const SizedBox.shrink();
    }

    final backgroundColor = isFreeDeliveryPassed
        ? const Color(0xFFE8F5E9) // Very light green
        : !isMinLimitPassed
            ? const Color(0xFFFFF3E0) // Very light orange
            : const Color(0xFFE3F2FD); // Very light blue

    final iconColor = isFreeDeliveryPassed
        ? const Color(0xFF2E7D32) // Dark green
        : !isMinLimitPassed
            ? const Color(0xFFE65100) // Dark orange
            : const Color(0xFF1565C0); // Dark blue

    String statusText;
    if (!isMinLimitPassed) {
      statusText = "Sepete minimum tutar için ${(minOrderLimit - currentCartTotal).toStringAsFixed(0)} TL daha ekleyin.";
    } else if (!isFreeDeliveryPassed) {
      statusText = "Kurye ücreti bedava! Kalan: ${(freeDeliveryLimit - currentCartTotal).toStringAsFixed(0)} TL.";
    } else {
      statusText = "Tebrikler, teslimat ücretiniz tamamen Hoppa'dan! 🎉";
    }

    final double progressValue = freeDeliveryLimit > 0
        ? (currentCartTotal / freeDeliveryLimit).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFreeDeliveryPassed
                ? Icons.celebration
                : !isMinLimitPassed
                    ? Icons.info_outline
                    : Icons.delivery_dining,
            size: 18,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor.withValues(alpha: 0.9),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey.shade300,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

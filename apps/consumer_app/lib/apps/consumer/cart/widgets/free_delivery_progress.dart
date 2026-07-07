import 'package:flutter/material.dart';

class FreeDeliveryProgress extends StatelessWidget {
  final double currentAmount;
  final double thresholdAmount;

  const FreeDeliveryProgress({
    super.key,
    required this.currentAmount,
    required this.thresholdAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (thresholdAmount <= 0) return const SizedBox.shrink();

    final remaining = thresholdAmount - currentAmount;
    final isReached = currentAmount >= thresholdAmount;
    final progress = (currentAmount / thresholdAmount).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isReached ? Colors.green.shade50 : Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReached ? Icons.local_shipping : Icons.local_shipping_outlined,
                color: isReached ? Colors.green : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isReached
                      ? "Harika! Ücretsiz teslimat kazandınız!"
                      : "Ücretsiz teslimat için ${remaining.toStringAsFixed(2)} ₺ daha ekleyin.",
                  style: TextStyle(
                    color: isReached
                        ? Colors.green.shade700
                        : Colors.blue.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isReached ? Colors.green : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

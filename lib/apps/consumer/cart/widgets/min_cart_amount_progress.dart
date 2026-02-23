import 'package:flutter/material.dart';

class MinCartAmountProgress extends StatelessWidget {
  final double currentAmount;
  final double minAmount;

  const MinCartAmountProgress({
    super.key,
    required this.currentAmount,
    required this.minAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (minAmount <= 0) return const SizedBox.shrink();

    final remaining = minAmount - currentAmount;
    final isReached = currentAmount >= minAmount;
    final progress = (currentAmount / minAmount).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isReached ? Colors.green.shade50 : Colors.orange.shade50,
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
                isReached ? Icons.check_circle : Icons.info_outline,
                color: isReached ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isReached
                      ? "Minimum sepet tutarına ulaştınız!"
                      : "Sipariş verebilmek için ${remaining.toStringAsFixed(2)} ₺ daha ürün eklemelisiniz.",
                  style: TextStyle(
                    color: isReached
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
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
                isReached ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

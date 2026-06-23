import 'package:flutter/material.dart';
import 'package:hoppa/shared/models/order.dart' as model;
import 'package:hoppa/shared/models/order_status.dart';
import 'package:hoppa/apps/consumer/orders/order_detail_page.dart';

class ActiveOrderBanner extends StatelessWidget {
  final model.Order order;

  const ActiveOrderBanner({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = OrderStatus.fromString(order.status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFC8E6C9),
            ], // Light Green Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            // İKON
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                status.icon,
                color: const Color(0xFF00A651),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // METİN VE PROGRESS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sipariş ${status.label}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: status.progressValue,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00A651),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: Color(0xFF1B5E20)),
          ],
        ),
      ),
    );
  }
}

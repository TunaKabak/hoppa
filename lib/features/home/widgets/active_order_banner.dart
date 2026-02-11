import 'package:flutter/material.dart';
import 'package:kktc_market/models/order.dart' as model;
import 'package:kktc_market/features/orders/order_detail_page.dart';

class ActiveOrderBanner extends StatelessWidget {
  final model.Order order;

  const ActiveOrderBanner({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
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
              color: Colors.green.withOpacity(0.2),
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
                _getStatusIcon(order.status),
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
                    _getStatusText(order.status),
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
                      value: _getProgressValue(order.status),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top;
      case 'preparing':
        return Icons.inventory_2;
      case 'on_way':
        return Icons.delivery_dining;
      default:
        return Icons.check_circle;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return "Sipariş Onay Bekliyor";
      case 'preparing':
        return "Sipariş Hazırlanıyor";
      case 'on_way':
        return "Sipariş Yolda";
      default:
        return "Sipariş Durumu";
    }
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'pending':
        return 0.15;
      case 'preparing': // %50 den fazla
        return 0.50;
      case 'on_way': // %80
        return 0.85;
      default:
        return 0.0;
    }
  }
}

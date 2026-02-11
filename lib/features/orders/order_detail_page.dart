import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kktc_market/models/order.dart' as model;

class OrderDetailPage extends StatelessWidget {
  final model.Order order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final date = order.createdAt;
    final formattedDate = DateFormat(
      'dd MMM yyyy, HH:mm',
      'tr_TR',
    ).format(date);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Sipariş Detayı",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- DURUM KARTI ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  _buildStatusIcon(status),
                  const SizedBox(height: 16),
                  Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sipariş No: #${order.id.substring(0, 8).toUpperCase()}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- ÜRÜNLER ---
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sipariş İçeriği",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...order.items.map((item) => _buildOrderItem(item)),
                  const Divider(height: 32),
                  // TOPLAM
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Toplam Tutar",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${order.totalAmount.toStringAsFixed(2)} ₺",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00A651), // Emerald Green
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- ADRES ve NOTLAR ---
            if (order.userAddress.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Teslimat Bilgileri",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            order.userAddress,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                    if (order.deliveryTime.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Teslimat Zamanı: ${order.deliveryTime}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(model.OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}x",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A651),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            "${(item.price * item.quantity).toStringAsFixed(2)} ₺",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'pending':
        icon = Icons.hourglass_empty_rounded;
        color = Colors.orange;
        break;
      case 'preparing':
        icon = Icons.inventory_2_rounded;
        color = Colors.blue;
        break;
      case 'on_way':
        icon = Icons.delivery_dining_rounded;
        color = Colors.purple;
        break;
      case 'delivered':
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case 'cancelled':
        icon = Icons.cancel_rounded;
        color = Colors.red;
        break;
      default:
        icon = Icons.info_rounded;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 48, color: color),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return "Sipariş Onay Bekliyor";
      case 'preparing':
        return "Sipariş Hazırlanıyor";
      case 'on_way':
        return "Sipariş Yolda";
      case 'delivered':
        return "Teslim Edildi";
      case 'cancelled':
        return "İptal Edildi";
      default:
        return status;
    }
  }
}

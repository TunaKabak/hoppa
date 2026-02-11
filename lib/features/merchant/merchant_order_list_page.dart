import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kktc_market/core/services/order_service.dart';

class MerchantOrderListPage extends StatelessWidget {
  final String? filterStatus;

  const MerchantOrderListPage({super.key, this.filterStatus});

  @override
  Widget build(BuildContext context) {
    final OrderService orderService = OrderService();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(_getAppBarTitle()), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: orderService.getIncomingOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var orders = snapshot.data!.docs;

          if (filterStatus == 'pending') {
            orders = orders.where((d) => d['status'] == 'pending').toList();
          } else if (filterStatus == 'active') {
            orders = orders
                .where(
                  (d) => [
                    'preparing',
                    'on_way',
                    'ready_for_pickup',
                  ].contains(d['status']),
                )
                .toList();
          }

          orders.sort((a, b) {
            Timestamp t1 = (a.data() as Map)['created_at'] ?? Timestamp.now();
            Timestamp t2 = (b.data() as Map)['created_at'] ?? Timestamp.now();
            return t2.compareTo(t1);
          });

          if (orders.isEmpty) {
            return Center(
              child: Text(
                "Sipariş bulunamadı (${_getAppBarTitle()})",
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, orders[index], orderService);
            },
          );
        },
      ),
    );
  }

  String _getAppBarTitle() {
    if (filterStatus == 'pending') return 'Onay Bekleyenler';
    if (filterStatus == 'active') return 'Aktif Siparişler';
    return 'Tüm Siparişler';
  }

  Widget _buildOrderCard(
    BuildContext context,
    DocumentSnapshot orderDoc,
    OrderService service,
  ) {
    final data = orderDoc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final items = (data['items'] as List<dynamic>);

    // YENİ: Gel Al kontrolü
    final bool isPickUp = data['is_pickup'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        // Başlık
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              "Sipariş #${orderDoc.id.substring(0, 4).toUpperCase()}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isPickUp) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "GEL AL",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          "${items.length} Ürün • ${data['total_amount']} ₺",
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),

        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          "${item['quantity']}x",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item['name'])),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        data['user_address'] ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // BUTONLAR (Dinamik)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(orderDoc.id, status, isPickUp, service),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // YENİ: Sipariş tipine göre değişen buton yapısı
  Widget _buildActionButton(
    String id,
    String status,
    bool isPickUp,
    OrderService service,
  ) {
    switch (status) {
      case 'pending':
        return FilledButton.icon(
          onPressed: () => service.updateOrderStatus(id, 'preparing'),
          icon: const Icon(Icons.check),
          label: const Text("ONAYLA"),
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
        );
      case 'preparing':
        // Eğer Gel Al ise "Kuryeye Ver" yerine "Hazır, Müşteri Bekleniyor" butonunu göster
        if (isPickUp) {
          return FilledButton.icon(
            onPressed: () => service.updateOrderStatus(id, 'ready_for_pickup'),
            icon: const Icon(Icons.store),
            label: const Text("HAZIR (BEKLİYOR)"),
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
          );
        } else {
          return FilledButton.icon(
            onPressed: () => service.updateOrderStatus(id, 'on_way'),
            icon: const Icon(Icons.motorcycle),
            label: const Text("KURYEYE VER"),
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
          );
        }
      case 'on_way':
        return FilledButton.icon(
          onPressed: () => service.updateOrderStatus(id, 'delivered'),
          icon: const Icon(Icons.done),
          label: const Text("TESLİM ET"),
          style: FilledButton.styleFrom(backgroundColor: Colors.grey),
        );
      case 'ready_for_pickup': // Yeni Durum
        return FilledButton.icon(
          onPressed: () => service.updateOrderStatus(id, 'delivered'),
          icon: const Icon(Icons.handshake),
          label: const Text("MÜŞTERİYE VERİLDİ"),
          style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
        );
      default:
        return const SizedBox();
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'pending') return Colors.red;
    if (status == 'preparing') return Colors.orange;
    if (status == 'on_way') return Colors.blue;
    if (status == 'ready_for_pickup') return Colors.teal; // Yeni renk
    return Colors.green;
  }

  IconData _getStatusIcon(String status) {
    if (status == 'pending') return Icons.notifications_active;
    if (status == 'preparing') return Icons.inventory;
    if (status == 'on_way') return Icons.directions_bike;
    if (status == 'ready_for_pickup') return Icons.shopping_bag; // Yeni ikon
    return Icons.check_circle;
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/core/services/order_service.dart';
import 'package:hoppa/models/order_status.dart';

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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var orders = snapshot.data!.docs;

          if (filterStatus == OrderStatus.pending.value) {
            orders = orders
                .where((d) => d['status'] == OrderStatus.pending.value)
                .toList();
          } else if (filterStatus == 'active') {
            orders = orders
                .where(
                  (d) => [
                    OrderStatus.preparing.value,
                    OrderStatus.onWay.value,
                    OrderStatus.readyForPickup.value,
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
    if (filterStatus == OrderStatus.pending.value) return 'Onay Bekleyenler';
    if (filterStatus == 'active') return 'Aktif Siparişler';
    return 'Tüm Siparişler';
  }

  Widget _buildOrderCard(
    BuildContext context,
    DocumentSnapshot orderDoc,
    OrderService service,
  ) {
    final data = orderDoc.data() as Map<String, dynamic>;
    final status = data['status'] ?? OrderStatus.pending.value;
    final items = (data['items'] as List<dynamic>);

    // YENİ: Gel Al kontrolü
    final bool isPickUp =
        (data['is_pickup'] ?? false) || (data['delivery_method'] == 'pickup');

    final delayColor = _getOrderDelayColor(
      data['created_at'] ?? Timestamp.now(),
      status,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: delayColor != Colors.transparent
            ? BorderSide(color: delayColor, width: 2)
            : BorderSide.none,
      ),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${items.length} Ürün • ${data['total_amount']} ₺",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_buildDelayIndicator(
                  data['created_at'] ?? Timestamp.now(),
                  status,
                ) !=
                null) ...[
              const SizedBox(height: 4),
              _buildDelayIndicator(
                data['created_at'] ?? Timestamp.now(),
                status,
              )!,
            ],
          ],
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
    final statusEnum = OrderStatus.fromString(status);

    switch (statusEnum) {
      case OrderStatus.pending:
        return FilledButton.icon(
          onPressed: () =>
              service.updateOrderStatus(id, OrderStatus.preparing.value),
          icon: const Icon(Icons.check),
          label: const Text("ONAYLA"),
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
        );
      case OrderStatus.preparing:
        // Eğer Gel Al ise "Kuryeye Ver" yerine "Hazır, Müşteri Bekleniyor" butonunu göster
        if (isPickUp) {
          return FilledButton.icon(
            onPressed: () =>
                service.updateOrderStatus(id, OrderStatus.readyForPickup.value),
            icon: const Icon(Icons.store),
            label: Text(OrderStatus.readyForPickup.label),
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
          );
        } else {
          return FilledButton.icon(
            onPressed: () =>
                service.updateOrderStatus(id, OrderStatus.onWay.value),
            icon: const Icon(Icons.motorcycle),
            label: const Text("KURYEYE VER"),
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
          );
        }
      case OrderStatus.onWay:
        return FilledButton.icon(
          onPressed: () =>
              service.updateOrderStatus(id, OrderStatus.delivered.value),
          icon: const Icon(Icons.done),
          label: const Text("TESLİM ET"),
          style: FilledButton.styleFrom(backgroundColor: Colors.grey),
        );
      case OrderStatus.readyForPickup: // Yeni Durum
        return FilledButton.icon(
          onPressed: () =>
              service.updateOrderStatus(id, OrderStatus.delivered.value),
          icon: const Icon(Icons.done_all),
          label: const Text("TESLİM ET"),
          style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
        );
      default:
        return const SizedBox();
    }
  }

  Color _getStatusColor(String status) {
    return OrderStatus.fromString(status).color;
  }

  IconData _getStatusIcon(String status) {
    return OrderStatus.fromString(status).icon;
  }

  // YENİ: Gecikme Rengi
  Color _getOrderDelayColor(Timestamp createdAt, String status) {
    // Sadece aktif siparişlerde gecikme kontrolü yapılır
    if (status == OrderStatus.delivered.value ||
        status == OrderStatus.cancelled.value) {
      return Colors.transparent;
    }

    final diff = DateTime.now().difference(createdAt.toDate());
    if (diff.inMinutes >= 30) return Colors.red; // Kritik
    if (diff.inMinutes >= 15) return Colors.orange; // Uyarı
    return Colors.transparent; // Normal
  }

  // YENİ: Gecikme Metni
  Widget? _buildDelayIndicator(Timestamp createdAt, String status) {
    if (status == OrderStatus.delivered.value ||
        status == OrderStatus.cancelled.value) {
      return null;
    }

    final diff = DateTime.now().difference(createdAt.toDate());
    if (diff.inMinutes < 15) return null;

    final color = diff.inMinutes >= 30 ? Colors.red : Colors.orange;
    final text = diff.inMinutes >= 30 ? "KRİTİK GECİKME" : "GECİKMEYE BAŞLADI";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_filled, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            "$text (${diff.inMinutes} dk)",
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

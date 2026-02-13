import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hoppa/core/services/auth_service.dart';
import 'package:hoppa/core/services/order_service.dart';
import 'package:hoppa/core/widgets/animated_sliding_toggle.dart'; // YENİ BİLEŞEN
import 'package:hoppa/models/order.dart' as model;
import 'package:hoppa/models/order_status.dart'; // Added import
import 'package:hoppa/features/orders/order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  // Filtreleme Durumu: 0 = Aktif, 1 = Geçmiş
  int _selectedFilterIndex = 0;

  // Stream'i hafızada tutmak için değişken
  late Stream<QuerySnapshot> _ordersStream;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.uid;

    if (userId != null) {
      _ordersStream = OrderService().getUserOrders(userId);
    } else {
      _ordersStream = const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryColor = Color(0xFF00A651);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Siparişlerim",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- FİLTRELEME BUTONLARI (KAYMA EFEKTLİ COMPONENT) ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: AnimatedSlidingToggle(
              labels: const ["Aktif Siparişler", "Geçmiş Siparişler"],
              selectedIndex: _selectedFilterIndex,
              activeColor: kPrimaryColor,
              onChanged: (index) =>
                  setState(() => _selectedFilterIndex = index),
            ),
          ),

          // --- SİPARİŞ LİSTESİ ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}"));
                }

                final allOrders = snapshot.data?.docs ?? [];

                final filteredOrders = allOrders.where((doc) {
                  final statusStr =
                      (doc.data() as Map<String, dynamic>)['status'];
                  final s = OrderStatus.fromString(statusStr ?? 'pending');

                  if (_selectedFilterIndex == 0) {
                    return s.isActive;
                  } else {
                    return s.isCompleted;
                  }
                }).toList();

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedFilterIndex == 0
                              ? Icons.local_shipping_outlined
                              : Icons.history,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilterIndex == 0
                              ? "Aktif siparişiniz bulunmuyor."
                              : "Geçmiş siparişiniz bulunmuyor.",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _OrderCard(order: order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final DocumentSnapshot order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final data = order.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final items = data['items'] as List<dynamic>;
    final date = (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat(
      'dd MMM yyyy, HH:mm',
      'tr_TR',
    ).format(date);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            _buildStatusBadge(status),
            const Spacer(),
            Text(
              "${(data['total_amount'] as num).toStringAsFixed(2)} ₺",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFF00A651),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            formattedDate,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sipariş Özeti",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${item['quantity'] is double ? (item['quantity'] as double).toStringAsFixed(1) : item['quantity']}x",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A651),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['name'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          "${item['price']} ₺",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (data['delivery_time'] != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Teslimat: ${data['delivery_time']}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                if (data['user_address'] != null &&
                    data['user_address'].toString().contains('Not:'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.note, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['user_address'].split('Not:')[1].trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final orderModel = model.Order.fromMap(data, order.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderDetailPage(order: orderModel),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A651),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Sipariş Detayı",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final s = OrderStatus.fromString(status);
    final color = s.color;
    final text = s.label;
    final icon = s.icon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

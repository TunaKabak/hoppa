import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoppa/core/services/order_service.dart';
import 'package:hoppa/models/order.dart' as model;
import 'package:hoppa/models/order_status.dart';
import 'package:hoppa/features/orders/order_detail_page.dart';

class ActiveOrderCard extends StatefulWidget {
  final String? businessId;

  const ActiveOrderCard({super.key, this.businessId});

  @override
  State<ActiveOrderCard> createState() => _ActiveOrderCardState();
}

class _ActiveOrderCardState extends State<ActiveOrderCard> {
  final OrderService _orderService = OrderService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  late Stream<model.Order?> _orderStream;

  @override
  void initState() {
    super.initState();
    if (_userId != null) {
      _orderStream = _orderService.getActiveOrderStream(
        _userId,
        businessId: widget.businessId,
      );
    } else {
      _orderStream = const Stream.empty();
    }
  }

  @override
  void didUpdateWidget(ActiveOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.businessId != oldWidget.businessId) {
      _initStream();
    }
  }

  void _initStream() {
    setState(() {
      if (_userId != null) {
        _orderStream = _orderService.getActiveOrderStream(
          _userId,
          businessId: widget.businessId,
        );
      } else {
        _orderStream = const Stream.empty();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Eğer kullanıcı giriş yapmamışsa kartı gösterme
    if (_userId == null) return const SizedBox.shrink();

    return StreamBuilder<model.Order?>(
      stream: _orderStream,
      builder: (context, snapshot) {
        // Fail-Safe: Herhangi bir yüklenme, hata veya veri yok durumunda GİZLE
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data == null) {
          return const SizedBox.shrink();
        }

        try {
          final order = snapshot.data!;
          final statusEnum = OrderStatus.fromString(order.status);

          // Eğer sipariş tamamlanmış veya iptal edilmişse gösterme
          if (statusEnum.isCompleted) {
            return const SizedBox.shrink();
          }

          return Card(
            color: Colors.white,
            elevation: 4,
            shadowColor: Colors.black12,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailPage(order: order),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildStatusIcon(order.status),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusText(order.status),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tahmini Teslimat: ${order.deliveryTime}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepProgressBar(
                      context,
                      order.status,
                      order.deliveryMethod,
                    ),
                  ],
                ),
              ),
            ),
          );
        } catch (e) {
          // Veri işleme hatasında (örn: eksik alan, parse hatası) sessizce gizle
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildStatusIcon(String status) {
    final s = OrderStatus.fromString(status);
    final color = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: Icon(s.icon, color: color, size: 28),
    );
  }

  String _getStatusText(String status) {
    final s = OrderStatus.fromString(status);
    if (s == OrderStatus.pending) return 'Siparişiniz Alındı';
    return s.label;
  }

  Widget _buildStepProgressBar(
    BuildContext context,
    String status,
    String deliveryMethod,
  ) {
    final s = OrderStatus.fromString(status);
    final isPickup = deliveryMethod == 'pickup';

    if (isPickup) {
      // Gel Al: 3 adım (Alındı -> Hazırlanıyor -> Hazır)
      // "Teslim Edildi" zaten kartta gösterilmediği için son adım "Hazır" olmalı
      int currentStep = 1; // Default Pending

      if (s == OrderStatus.preparing) currentStep = 2;
      if (s == OrderStatus.readyForPickup) currentStep = 3;
      if (s == OrderStatus.delivered) currentStep = 3; // Tamamlandı

      return Row(
        children: [
          _buildStep(context, 1, currentStep >= 1, 'Alındı'),
          _buildConnector(currentStep >= 2),
          _buildStep(context, 2, currentStep >= 2, OrderStatus.preparing.label),
          _buildConnector(currentStep >= 3),
          _buildStep(
            context,
            3,
            currentStep >= 3,
            OrderStatus.readyForPickup.label,
          ),
        ],
      );
    }

    // Teslimat: 3 adım (Alındı, Hazırlanıyor, Yolda)
    final currentStep = s.stepIndex + 1;

    return Row(
      children: [
        _buildStep(context, 1, currentStep >= 1, 'Alındı'),
        _buildConnector(currentStep >= 2),
        _buildStep(context, 2, currentStep >= 2, OrderStatus.preparing.label),
        _buildConnector(currentStep >= 3),
        _buildStep(context, 3, currentStep >= 3, OrderStatus.onWay.label),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context,
    int stepIndex,
    bool isActive,
    String label,
  ) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.orange : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: isActive
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.orange : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isActive) {
    return Expanded(
      child: Transform(
        transform: Matrix4.translationValues(0, -8, 0),
        child: Container(
          height: 2,
          color: isActive ? Colors.orange : Colors.grey[300],
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        ),
      ),
    );
  }
}

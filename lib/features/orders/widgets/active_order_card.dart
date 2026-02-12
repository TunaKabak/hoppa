import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoppa/core/services/order_service.dart';
import 'package:hoppa/models/order.dart' as model;

class ActiveOrderCard extends StatefulWidget {
  const ActiveOrderCard({super.key});

  @override
  State<ActiveOrderCard> createState() => _ActiveOrderCardState();
}

class _ActiveOrderCardState extends State<ActiveOrderCard> {
  final OrderService _orderService = OrderService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isExpanded = false;
  late Stream<model.Order?> _orderStream;

  @override
  void initState() {
    super.initState();
    if (_userId != null) {
      _orderStream = _orderService.getActiveOrderStream(_userId);
    } else {
      _orderStream = const Stream.empty();
    }
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
          final status = order.status;

          print('DEBUG: Gelen Sipariş Durumu: $status');

          // Eğer sipariş tamamlanmış veya iptal edilmişse gösterme
          if (status == 'delivered' || status == 'cancelled') {
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
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildStatusIcon(status),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getStatusText(status),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tahmini Teslimat: ${order.deliveryTime}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStepProgressBar(context, status),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Text(
                            'Sipariş Özeti',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.quantity.toInt()}x ${item.name}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${item.price.toStringAsFixed(2)} ₺',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Toplam',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${order.totalAmount.toStringAsFixed(2)} ₺',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
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
    IconData icon;
    Color color;

    switch (status) {
      case 'on_way':
        icon = Icons.delivery_dining;
        color = Colors.orange;
        break;
      case 'preparing':
      case 'pending':
      default:
        icon = Icons.soup_kitchen;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Siparişiniz Alındı';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'on_way':
        return 'Yolda';
      default:
        return 'İşlemde';
    }
  }

  Widget _buildStepProgressBar(BuildContext context, String status) {
    int currentStep = 0;
    if (status == 'pending') currentStep = 1;
    if (status == 'preparing') currentStep = 2;
    if (status == 'on_way') currentStep = 3;

    return Row(
      children: [
        _buildStep(context, 1, currentStep >= 1, 'Alındı'),
        _buildConnector(currentStep >= 2),
        _buildStep(context, 2, currentStep >= 2, 'Hazırlanıyor'),
        _buildConnector(currentStep >= 3),
        _buildStep(context, 3, currentStep >= 3, 'Yolda'),
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

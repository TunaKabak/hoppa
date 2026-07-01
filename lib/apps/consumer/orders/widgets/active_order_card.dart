import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_order_repository.dart';
import 'package:hoppa/shared/models/order_status.dart';
import 'package:hoppa/apps/consumer/orders/order_detail_page.dart';
import 'package:hoppa/shared/models/order.dart' as model;

class ActiveOrderCard extends ConsumerStatefulWidget {
  final String? businessId;

  const ActiveOrderCard({super.key, this.businessId});

  @override
  ConsumerState<ActiveOrderCard> createState() => _ActiveOrderCardState();
}

class _ActiveOrderCardState extends ConsumerState<ActiveOrderCard> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Refresh orders periodically
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(consumerOrdersProvider);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final bool isGuest = authState is! AuthAuthenticated;
    
    // Eğer kullanıcı giriş yapmamışsa kartı gösterme
    if (isGuest) return const SizedBox.shrink();

    final ordersAsync = ref.watch(consumerOrdersProvider);

    return ordersAsync.when(
      loading: () => _buildSkeleton(context),
      error: (error, stack) {
        return const SizedBox.shrink();
      },
      data: (allOrders) {
        try {
          // Find active orders for this business
          final activeOrders = allOrders.where((order) {
            final s = OrderStatus.fromString(order.status);
            final matchesBusiness = widget.businessId == null || order.businessId == widget.businessId;
            return matchesBusiness && s.isActive;
          }).toList();

          if (activeOrders.isEmpty) {
            return const SizedBox.shrink();
          }

          // Sort by newest first
          activeOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (activeOrders.length == 1) {
            return _SingleActiveOrderCard(
              order: activeOrders.first,
              canExpand: true,
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            );
          }

          // Multiple active orders -> scroll horizontally
          return SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeOrders.length,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.82,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: _SingleActiveOrderCard(
                      order: order,
                      canExpand: false,
                      margin: EdgeInsets.zero,
                    ),
                  ),
                );
              },
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[300],
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonStep(),
                _buildSkeletonConnector(),
                _buildSkeletonStep(),
                _buildSkeletonConnector(),
                _buildSkeletonStep(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonStep() {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          width: 36,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonConnector() {
    return Expanded(
      child: Transform(
        transform: Matrix4.translationValues(0, -8, 0),
        child: Container(
          height: 2,
          color: Colors.grey[200],
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        ),
      ),
    );
  }
}

class _SingleActiveOrderCard extends StatefulWidget {
  final model.Order order;
  final bool canExpand;
  final EdgeInsetsGeometry margin;

  const _SingleActiveOrderCard({
    required this.order,
    required this.canExpand,
    required this.margin,
  });

  @override
  State<_SingleActiveOrderCard> createState() => _SingleActiveOrderCardState();
}

class _SingleActiveOrderCardState extends State<_SingleActiveOrderCard> {
  bool _isExpanded = false;

  Widget _buildStatusIcon(String status, bool compact) {
    final s = OrderStatus.fromString(status);
    final color = Colors.orange;

    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: Icon(s.icon, color: color, size: compact ? 22 : 28),
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
      int currentStep = 1;
      if (s == OrderStatus.preparing) currentStep = 2;
      if (s == OrderStatus.readyForPickup) currentStep = 3;
      if (s == OrderStatus.delivered) currentStep = 3;

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

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    if (!widget.canExpand) {
      // Horizontal compact card
      return Card(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black12,
        margin: widget.margin,
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    _buildStatusIcon(order.status, true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(order.status),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${order.items.length} Ürün • ${order.totalAmount.toStringAsFixed(2)} ₺",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
    }

    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      margin: widget.margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatusIcon(order.status, false),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(order.status),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 4),
                          if (!_isExpanded)
                            Text(
                              "${order.items.length} Ürün • Tutar: ${order.totalAmount.toStringAsFixed(2)} ₺",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                            )
                          else
                            Text(
                              order.items.map((item) => "${item.quantity.toInt()}x ${item.name}").join(", "),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.orange,
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.payment, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        order.paymentMethod == "ONLINE_PAYMENT" ? "Online Kredi Kartı" : "Kapıda Ödeme",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                  if (order.orderNote.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.notes, size: 12, color: Colors.orange[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Not: ${order.orderNote}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange[800], fontStyle: FontStyle.italic, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Tahmini Teslimat: ${order.deliveryTime.isNotEmpty ? order.deliveryTime : "-"}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  _buildStepProgressBar(
                    context,
                    order.status,
                    order.deliveryMethod,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailPage(order: order),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text("Sipariş Detayına Git"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade50,
                      foregroundColor: Colors.orange.shade800,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.orange.shade200),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

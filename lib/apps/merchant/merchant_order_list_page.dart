import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/shared/models/order.dart' as model;
import 'package:hoppa/shared/models/order_status.dart';
import 'package:hoppa/apps/merchant/merchant_main_layout.dart';
import 'package:hoppa/apps/merchant/repositories/merchant_order_repository.dart';
import 'package:core_auth/core_auth.dart';

class MerchantOrderListPage extends ConsumerStatefulWidget {
  final String? businessId;
  final String? filterStatus;
  final String? orderId;

  const MerchantOrderListPage({
    super.key,
    this.businessId,
    this.filterStatus,
    this.orderId,
  });

  @override
  ConsumerState<MerchantOrderListPage> createState() => _MerchantOrderListPageState();
}

class _MerchantOrderListPageState extends ConsumerState<MerchantOrderListPage> {
  Timer? _pollingTimer;
  String? _selectedFilter;
  String? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.filterStatus;
    _selectedOrderId = widget.orderId;
    // Refresh periodically
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(merchantOrdersProvider);
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
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(merchantOrdersProvider);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          centerTitle: true,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
              : IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => merchantDrawerKey.currentState?.openDrawer(),
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(merchantOrdersProvider);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (_selectedOrderId != null && _selectedOrderId!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text(
                      "Detay Filtresi: #${_selectedOrderId!.substring(0, 8).toUpperCase()}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedOrderId = null;
                        });
                      },
                    )
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildFilterChip(null, "Tümü", theme),
                    const SizedBox(width: 8),
                    _buildFilterChip(OrderStatus.pending.value, "Bekleyenler ⏳", theme),
                    const SizedBox(width: 8),
                    _buildFilterChip(OrderStatus.preparing.value, "Hazırlananlar 🍳", theme),
                    const SizedBox(width: 8),
                    _buildFilterChip(OrderStatus.onWay.value, "Yoldakiler 🛵", theme),
                    const SizedBox(width: 8),
                    _buildFilterChip(OrderStatus.delivered.value, "Tamamlananlar ✅", theme),
                    const SizedBox(width: 8),
                    _buildFilterChip(OrderStatus.cancelled.value, "İptaller ❌", theme),
                  ],
                ),
              ),
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text("Hata: $error")),
                data: (allOrders) {
                  var orders = allOrders.toList();

                  if (_selectedOrderId != null && _selectedOrderId!.isNotEmpty) {
                    orders = orders
                        .where((d) => d.id == _selectedOrderId)
                        .toList();
                  } else {
                    if (_selectedFilter == 'active') {
                      orders = orders
                          .where(
                            (d) => [
                              OrderStatus.preparing.value,
                              OrderStatus.onWay.value,
                              OrderStatus.readyForPickup.value,
                            ].contains(d.status),
                          )
                          .toList();
                    } else if (_selectedFilter != null) {
                      orders = orders
                          .where((d) => d.status == _selectedFilter)
                          .toList();
                    }
                  }

                  orders.sort((a, b) {
                    final t1 = a.createdAt;
                    final t2 = b.createdAt;
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
                      return _buildOrderCard(context, orders[index], ref);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String? status, String label, ThemeData theme) {
    final isSelected = _selectedFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? status : null;
        });
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  String _getAppBarTitle() {
    if (_selectedOrderId != null && _selectedOrderId!.isNotEmpty) {
      return 'Sipariş Detayı';
    }
    if (_selectedFilter == OrderStatus.pending.value) return 'Onay Bekleyenler';
    if (_selectedFilter == OrderStatus.preparing.value) return 'Hazırlananlar';
    if (_selectedFilter == OrderStatus.onWay.value) return 'Yoldakiler';
    if (_selectedFilter == OrderStatus.delivered.value) return 'Tamamlananlar';
    if (_selectedFilter == OrderStatus.cancelled.value) return 'İptaller';
    if (_selectedFilter == 'active') return 'Aktif Siparişler';
    return 'Tüm Siparişler';
  }

  Widget _buildOrderCard(
    BuildContext context,
    model.Order order,
    WidgetRef ref,
  ) {
    final status = order.status;
    final items = order.items;

    // YENİ: Gel Al kontrolü
    final bool isPickUp = order.deliveryMethod == 'pickup';

    final delayColor = _getOrderDelayColor(
      order.createdAt,
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
          backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              "Sipariş #${order.id.substring(0, 4).toUpperCase()}",
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
              "${items.length} Ürün • ${order.totalAmount} ₺",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_buildDelayIndicator(
                  order.createdAt,
                  status,
                ) !=
                null) ...[
              const SizedBox(height: 4),
              _buildDelayIndicator(
                order.createdAt,
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
                          "${item.quantity.toInt()}x",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.name.isNotEmpty ? item.name : "Bilinmeyen Ürün")),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      order.paymentMethod == "ONLINE_PAYMENT" ? "Online Kredi Kartı" : "Kapıda Ödeme",
                      style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey[800], fontSize: 13),
                    ),
                  ],
                ),
                if (order.dontRingBell || order.leaveAtDoor) ...[
                  const SizedBox(height: 8),
                  _buildDeliveryPreferenceBadges(
                    dontRingBell: order.dontRingBell,
                    leaveAtDoor: order.leaveAtDoor,
                    theme: theme,
                  ),
                ],
                if (order.orderNote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 16, color: Colors.orange[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.orderNote,
                            style: TextStyle(color: Colors.orange[900], fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.userAddress.isNotEmpty ? order.userAddress : '-',
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
                    _buildActionButton(order.id, status, isPickUp, ref),
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

  Widget _buildDeliveryPreferenceBadges({
    required bool dontRingBell,
    required bool leaveAtDoor,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          if (leaveAtDoor) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade300, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.door_front_door, size: 16, color: Colors.blue.shade800),
                  const SizedBox(width: 6),
                  Text(
                    "KAPIYA BIRAK 🚪",
                    style: TextStyle(
                      color: Colors.blue.shade900, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (dontRingBell) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade300, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off, size: 16, color: Colors.orange.shade800),
                  const SizedBox(width: 6),
                  Text(
                    "ZİLİ ÇALMA 🔕",
                    style: TextStyle(
                      color: Colors.orange.shade900, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String id,
    String status,
    bool isPickUp,
    WidgetRef ref,
  ) {
    final statusEnum = OrderStatus.fromString(status);

    Future<void> updateStatus(String newStatus) async {
      try {
        await ref.read(merchantOrderRepositoryProvider).updateOrderStatus(id, newStatus);
        ref.invalidate(merchantOrdersProvider);
      } catch (e) {
        print("Sipariş güncellenirken hata oluştu: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e")),
          );
        }
      }
    }

    Widget actionBtn = const SizedBox();
    switch (statusEnum) {
      case OrderStatus.pending:
        actionBtn = FilledButton.icon(
          onPressed: () => updateStatus(OrderStatus.preparing.value),
          icon: const Icon(Icons.check),
          label: const Text("ONAYLA"),
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
        );
        break;
      case OrderStatus.preparing:
        if (isPickUp) {
          actionBtn = FilledButton.icon(
            onPressed: () => updateStatus(OrderStatus.readyForPickup.value),
            icon: const Icon(Icons.store),
            label: Text(OrderStatus.readyForPickup.label),
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
          );
        } else {
          actionBtn = FilledButton.icon(
            onPressed: () => updateStatus(OrderStatus.onWay.value),
            icon: const Icon(Icons.motorcycle),
            label: const Text("KURYEYE VER"),
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
          );
        }
        break;
      case OrderStatus.onWay:
        actionBtn = FilledButton.icon(
          onPressed: () => updateStatus(OrderStatus.delivered.value),
          icon: const Icon(Icons.done),
          label: const Text("TESLİM ET"),
          style: FilledButton.styleFrom(backgroundColor: Colors.grey),
        );
        break;
      case OrderStatus.readyForPickup:
        actionBtn = FilledButton.icon(
          onPressed: () => updateStatus(OrderStatus.delivered.value),
          icon: const Icon(Icons.done_all),
          label: const Text("TESLİM ET"),
          style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
        );
        break;
      default:
        actionBtn = const SizedBox();
    }

    final bool canCancel = [OrderStatus.pending, OrderStatus.preparing, OrderStatus.onWay].contains(statusEnum);

    return Wrap(
      spacing: 8,
      children: [
        if (canCancel)
          TextButton.icon(
            onPressed: () => _showCancelDialog(context, id, ref),
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            label: const Text("İPTAL ET", style: TextStyle(color: Colors.red)),
          ),
        if (actionBtn is! SizedBox) actionBtn,
      ],
    );
  }

  void _showCancelDialog(BuildContext context, String orderId, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Siparişi İptal Et"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Bu siparişi iptal etmek istediğinize emin misiniz? Lütfen bir neden belirtin."),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: "İptal Nedeni",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Vazgeç"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen bir iptal nedeni giriniz.")),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await ref.read(merchantOrderRepositoryProvider).cancelOrder(orderId, reason);
                  ref.invalidate(merchantOrdersProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Sipariş iptal edildi.")),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Hata: $e")),
                    );
                  }
                }
              },
              child: const Text("Siparişi İptal Et"),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    return OrderStatus.fromString(status).color;
  }

  IconData _getStatusIcon(String status) {
    return OrderStatus.fromString(status).icon;
  }

  // YENİ: Gecikme Rengi
  Color _getOrderDelayColor(DateTime createdAt, String status) {
    // Sadece aktif siparişlerde gecikme kontrolü yapılır
    if (status == OrderStatus.delivered.value ||
        status == OrderStatus.cancelled.value) {
      return Colors.transparent;
    }

    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes >= 30) return Colors.red; // Kritik
    if (diff.inMinutes >= 15) return Colors.orange; // Uyarı
    return Colors.transparent; // Normal
  }

  // YENİ: Gecikme Metni
  Widget? _buildDelayIndicator(DateTime createdAt, String status) {
    if (status == OrderStatus.delivered.value ||
        status == OrderStatus.cancelled.value) {
      return null;
    }

    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 15) return null;

    final color = diff.inMinutes >= 30 ? Colors.red : Colors.orange;
    final text = diff.inMinutes >= 30 ? "KRİTİK GECİKME" : "GECİKMEYE BAŞLADI";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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

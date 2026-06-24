import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hoppa/shared/models/order.dart' as model;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_order_repository.dart';

import 'package:hoppa/shared/core/services/business_service.dart';
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/shared/models/business_type.dart';
import 'package:hoppa/shared/models/order_status.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final model.Order? order;
  final String? orderId;

  const OrderDetailPage({super.key, this.order, this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  final BusinessService _businessService = BusinessService();
  Business? _business;
  bool _isLoadingBusiness = true;
  model.Order? _order;
  bool _isLoadingOrder = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order == null && widget.orderId != null) {
      _fetchOrderDetails();
    } else {
      _fetchBusinessInfo();
    }
  }

  Future<void> _fetchOrderDetails() async {
    setState(() => _isLoadingOrder = true);
    try {
      final repository = ref.read(consumerOrderRepositoryProvider);
      final orders = await repository.getMyOrders();
      final order = orders.firstWhere((o) => o.id == widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoadingOrder = false;
        });
        _fetchBusinessInfo();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOrder = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sipariş yüklenemedi: $e")),
        );
      }
    }
  }

  Future<void> _fetchBusinessInfo() async {
    if (_order == null || _order!.businessId.isEmpty) {
      setState(() => _isLoadingBusiness = false);
      return;
    }

    final business = await _businessService.getBusinessById(
      _order!.businessId,
    );
    if (mounted) {
      setState(() {
        _business = business;
        _isLoadingBusiness = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_order == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final order = _order!;
    final status = order.status;
    final date = order.createdAt;
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F5F7,
      ), // Slightly darker for card contrast
      appBar: AppBar(
        title: const Text(
          "Sipariş Detayı",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. İŞLETME BİLGİ KARTI (EN ÜSTE)
          _buildCard(
            padding: EdgeInsets.zero,
            child: _isLoadingBusiness
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _business == null
                    ? const SizedBox.shrink()
                    : ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _business!.logoUrl.isNotEmpty
                              ? NetworkImage(_business!.logoUrl)
                              : null,
                          child: _business!.logoUrl.isEmpty
                              ? const Icon(Icons.store, color: Colors.grey)
                              : null,
                        ),
                        title: Text(
                          _business!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _business!.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (_business!.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(_business!.phone),
                                ],
                              ),
                            ],
                          ],
                        ),
                        // Optional: Add trailing call button if desired
                      ),
          ),

          const SizedBox(height: 16),

          // 2. SİPARİŞ DURUMU & TAKİP
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sipariş Durumu",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTrackingStepper(
                  status,
                  isPickup: order.deliveryMethod == 'pickup',
                ),
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Text(
                        "Sipariş No: #${order.id.substring(0, 8).toUpperCase()}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. SİPARİŞ İÇERİĞİ KARTI
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sipariş İçeriği",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                ...order.items.map((item) => _buildOrderItem(item)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. SİPARİŞ ÖZETİ & NOTU KARTI
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sipariş Özeti",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  "Ara Toplam",
                  "${order.totalAmount.toStringAsFixed(2)} ₺",
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  "Teslimat Ücreti",
                  "Ücretsiz",
                  valueColor: Colors.green,
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOPLAM TUTAR",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${order.totalAmount.toStringAsFixed(2)} ₺",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // NOT ALANI
                const Text(
                  "Sipariş Notu",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(
                      20,
                    ), // Light yellow background for note
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withAlpha(50)),
                  ),
                  child: Text(
                    order.orderNote.isNotEmpty
                        ? order.orderNote
                        : "Not Eklenmemiş",
                    style: TextStyle(
                      fontStyle: order.orderNote.isNotEmpty
                          ? FontStyle.normal
                          : FontStyle.italic,
                      color: order.orderNote.isNotEmpty
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                ),
                // Zili Çalma Tercihi
                if (order.dontRingBell) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 20,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Zili Çalma - Kurye arayarak haber verecek",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. TESLİMAT BİLGİLERİ (EN ALTTA)
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Teslimat Bilgileri",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Delivery Method & Time Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        order.userAddress.isEmpty
                            ? Icons.store
                            : Icons.local_shipping,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.deliveryMethod == 'pickup'
                                  ? "GEL AL"
                                  : "EVE TESLİM",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (order.deliveryTime.isEmpty ||
                                      order.deliveryTime
                                          .toLowerCase()
                                          .contains("dk") ||
                                      order.deliveryTime
                                          .toLowerCase()
                                          .contains("min"))
                                  ? "HEMEN TESLİM"
                                  : "Randevulu Teslim - ${order.deliveryTime}",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (order.deliveryMethod != 'pickup') ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.userAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),

                // MİNİ HARİTA (OpenStreetMap)
                if (order.addressLatitude != 0.0 &&
                    order.addressLongitude != 0.0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue[100]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            order.addressLatitude,
                            order.addressLongitude,
                          ),
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag
                                .none, // Disable interactions for mini map
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.hoppa.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  order.addressLatitude,
                                  order.addressLongitude,
                                ),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Fallback for orders without coordinates
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: Colors.grey,
                            size: 32,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Konum bilgisi yok",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12, // Softer shadow
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(model.OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}x",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
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

  Widget _buildTrackingStepper(String currentStatus, {bool isPickup = false}) {
    // Gel Al siparişlerinde "Yolda" yerine "Hazır"
    final steps = isPickup
        ? [
            OrderStatus.pending,
            OrderStatus.preparing,
            OrderStatus.readyForPickup,
            OrderStatus.delivered,
          ]
        : [
            OrderStatus.pending,
            OrderStatus.preparing,
            OrderStatus.onWay,
            OrderStatus.delivered,
          ];
    final stepTitles = steps.map((s) => s.label).toList();

    // İşletme türüne göre ikon seçimi
    IconData getPreparingIcon() {
      final type = _business?.type;
      switch (type) {
        case BusinessType.restaurant:
          return Icons.restaurant;
        case BusinessType.cafe:
          return Icons.coffee;
        case BusinessType.bakery:
          return Icons.bakery_dining;
        case BusinessType.butcher:
          return Icons.content_cut;
        case BusinessType.greengrocer:
          return Icons.eco;
        case BusinessType.water:
          return Icons.water_drop;
        case BusinessType.nuts:
          return Icons.grain;
        case BusinessType.florist:
          return Icons.local_florist;
        case BusinessType.market:
          return Icons.shopping_bag;
        default:
          return Icons.inventory_2;
      }
    }

    final stepIcons = [
      Icons.receipt_long,
      getPreparingIcon(),
      Icons.delivery_dining,
      Icons.check_circle,
    ];

    if (currentStatus == OrderStatus.cancelled.value) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 48),
            SizedBox(height: 12),
            Text(
              "Sipariş İptal Edildi",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    int currentIndex = -1;
    final currentEnum = OrderStatus.fromString(currentStatus);
    final idx = steps.indexOf(currentEnum);
    if (idx >= 0) {
      currentIndex = idx;
    }

    const double circleSize = 44;
    const Color activeColor = Color(0xFF00A651);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Her step'in genişliği
          final stepWidth = constraints.maxWidth / steps.length;
          // Çizgi başlangıç ve bitiş noktaları (daire merkezleri arası)
          final lineY = circleSize / 2;

          return Stack(
            children: [
              // Arka plan çizgileri (daire merkezleri arasında)
              for (int i = 0; i < steps.length - 1; i++)
                Positioned(
                  left: stepWidth * i + stepWidth / 2,
                  top: lineY - 1.5,
                  width: stepWidth,
                  height: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: i < currentIndex ? activeColor : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

              // Step daireleri ve etiketleri
              Row(
                children: List.generate(steps.length, (index) {
                  bool isCompleted = index <= currentIndex;
                  bool isCurrent = index == currentIndex;

                  return Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted ? activeColor : Colors.grey[200],
                            border: Border.all(
                              color: isCompleted
                                  ? activeColor
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: activeColor.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            stepIcons[index],
                            size: 22,
                            color: isCompleted
                                ? Colors.white
                                : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stepTitles[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isCompleted
                                ? Colors.black87
                                : Colors.grey[500],
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

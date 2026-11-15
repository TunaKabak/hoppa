import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/courier_models.dart';
import '../utils/distance_formatter.dart';

class CourierOrderCard extends StatelessWidget {
  final CourierOrder order;
  final double? courierLatitude;
  final double? courierLongitude;
  final bool isActionLoading;
  final Future<void> Function(String orderId) onPickup;
  final Future<void> Function(String orderId) onDeliver;

  const CourierOrderCard({
    super.key,
    required this.order,
    this.courierLatitude,
    this.courierLongitude,
    required this.isActionLoading,
    required this.onPickup,
    required this.onDeliver,
  });

  static const Color _hoppaOrange = Color(0xFFFF6B00);
  static const Color _hoppaGreen = Color(0xFF00A651);

  String? _computeActiveDistanceLabel() {
    final hasCourier = courierLatitude != null && courierLongitude != null;
    if (hasCourier) {
      if (order.isAwaitingPickup &&
          order.shop?.latitude != null &&
          order.shop?.longitude != null) {
        final km = calculateDistanceKm(
          lat1: courierLatitude!,
          lon1: courierLongitude!,
          lat2: order.shop!.latitude!,
          lon2: order.shop!.longitude!,
        );
        return 'Mağazaya: ${formatDistance(km)}';
      }
      if (order.isOnTheWay &&
          order.address?.latitude != null &&
          order.address?.longitude != null) {
        final km = calculateDistanceKm(
          lat1: courierLatitude!,
          lon1: courierLongitude!,
          lat2: order.address!.latitude!,
          lon2: order.address!.longitude!,
        );
        return 'Müşteriye: ${formatDistance(km)}';
      }
    }

    if (order.shop?.latitude != null &&
        order.shop?.longitude != null &&
        order.address?.latitude != null &&
        order.address?.longitude != null) {
      final km = calculateDistanceKm(
        lat1: order.shop!.latitude!,
        lon1: order.shop!.longitude!,
        lat2: order.address!.latitude!,
        lon2: order.address!.longitude!,
      );
      return 'Güzergah: ${formatDistance(km)}';
    }

    return null;
  }

  Future<void> _callPhone(
    BuildContext context,
    String? rawPhone,
    String targetLabel,
  ) async {
    final phone = rawPhone?.trim() ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$targetLabel telefon numarası bulunamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final sanitized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri(scheme: 'tel', path: sanitized);

    await _launchWithClipboardFallback(
      context,
      uri: uri,
      fallbackValue: phone,
      fallbackLabel: '$targetLabel telefonu',
    );
  }

  Future<void> _navigateToLocation(
    BuildContext context, {
    required double? latitude,
    required double? longitude,
    required String? addressQuery,
    required String targetLabel,
  }) async {
    String? queryParam;
    String fallbackText = '';

    if (latitude != null && longitude != null) {
      queryParam = '$latitude,$longitude';
      fallbackText = addressQuery?.trim().isNotEmpty == true
          ? addressQuery!.trim()
          : queryParam;
    } else if (addressQuery != null && addressQuery.trim().isNotEmpty) {
      queryParam = addressQuery.trim();
      fallbackText = queryParam;
    }

    if (queryParam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$targetLabel konum bilgisi bulunamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': queryParam,
    });

    await _launchWithClipboardFallback(
      context,
      uri: uri,
      fallbackValue: fallbackText,
      fallbackLabel: '$targetLabel adresi',
    );
  }

  Future<void> _launchWithClipboardFallback(
    BuildContext context, {
    required Uri uri,
    required String fallbackValue,
    required String fallbackLabel,
  }) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (e) {
      debugPrint('⚠️ Dış uygulama açılamadı ($uri): $e');
    }

    await Clipboard.setData(ClipboardData(text: fallbackValue));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Uygulama açılamadı; $fallbackLabel panoya kopyalandı: $fallbackValue',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceLabel = _computeActiveDistanceLabel();
    final isOnTheWay = order.isOnTheWay;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Order number + Status pill + Distance
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SİPARİŞ ${order.displayOrderNumber}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _hoppaOrange,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (distanceLabel != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distanceLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                _StatusPill(status: order.status),
              ],
            ),
            const SizedBox(height: 12),

            // Payment Warning / Status Banner
            _PaymentPill(order: order),
            const Divider(height: 24),

            // Shop Info
            _LocationInfoRow(
              icon: Icons.storefront_rounded,
              iconColor: _hoppaOrange,
              title: order.shop?.name ?? 'Mağaza',
              subtitle: order.shop?.address ?? 'Mağaza adresi belirtilmemiş',
              badgeText: 'ALIŞ NOKTASI',
            ),
            const SizedBox(height: 12),

            // Customer & Address Info
            _LocationInfoRow(
              icon: Icons.location_on_rounded,
              iconColor: _hoppaGreen,
              title: order.consumer?.fullName ?? 'Müşteri',
              subtitle: order.resolvedDeliveryAddress,
              badgeText: order.address?.title?.isNotEmpty == true
                  ? 'TESLİMAT • ${order.address!.title!.toUpperCase()}'
                  : 'TESLİMAT ADRESİ',
            ),

            // Special delivery flags (dontRingBell, leaveAtDoor) & customerNote
            if (order.dontRingBell ||
                order.leaveAtDoor ||
                (order.customerNote != null &&
                    order.customerNote!.isNotEmpty)) ...[
              const SizedBox(height: 12),
              if (order.dontRingBell || order.leaveAtDoor)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (order.dontRingBell)
                        const _InstructionChip(
                          label: '🔕 Zili Çalma',
                          bgColor: Color(0xFFFEF3C7),
                          textColor: Color(0xFF92400E),
                        ),
                      if (order.leaveAtDoor)
                        const _InstructionChip(
                          label: '🚪 Kapıya Bırak',
                          bgColor: Color(0xFFDBEAFE),
                          textColor: Color(0xFF1E40AF),
                        ),
                    ],
                  ),
                ),
              if (order.customerNote != null && order.customerNote!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 18,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerNote!,
                          style: const TextStyle(
                            color: Color(0xFF78350F),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // Action Buttons (Shop & Customer Call + Navigate)
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ActionOutlineButton(
                    icon: Icons.call_outlined,
                    label: 'Mağazayı Ara',
                    onPressed: () =>
                        _callPhone(context, order.shop?.phone, 'Mağaza'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionOutlineButton(
                    icon: Icons.directions_outlined,
                    label: 'Mağazaya Git',
                    onPressed: () => _navigateToLocation(
                      context,
                      latitude: order.shop?.latitude,
                      longitude: order.shop?.longitude,
                      addressQuery: order.shop?.address ?? order.shop?.name,
                      targetLabel: 'Mağaza',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ActionOutlineButton(
                    icon: Icons.phone_in_talk_outlined,
                    label: 'Müşteriyi Ara',
                    onPressed: () =>
                        _callPhone(context, order.consumer?.phone, 'Müşteri'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionOutlineButton(
                    icon: Icons.map_outlined,
                    label: 'Müşteriye Git',
                    onPressed: () => _navigateToLocation(
                      context,
                      latitude: order.address?.latitude,
                      longitude: order.address?.longitude,
                      addressQuery: order.resolvedDeliveryAddress,
                      targetLabel: 'Müşteri',
                    ),
                  ),
                ),
              ],
            ),

            // Items & Options Breakdown
            if (order.items.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Sipariş İçeriği (${order.items.length} kalem)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.formattedQuantity}x',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.options.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 34, top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.options.map((opt) {
                              final prefix = opt.isRemove ? '❌' : '➕';
                              final groupPrefix = opt.groupName.isNotEmpty
                                  ? '${opt.groupName}: '
                                  : '';
                              final qtyPrefix =
                                  !opt.isRemove && opt.quantity > 1
                                  ? '${opt.quantity}x '
                                  : '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '$prefix $qtyPrefix$groupPrefix${opt.name}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: opt.isRemove
                                        ? const Color(0xFFB91C1C)
                                        : const Color(0xFF475569),
                                    fontWeight: opt.isRemove
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const Divider(height: 22),

            // 2-Stage SwipeButton.expand
            SwipeButton.expand(
              key: ValueKey('${order.id}_${order.status}'),
              enabled: !isActionLoading,
              height: 54,
              borderRadius: BorderRadius.circular(14),
              activeTrackColor: isOnTheWay ? _hoppaGreen : _hoppaOrange,
              inactiveTrackColor: Colors.grey.shade300,
              activeThumbColor: Colors.white,
              inactiveThumbColor: Colors.grey.shade100,
              thumbPadding: const EdgeInsets.all(4),
              thumb: Icon(
                isOnTheWay
                    ? Icons.check_circle_rounded
                    : Icons.inventory_2_rounded,
                color: isOnTheWay ? _hoppaGreen : _hoppaOrange,
              ),
              onSwipe: () {
                if (isOnTheWay) {
                  onDeliver(order.id);
                } else {
                  onPickup(order.id);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 36, right: 12),
                child: Text(
                  isActionLoading
                      ? 'İşleniyor...'
                      : (isOnTheWay
                            ? 'Müşteriye Teslim Ettim'
                            : 'Mağazadan Teslim Aldım'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isOnTheWay = status == 'ON_THE_WAY';
    final bool isReady = status == 'READY_FOR_PICKUP';

    final Color bgColor;
    final Color textColor;
    final String label;

    if (isOnTheWay) {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
      label = 'Müşteriye Yolda';
    } else if (isReady) {
      bgColor = const Color(0xFFFFEDD5);
      textColor = const Color(0xFF9A3412);
      label = 'Mağazadan Teslim Alınacak • Hazır';
    } else {
      bgColor = const Color(0xFFDBEAFE);
      textColor = const Color(0xFF1E40AF);
      label = 'Mağazadan Teslim Alınacak';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PaymentPill extends StatelessWidget {
  final CourierOrder order;

  const _PaymentPill({required this.order});

  @override
  Widget build(BuildContext context) {
    final bool isOnline = order.paymentMethod == 'ONLINE_PAYMENT';
    final bool isWallet = order.paymentMethod == 'WALLET';
    final String amountText = '₺${order.totalAmount.toStringAsFixed(2)}';

    if (isOnline || isWallet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 18,
              color: Color(0xFF15803D),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isWallet
                    ? 'Hoppa Cüzdan ile Ödendi ($amountText)'
                    : 'Online Ödendi ($amountText)',
                style: const TextStyle(
                  color: Color(0xFF166534),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final String methodLabel;
    if (order.paymentMethod == 'CASH_ON_DELIVERY') {
      methodLabel = 'Kapıda Nakit Ödeme';
    } else if (order.paymentMethod == 'CARD_ON_DELIVERY') {
      methodLabel = 'Kapıda Kart / POS Ödeme';
    } else {
      methodLabel = 'Kapıda Ödeme';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.3),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Color(0xFFC2410C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$methodLabel • Tahsil Et: $amountText',
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String badgeText;
  final String title;
  final String subtitle;

  const _LocationInfoRow({
    required this.icon,
    required this.iconColor,
    required this.badgeText,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badgeText,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstructionChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _InstructionChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ActionOutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionOutlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0F172A),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 17, color: const Color(0xFFFF6B00)),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

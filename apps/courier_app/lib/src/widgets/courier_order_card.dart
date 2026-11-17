import 'package:core_ui/core_ui.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final distanceLabel = _computeActiveDistanceLabel();
    final isOnTheWay = order.isOnTheWay;
    final borderColor = isDark
        ? HoppaDesignTokens.borderOutdoorDark
        : HoppaDesignTokens.borderOutdoorLight;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusLg),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
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
                          fontFeatures: HoppaDesignTokens.tabularFigures,
                        ),
                      ),
                      if (distanceLabel != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.near_me_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distanceLabel,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFeatures: HoppaDesignTokens.tabularFigures,
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
                          icon: Icons.notifications_off_outlined,
                          label: 'Zili Çalma',
                          bgColor: Color(0xFFFEF3C7),
                          textColor: Color(0xFF92400E),
                        ),
                      if (order.leaveAtDoor)
                        const _InstructionChip(
                          icon: Icons.door_front_door_outlined,
                          label: 'Kapıya Bırak',
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

            // Action Buttons (Stage-Highlighted 48dp Touch Targets)
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ActionOutlineButton(
                    icon: Icons.call_outlined,
                    label: 'Mağazayı Ara',
                    isHighlighted: order.isAwaitingPickup,
                    onPressed: () =>
                        _callPhone(context, order.shop?.phone, 'Mağaza'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionOutlineButton(
                    icon: Icons.directions_outlined,
                    label: 'Mağazaya Git',
                    isHighlighted: order.isAwaitingPickup,
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
                    isHighlighted: isOnTheWay,
                    onPressed: () =>
                        _callPhone(context, order.consumer?.phone, 'Müşteri'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionOutlineButton(
                    icon: Icons.map_outlined,
                    label: 'Müşteriye Git',
                    isHighlighted: isOnTheWay,
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

            const Divider(height: 22),

            // Primary Field Action (Placed BEFORE collapsible item details)
            SwipeButton.expand(
              key: ValueKey('${order.id}_${order.status}'),
              enabled: !isActionLoading,
              height: 56,
              borderRadius: BorderRadius.circular(14),
              activeTrackColor: isOnTheWay ? _hoppaGreen : _hoppaOrange,
              inactiveTrackColor: isDark
                  ? HoppaDesignTokens.surfaceSubtleDark
                  : Colors.grey.shade300,
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
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            // Collapsible Items & Options Breakdown
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: order.items.length <= 2,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 6),
                  title: Text(
                    'Sipariş İçeriği (${order.items.length} kalem)',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: theme.colorScheme.onSurface,
                      fontFeatures: HoppaDesignTokens.tabularFigures,
                    ),
                  ),
                  children: order.items.map(
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
                                  color: theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item.formattedQuantity}x',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface,
                                    fontFeatures:
                                        HoppaDesignTokens.tabularFigures,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                    color: theme.colorScheme.onSurface,
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
                                  final prefix = opt.isRemove ? '-' : '+';
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
                                            ? (isDark
                                                ? HoppaDesignTokens
                                                    .statusDangerDark
                                                : const Color(0xFFB91C1C))
                                            : theme
                                                .colorScheme.onSurfaceVariant,
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
                  ).toList(),
                ),
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isOnline = order.paymentMethod == 'ONLINE_PAYMENT';
    final bool isWallet = order.paymentMethod == 'WALLET';
    final String amountText = '₺${order.totalAmount.toStringAsFixed(2)}';

    if (isOnline || isWallet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? HoppaDesignTokens.brandGreen.withValues(alpha: 0.16)
              : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? HoppaDesignTokens.statusSuccessDark.withValues(alpha: 0.4)
                : const Color(0xFFBBF7D0),
            width: 1.3,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified_rounded,
              size: 18,
              color: isDark
                  ? HoppaDesignTokens.statusSuccessDark
                  : const Color(0xFF15803D),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isWallet
                    ? 'Hoppa Cüzdan ile Ödendi ($amountText)'
                    : 'Online Ödendi ($amountText)',
                style: TextStyle(
                  color: isDark
                      ? HoppaDesignTokens.statusSuccessDark
                      : const Color(0xFF166534),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFeatures: HoppaDesignTokens.tabularFigures,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final String methodLabel;
    if (order.paymentMethod == 'CASH_ON_DELIVERY') {
      methodLabel = 'Kapıda Nakit';
    } else if (order.paymentMethod == 'CARD_ON_DELIVERY') {
      methodLabel = 'Kapıda Kart / POS';
    } else {
      methodLabel = 'Kapıda Ödeme';
    }

    final bannerBg = isDark
        ? HoppaDesignTokens.brandOrange.withValues(alpha: 0.16)
        : const Color(0xFFFFF7ED);
    final bannerBorder = isDark
        ? HoppaDesignTokens.brandOrange.withValues(alpha: 0.55)
        : const Color(0xFFFDBA74);
    final bannerAccent =
        isDark ? HoppaDesignTokens.statusWarningDark : const Color(0xFF9A3412);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payments_rounded,
            size: 24,
            color: bannerAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KAPIDA TAHSİL EDİLECEK',
                  style: TextStyle(
                    color: bannerAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: bannerAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    methodLabel,
                    style: TextStyle(
                      color: bannerAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF7C2D12),
              fontWeight: FontWeight.w900,
              fontSize: 24,
              fontFeatures: HoppaDesignTokens.tabularFigures,
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
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
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
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
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
  final IconData? icon;
  final String label;
  final Color bgColor;
  final Color textColor;

  const _InstructionChip({
    this.icon,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionOutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isHighlighted;

  const _ActionOutlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultBorder = isDark
        ? HoppaDesignTokens.borderOutdoorDark
        : HoppaDesignTokens.borderOutdoorLight;

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, HoppaDesignTokens.minTouchTarget),
        backgroundColor: isHighlighted
            ? HoppaDesignTokens.brandOrange.withValues(alpha: 0.12)
            : theme.colorScheme.surface,
        foregroundColor: isHighlighted
            ? HoppaDesignTokens.brandOrange
            : theme.colorScheme.onSurface,
        side: BorderSide(
          color: isHighlighted ? HoppaDesignTokens.brandOrange : defaultBorder,
          width: isHighlighted ? 1.8 : 1.3,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(
        icon,
        size: 18,
        color: HoppaDesignTokens.brandOrange,
      ),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

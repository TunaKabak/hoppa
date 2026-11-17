import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/courier_models.dart';
import '../utils/distance_formatter.dart';

class _RouteStop {
  final String label;
  final LatLng point;
  final bool isShop;
  final String orderCode;

  const _RouteStop({
    required this.label,
    required this.point,
    required this.isShop,
    required this.orderCode,
  });
}

/// Interactive courier route map with CartoDB light/dark tiles, nearest-neighbor
/// stop polyline, 48dp recenter button, and expandable height toggle.
class CourierRouteMapCard extends StatefulWidget {
  final List<CourierOrder> activeOrders;
  final double? courierLatitude;
  final double? courierLongitude;

  const CourierRouteMapCard({
    super.key,
    required this.activeOrders,
    this.courierLatitude,
    this.courierLongitude,
  });

  @override
  State<CourierRouteMapCard> createState() => _CourierRouteMapCardState();
}

class _CourierRouteMapCardState extends State<CourierRouteMapCard> {
  static const LatLng _kktcFallbackCenter = LatLng(35.1856, 33.3823);
  final MapController _mapController = MapController();
  bool _isExpanded = false;

  LatLng get _originPoint {
    if (widget.courierLatitude != null && widget.courierLongitude != null) {
      return LatLng(widget.courierLatitude!, widget.courierLongitude!);
    }
    for (final order in widget.activeOrders) {
      if (order.shop?.latitude != null && order.shop?.longitude != null) {
        return LatLng(order.shop!.latitude!, order.shop!.longitude!);
      }
      if (order.address?.latitude != null && order.address?.longitude != null) {
        return LatLng(order.address!.latitude!, order.address!.longitude!);
      }
    }
    return _kktcFallbackCenter;
  }

  List<_RouteStop> _buildOrderedStops(LatLng origin) {
    final pending = <_RouteStop>[];

    for (final order in widget.activeOrders) {
      if (order.isAwaitingPickup &&
          order.shop?.latitude != null &&
          order.shop?.longitude != null) {
        pending.add(
          _RouteStop(
            label: order.shop?.name ?? 'Mağaza',
            point: LatLng(order.shop!.latitude!, order.shop!.longitude!),
            isShop: true,
            orderCode: order.displayOrderNumber,
          ),
        );
      }
      if (order.address?.latitude != null && order.address?.longitude != null) {
        pending.add(
          _RouteStop(
            label: order.consumer?.fullName ?? 'Müşteri',
            point: LatLng(order.address!.latitude!, order.address!.longitude!),
            isShop: false,
            orderCode: order.displayOrderNumber,
          ),
        );
      }
    }

    if (pending.isEmpty) return const [];

    final remaining = List<_RouteStop>.from(pending);
    final ordered = <_RouteStop>[];
    LatLng cursor = origin;

    while (remaining.isNotEmpty) {
      int bestIdx = 0;
      double bestDist = double.infinity;

      for (int i = 0; i < remaining.length; i++) {
        final dist = calculateDistanceKm(
          lat1: cursor.latitude,
          lon1: cursor.longitude,
          lat2: remaining[i].point.latitude,
          lon2: remaining[i].point.longitude,
        );
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }

      final nextStop = remaining.removeAt(bestIdx);
      ordered.add(nextStop);
      cursor = nextStop.point;
    }

    return ordered;
  }

  double _computeTotalRouteKm(LatLng origin, List<_RouteStop> stops) {
    if (stops.isEmpty) return 0.0;
    double total = 0.0;
    LatLng prev = origin;
    for (final stop in stops) {
      total += calculateDistanceKm(
        lat1: prev.latitude,
        lon1: prev.longitude,
        lat2: stop.point.latitude,
        lon2: stop.point.longitude,
      );
      prev = stop.point;
    }
    return total;
  }

  void _recenterMap(LatLng center) {
    _mapController.move(center, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasCourierGps =
        widget.courierLatitude != null && widget.courierLongitude != null;
    final origin = _originPoint;
    final orderedStops = _buildOrderedStops(origin);
    final totalKm = _computeTotalRouteKm(origin, orderedStops);

    final routePoints = <LatLng>[
      origin,
      ...orderedStops.map((s) => s.point),
    ];

    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusLg),
        side: BorderSide(
          color: isDark
              ? HoppaDesignTokens.borderOutdoorDark
              : HoppaDesignTokens.borderOutdoorLight,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HoppaDesignTokens.brandOrange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: HoppaDesignTokens.brandOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Canlı Teslimat Rotası',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        orderedStops.isEmpty
                            ? (hasCourierGps
                                ? 'Konum aktif • Durak bekleniyor'
                                : 'Konum veya durak koordinatı bekleniyor')
                            : '${orderedStops.length} durak • ${formatDistance(totalKm)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFeatures: HoppaDesignTokens.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Konuma Odaklan',
                  onPressed: () => _recenterMap(origin),
                  constraints: const BoxConstraints(
                    minWidth: HoppaDesignTokens.minTouchTarget,
                    minHeight: HoppaDesignTokens.minTouchTarget,
                  ),
                  icon: const Icon(Icons.my_location_rounded),
                ),
                IconButton(
                  tooltip: _isExpanded ? 'Haritayı Küçült' : 'Haritayı Büyüt',
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  constraints: const BoxConstraints(
                    minWidth: HoppaDesignTokens.minTouchTarget,
                    minHeight: HoppaDesignTokens.minTouchTarget,
                  ),
                  icon: Icon(
                    _isExpanded
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            height: _isExpanded ? 300 : 190,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: origin,
                initialZoom: 13.8,
                minZoom: 4.0,
                maxZoom: 18.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.hoppa.courier',
                ),
                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 6.5,
                        color: HoppaDesignTokens.brandOrange
                            .withValues(alpha: 0.28),
                      ),
                      Polyline(
                        points: routePoints,
                        strokeWidth: 3.8,
                        color: HoppaDesignTokens.brandOrange,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (hasCourierGps)
                      Marker(
                        point: origin,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: HoppaDesignTokens.brandGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.two_wheeler_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    for (int i = 0; i < orderedStops.length; i++)
                      Marker(
                        point: orderedStops[i].point,
                        width: 46,
                        height: 46,
                        child: _StopMarkerPin(
                          index: i + 1,
                          isShop: orderedStops[i].isShop,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StopMarkerPin extends StatelessWidget {
  final int index;
  final bool isShop;

  const _StopMarkerPin({required this.index, required this.isShop});

  @override
  Widget build(BuildContext context) {
    final pinColor = isShop
        ? HoppaDesignTokens.brandOrange
        : HoppaDesignTokens.statusInfo;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 5,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isShop ? Icons.storefront_rounded : Icons.person_pin_circle,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 1),
              Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  fontFeatures: HoppaDesignTokens.tabularFigures,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

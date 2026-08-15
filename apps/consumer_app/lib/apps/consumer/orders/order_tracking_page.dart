import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_shared/shared/models/order.dart' as model;
import 'package:core_shared/shared/models/courier_location.dart';
import 'package:consumer_app/apps/consumer/widgets/selected_options_breakdown.dart';

// Tüketici tarafında kurye konumunu dinleyen Supabase Realtime StreamProvider
final courierLocationStreamProvider = StreamProvider.family<CourierLocation?, String>((ref, courierId) {
  try {
    final supabase = Supabase.instance.client;
    return supabase
        .from('CourierLocation')
        .stream(primaryKey: ['id'])
        .eq('courierId', courierId)
        .map((data) {
          if (data.isEmpty) return null;
          return CourierLocation.fromJson(data.first);
        });
  } catch (e) {
    debugPrint("Supabase Stream initialization error: $e");
    return const Stream.empty();
  }
});

class OrderTrackingPage extends ConsumerStatefulWidget {
  final model.Order order;

  const OrderTrackingPage({super.key, required this.order});

  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  // Tracking Data State
  late model.Order _currentOrder;
  Map<String, dynamic>? _trackingPayload;
  bool _isLoading = true;

  // Locations & Navigation
  LatLng? _courierLatLng;
  LatLng? _oldCourierLatLng;
  LatLng? _shopLatLng;
  late LatLng _destinationLatLng;
  double _currentBearing = 0.0;
  
  // Dynamic Distance & ETA
  double _distanceKm = 0.0;
  int _etaMinutes = 15;

  // Movement Animation
  AnimationController? _movementController;
  Animation<double>? _latAnimation;
  Animation<double>? _lngAnimation;
  Animation<double>? _bearingAnimation;

  // Radar Pulse Animation for Courier Pin
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  // Periodic REST Polling Timer for 100% fail-safe sync
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

    // Destination coordinates
    final destLat = _currentOrder.addressLatitude != 0.0 ? _currentOrder.addressLatitude : 35.1856;
    final destLng = _currentOrder.addressLongitude != 0.0 ? _currentOrder.addressLongitude : 33.3823;
    _destinationLatLng = LatLng(destLat, destLng);

    // Initialize Radar Animation
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _radarAnimation = Tween<double>(begin: 0.8, end: 2.2).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.easeOutQuad),
    );

    // Initial Fetch & Start Hybrid Sync
    _fetchTrackingData();
    _startPeriodicPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _movementController?.dispose();
    _radarController.dispose();
    super.dispose();
  }

  void _startPeriodicPolling() {
    _pollingTimer?.cancel();
    // Poll backend every 3 seconds for continuous real-time sync
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _fetchTrackingData(isSilent: true);
      }
    });
  }

  Future<void> _fetchTrackingData({bool isSilent = false}) async {
    if (!isSilent && _isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/api/consumer/orders/${_currentOrder.id}/tracking');

      if (response['data'] != null && mounted) {
        final data = response['data'];
        _trackingPayload = data;

        // Parse shop coordinates
        if (data['shop'] != null) {
          final sLat = double.tryParse(data['shop']['latitude']?.toString() ?? '') ?? 35.1856;
          final sLng = double.tryParse(data['shop']['longitude']?.toString() ?? '') ?? 33.3823;
          _shopLatLng = LatLng(sLat, sLng);
        }

        // Parse destination coordinates
        if (data['order'] != null) {
          final oLat = double.tryParse(data['order']['addressLatitude']?.toString() ?? '') ?? _destinationLatLng.latitude;
          final oLng = double.tryParse(data['order']['addressLongitude']?.toString() ?? '') ?? _destinationLatLng.longitude;
          _destinationLatLng = LatLng(oLat, oLng);
        }

        // Parse live courier location
        if (data['courier'] != null && data['courier']['location'] != null) {
          final loc = data['courier']['location'];
          final cLat = double.tryParse(loc['latitude']?.toString() ?? '');
          final cLng = double.tryParse(loc['longitude']?.toString() ?? '');
          final cBearing = double.tryParse(loc['bearing']?.toString() ?? '') ?? 0.0;

          if (cLat != null && cLng != null) {
            final targetLoc = LatLng(cLat, cLng);
            _updateCourierLocation(targetLoc, cBearing);
          }
        } else if (_courierLatLng == null && _shopLatLng != null) {
          // If courier is not yet broadcasting, place near shop as initial position
          _courierLatLng = _shopLatLng;
        }

        _calculateEtaAndDistance();

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Tracking polling error: $e");
      if (!isSilent && mounted) {
        setState(() {
          _isLoading = false;
          // Fallback to local coordinates so map always loads
          if (_courierLatLng == null && _shopLatLng != null) {
            _courierLatLng = _shopLatLng;
          }
        });
      }
    }
  }

  void _calculateEtaAndDistance() {
    final fromPoint = _courierLatLng ?? _shopLatLng ?? _destinationLatLng;
    const Distance distanceCalc = Distance();
    final meters = distanceCalc.as(LengthUnit.Meter, fromPoint, _destinationLatLng);
    
    _distanceKm = (meters / 1000.0);
    // Average urban courier speed with traffic factor: 26 km/h
    final rawMinutes = ((_distanceKm / 26.0) * 60).round();
    _etaMinutes = rawMinutes.clamp(3, 45);
  }

  double _calculateShortestAngle(double from, double to) {
    double difference = (to - from) % 360;
    if (difference > 180) {
      difference -= 360;
    } else if (difference < -180) {
      difference += 360;
    }
    return from + difference;
  }

  void _updateCourierLocation(LatLng targetPosition, double targetBearing) {
    if (_courierLatLng == null) {
      setState(() {
        _courierLatLng = targetPosition;
        _oldCourierLatLng = targetPosition;
        _currentBearing = targetBearing;
      });
      _fitMapBounds();
      return;
    }

    // Check if movement is significant (at least 1 meter)
    const Distance dist = Distance();
    if (dist.as(LengthUnit.Meter, _courierLatLng!, targetPosition) < 0.5) {
      return;
    }

    // Animation Interruption handling
    if (_movementController != null && _movementController!.isAnimating) {
      _oldCourierLatLng = LatLng(
        _latAnimation!.value,
        _lngAnimation!.value,
      );
      if (_bearingAnimation != null) {
        _currentBearing = _bearingAnimation!.value;
      }
    } else {
      _oldCourierLatLng = _courierLatLng;
    }

    final double shortestTargetBearing = _calculateShortestAngle(_currentBearing, targetBearing);

    _movementController?.dispose();
    _movementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _latAnimation = Tween<double>(
      begin: _oldCourierLatLng!.latitude,
      end: targetPosition.latitude,
    ).animate(CurvedAnimation(parent: _movementController!, curve: Curves.easeInOut));

    _lngAnimation = Tween<double>(
      begin: _oldCourierLatLng!.longitude,
      end: targetPosition.longitude,
    ).animate(CurvedAnimation(parent: _movementController!, curve: Curves.easeInOut));

    _bearingAnimation = Tween<double>(
      begin: _currentBearing,
      end: shortestTargetBearing,
    ).animate(CurvedAnimation(parent: _movementController!, curve: Curves.easeInOut));

    _movementController!.addListener(() {
      if (mounted) {
        setState(() {
          _courierLatLng = LatLng(_latAnimation!.value, _lngAnimation!.value);
          _currentBearing = _bearingAnimation!.value % 360;
          _calculateEtaAndDistance();
        });
      }
    });

    _movementController!.forward();
  }

  void _fitMapBounds() {
    final points = <LatLng>[];
    if (_courierLatLng != null) points.add(_courierLatLng!);
    if (_shopLatLng != null) points.add(_shopLatLng!);
    points.add(_destinationLatLng);

    if (points.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (points.length == 1) {
          _mapController.move(points.first, 15);
        } else {
          final bounds = LatLngBounds.fromPoints(points);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.only(top: 130, bottom: 290, left: 45, right: 45),
            ),
          );
        }
      }
    });
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) return;
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(RegExp(r'\s+'), ''),
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint("Phone call error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandOrange = Color(0xFFFF6B00);
    const brandGreen = Color(0xFF00A651);
    final courierId = _trackingPayload?['courier']?['id'] ?? _currentOrder.courierId;

    // Listen to Supabase Stream if courierId exists (with fallback to REST polling)
    if (courierId != null && courierId.toString().isNotEmpty) {
      ref.listen<AsyncValue<CourierLocation?>>(
        courierLocationStreamProvider(courierId.toString()),
        (prev, next) {
          next.whenData((loc) {
            if (loc != null && mounted) {
              _updateCourierLocation(
                LatLng(loc.latitude, loc.longitude),
                loc.bearing,
              );
            }
          });
        },
      );
    }

    final courierData = _trackingPayload?['courier'];
    final shopData = _trackingPayload?['shop'];
    final orderData = _trackingPayload?['order'] ?? _currentOrder;
    final statusStr = (orderData['status'] ?? _currentOrder.status ?? 'PENDING').toString().toUpperCase();

    // Map Center fallback
    final initialCenter = _courierLatLng ?? _shopLatLng ?? _destinationLatLng;

    return Scaffold(
      body: Stack(
        children: [
          // ===================================================================
          // 1. FLUTTER MAP
          // ===================================================================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
              minZoom: 4.0,
              maxZoom: 19.0,
            ),
            children: [
              // High Performance OpenStreetMap Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hoppa.consumer',
              ),

              // Map Markers
              MarkerLayer(
                markers: [
                  // Shop Marker 🏪
                  if (_shopLatLng != null)
                    Marker(
                      point: _shopLatLng!,
                      width: 50,
                      height: 50,
                      child: _buildShopMarker(shopData?['name'] ?? 'İşletme'),
                    ),

                  // Destination Marker 🏠
                  Marker(
                    point: _destinationLatLng,
                    width: 55,
                    height: 55,
                    child: _buildDestinationMarker(),
                  ),

                  // Live Moving Courier Marker 🛵
                  if (_courierLatLng != null)
                    Marker(
                      point: _courierLatLng!,
                      width: 70,
                      height: 70,
                      child: _buildCourierMarker(),
                    ),
                ],
              ),
            ],
          ),

          // ===================================================================
          // 2. TOP FLOATING STATUS & ETA BAR
          // ===================================================================
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back Button
                _buildCircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),

                // Live Dynamic Status Pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        // Blinking Live GPS Dot
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: brandGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: brandGreen.withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                statusStr == 'ON_THE_WAY' || statusStr == 'ONWAY'
                                    ? "Tahmini Varış: $_etaMinutes dk"
                                    : (statusStr == 'PREPARING' ? "Sipariş Hazırlanıyor" : "Canlı Takip"),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                "${_distanceKm.toStringAsFixed(1)} km uzakta • Canlı GPS",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Re-center / Fit Bounds Button
                _buildCircleIconButton(
                  icon: Icons.my_location_rounded,
                  iconColor: brandOrange,
                  onTap: _fitMapBounds,
                ),
              ],
            ),
          ),

          // ===================================================================
          // 3. BOTTOM SLIDING SHEET / FLOATING DETAIL CARD
          // ===================================================================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomTrackingSheet(
              context,
              statusStr: statusStr,
              courierData: courierData,
              shopData: shopData,
              orderData: orderData,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET BUILDERS
  // ===========================================================================

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Icon(icon, color: iconColor ?? const Color(0xFF1E293B), size: 20),
        ),
      ),
    );
  }

  Widget _buildCourierMarker() {
    return AnimatedBuilder(
      animation: _radarAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glowing Radar Pulse Wave
            Container(
              width: 32 * _radarAnimation.value,
              height: 32 * _radarAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B00).withValues(
                  alpha: (1.0 - (_radarAnimation.value - 0.8) / 1.4).clamp(0.0, 0.4),
                ),
              ),
            ),

            // Rotating Courier Badge with Bearing Angle
            Transform.rotate(
              angle: (_currentBearing * math.pi / 180),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShopMarker(String shopName) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.indigo,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.home_rounded,
            color: Colors.red,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomTrackingSheet(
    BuildContext context, {
    required String statusStr,
    required dynamic courierData,
    required dynamic shopData,
    required dynamic orderData,
  }) {
    const brandOrange = Color(0xFFFF6B00);
    final courierName = courierData?['name'] ?? _currentOrder.courierName ?? 'Hoppa Kuryesi';
    final courierPhone = courierData?['phoneNumber'] ?? _currentOrder.courierPhone;
    final vehiclePlate = courierData?['vehiclePlate'] ?? _currentOrder.courierVehiclePlate ?? '';
    final vehicleType = courierData?['vehicleType'] ?? 'Motosiklet';
    final shopName = shopData?['name'] ?? _currentOrder.businessName ?? 'İşletme';
    final shopPhone = shopData?['phone'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Order Status Stepper
          _buildLiveStatusStepper(statusStr),
          const SizedBox(height: 16),

          // Courier Profile Card (If courier is assigned)
          if (courierData != null || courierName.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // Courier Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: brandOrange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.sports_motorsports_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),

                  // Courier Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              courierName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A651).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Kurye",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00A651),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vehiclePlate.isNotEmpty ? "$vehicleType • $vehiclePlate" : vehicleType,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Call Courier Button
                  if (courierPhone != null && courierPhone.toString().isNotEmpty)
                    IconButton.filled(
                      onPressed: () => _makePhoneCall(courierPhone.toString()),
                      icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF00A651),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Shop and Delivery Info Summary
          Row(
            children: [
              // Shop pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 18, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      if (shopPhone != null && shopPhone.toString().isNotEmpty)
                        GestureDetector(
                          onTap: () => _makePhoneCall(shopPhone.toString()),
                          child: const Icon(Icons.phone_outlined, size: 16, color: Colors.indigo),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Destination Address pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentOrder.userAddress.isNotEmpty ? _currentOrder.userAddress : 'Teslimat Adresi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Customer Note / Preferences (if any)
          if (_currentOrder.orderNote.isNotEmpty || _currentOrder.dontRingBell || _currentOrder.leaveAtDoor) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (_currentOrder.dontRingBell)
                  _buildPreferenceBadge("🔕 Zili Çalma"),
                if (_currentOrder.leaveAtDoor)
                  _buildPreferenceBadge("🚪 Kapıya Bırak"),
                if (_currentOrder.orderNote.isNotEmpty)
                  _buildPreferenceBadge("💬 Not: ${_currentOrder.orderNote}"),
              ],
            ),
          ],

          // Sipariş Kalemleri ve Opsiyon Detayları
          if (_currentOrder.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                dense: true,
                leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFFFF6B00), size: 20),
                title: Text(
                  "${_currentOrder.items.length} Ürün • ${_currentOrder.totalAmount.toStringAsFixed(2)} ₺",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                ),
                children: _currentOrder.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}x",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              if (item.options.isNotEmpty)
                                SelectedOptionsBreakdown(
                                  options: item.options,
                                  quantity: item.quantity,
                                  isCompact: true,
                                  isCollapsible: true,
                                  initiallyExpanded: false,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${(item.price * item.quantity).toStringAsFixed(2)} ₺",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferenceBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
      ),
    );
  }

  Widget _buildLiveStatusStepper(String status) {
    const brandOrange = Color(0xFFFF6B00);
    int currentStep = 0;
    if (status == 'PREPARING') currentStep = 1;
    if (status == 'ON_THE_WAY' || status == 'ONWAY') currentStep = 2;
    if (status == 'DELIVERED') currentStep = 3;

    final steps = [
      {'label': 'Alındı', 'icon': Icons.check_circle_rounded},
      {'label': 'Hazırlanıyor', 'icon': Icons.outdoor_grill_rounded},
      {'label': 'Yolda', 'icon': Icons.two_wheeler_rounded},
      {'label': 'Teslim Edildi', 'icon': Icons.home_rounded},
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIdx = index ~/ 2;
          final isPassed = stepIdx < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              color: isPassed ? brandOrange : Colors.grey[300],
            ),
          );
        }

        final stepIdx = index ~/ 2;
        final isActive = stepIdx == currentStep;
        final isPassed = stepIdx <= currentStep;
        final step = steps[stepIdx];

        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isPassed ? brandOrange : Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? brandOrange.withValues(alpha: 0.3) : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Icon(
                step['icon'] as IconData,
                size: 16,
                color: isPassed ? Colors.white : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step['label'] as String,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isPassed ? FontWeight.bold : FontWeight.w500,
                color: isPassed ? const Color(0xFF1E293B) : Colors.grey[400],
              ),
            ),
          ],
        );
      }),
    );
  }
}

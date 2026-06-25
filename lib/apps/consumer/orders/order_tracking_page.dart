import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hoppa/shared/models/order.dart' as model;
import 'package:hoppa/shared/models/courier_location.dart';

// Tüketici tarafında kurye konumunu dinleyen Riverpod StreamProvider
final courierLocationStreamProvider = StreamProvider.family<CourierLocation, String>((ref, courierId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('CourierLocation')
      .stream(primaryKey: ['id'])
      .eq('courierId', courierId)
      .map((data) {
        if (data.isEmpty) {
          throw Exception("Kurye konumu bulunamadı.");
        }
        return CourierLocation.fromJson(data.first);
      });
});

class OrderTrackingPage extends ConsumerStatefulWidget {
  final model.Order order;

  const OrderTrackingPage({super.key, required this.order});

  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _previousCourierLatLng;
  LatLng? _currentCourierLatLng;
  double _currentBearing = 0.0;
  
  // Animation coordinates for smooth transition
  AnimationController? _movementController;
  Animation<double>? _latAnimation;
  Animation<double>? _lngAnimation;

  @override
  void dispose() {
    _movementController?.dispose();
    super.dispose();
  }

  void _animateCourierMovement(LatLng newLocation) {
    if (_currentCourierLatLng == null) {
      setState(() {
        _currentCourierLatLng = newLocation;
      });
      return;
    }

    _previousCourierLatLng = _currentCourierLatLng;
    
    _movementController?.dispose();
    _movementController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _latAnimation = Tween<double>(
      begin: _previousCourierLatLng!.latitude,
      end: newLocation.latitude,
    ).animate(CurvedAnimation(parent: _movementController!, curve: Curves.easeInOut));

    _lngAnimation = Tween<double>(
      begin: _previousCourierLatLng!.longitude,
      end: newLocation.longitude,
    ).animate(CurvedAnimation(parent: _movementController!, curve: Curves.easeInOut));

    _movementController!.addListener(() {
      if (mounted) {
        setState(() {
          _currentCourierLatLng = LatLng(_latAnimation!.value, _lngAnimation!.value);
        });
      }
    });

    _movementController!.forward();
  }

  void _fitMapBounds(LatLng courierLoc, LatLng destLoc) {
    // Fit map bounds to show both points with padding
    final bounds = LatLngBounds(courierLoc, destLoc);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(70.0),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courierId = widget.order.courierId;
    
    // Fallback coordinates if order has no destination coordinates
    final destinationLatLng = LatLng(
      widget.order.addressLatitude != 0.0 ? widget.order.addressLatitude : 35.1856,
      widget.order.addressLongitude != 0.0 ? widget.order.addressLongitude : 33.3823,
    );

    if (courierId == null || courierId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sipariş Takibi")),
        body: const Center(
          child: Text(
            "Bu sipariş için atanmış kurye bilgisi bulunamadı.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final courierLocationAsync = ref.watch(courierLocationStreamProvider(courierId));

    return Scaffold(
      body: Stack(
        children: [
          // MAP VIEW
          courierLocationAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) {
              print("Supabase Stream Hatası: $err");
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 220.0, left: 24.0, right: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off_outlined,
                        size: 54,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Bağlantı Sorunu",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Kurye konumu şu anda canlı olarak alınamıyor. Bağlantı arka planda otomatik olarak yeniden deneniyor...",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(courierLocationStreamProvider(courierId));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Yeniden Dene"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
            data: (courierLocation) {
              final newLocation = LatLng(courierLocation.latitude, courierLocation.longitude);
              
              // Trigger smooth animation and map frame update on new coordinate
              if (_currentCourierLatLng == null || 
                  _currentCourierLatLng!.latitude != newLocation.latitude ||
                  _currentCourierLatLng!.longitude != newLocation.longitude) {
                
                _animateCourierMovement(newLocation);
                _currentBearing = courierLocation.bearing;
                _fitMapBounds(newLocation, destinationLatLng);
              }

              final activeCourierLoc = _currentCourierLatLng ?? newLocation;

              // Calculate current distance
              final double distanceInMeters = Geolocator.distanceBetween(
                activeCourierLoc.latitude,
                activeCourierLoc.longitude,
                destinationLatLng.latitude,
                destinationLatLng.longitude,
              );
              
              final String distanceText = distanceInMeters > 1000
                  ? "${(distanceInMeters / 1000).toStringAsFixed(1)} km"
                  : "${distanceInMeters.round()} metre";

              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: destinationLatLng,
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.hoppa.app',
                      ),
                      // Line connecting courier to destination
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [activeCourierLoc, destinationLatLng],
                            strokeWidth: 4.0,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                            pattern: const StrokePattern.dotted(),
                          ),
                        ],
                      ),
                      // Markers
                      MarkerLayer(
                        markers: [
                          // Destination Marker
                          Marker(
                            point: destinationLatLng,
                            width: 50,
                            height: 50,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ],
                            ),
                          ),
                          // Courier Marker
                          Marker(
                            point: activeCourierLoc,
                            width: 60,
                            height: 60,
                            child: Transform.rotate(
                              angle: _currentBearing * math.pi / 180,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.motorcycle,
                                    color: theme.colorScheme.primary,
                                    size: 30,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // TOP HEADER INFO (OVERLAY)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_filled, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Kuryeniz Yaklaşıyor",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Mesafe: $distanceText",
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // BACK BUTTON
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // BOTTOM CONTROL PANEL
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Süleyman Kurye",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Motorlu Kurye • 34 HO 9999",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          // Call courier simulated
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Kurye ile bağlantı kuruluyor...")),
                          );
                        },
                        icon: const Icon(Icons.phone),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.delivery_dining, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "Siparişiniz Yolda 🛵",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

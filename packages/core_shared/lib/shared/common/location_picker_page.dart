import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:core_shared/shared/core/data/kktc_boundary.dart';

class LocationPickerPage extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const LocationPickerPage({
    super.key,
    this.initialLatitude = 35.1856, // Default (Lefkoşa)
    this.initialLongitude = 33.3823,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late final MapController _mapController;
  late LatLng _currentCenter;
  bool _isLoading = true;
  bool _isDragging = false;
  bool _isSatellite = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    final validLat = isLocationInKktc(widget.initialLatitude, widget.initialLongitude)
        ? widget.initialLatitude
        : kKktcDefaultCenter.latitude;
    final validLng = isLocationInKktc(widget.initialLatitude, widget.initialLongitude)
        ? widget.initialLongitude
        : kKktcDefaultCenter.longitude;
    _currentCenter = LatLng(validLat, validLng);
    _checkPermissionAndLocate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _searchAddress(String query) async {
    if (query.isEmpty) return [];
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1&countrycodes=cy,tr',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'HoppaApp/1.0',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => {
          'display_name': item['display_name'] ?? '',
          'lat': double.tryParse(item['lat']?.toString() ?? '') ?? 0.0,
          'lon': double.tryParse(item['lon']?.toString() ?? '') ?? 0.0,
        }).toList();
      }
    } catch (e) {
      debugPrint("Nominatim Search Error: $e");
    }
    return [];
  }

  void _debounceSearch(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.length > 2) {
        final results = await _searchAddress(query);
        setState(() {
          _searchResults = results;
        });
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _checkPermissionAndLocate() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      if (widget.initialLatitude == 0 && widget.initialLongitude == 0) {
        _moveToCurrentLocation();
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!isLocationInKktc(position.latitude, position.longitude)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ Mevcut konumunuz KKTC sınırları dışındadır."),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController.move(latLng, 15);
      setState(() {
        _currentCenter = latLng;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Location Error: $e");
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        _currentCenter = camera.center;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isInsideKktc = isLocationInKktc(_currentCenter.latitude, _currentCenter.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Konum Seçin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              minZoom: 8.5,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(bounds: kKktcMapBounds),
              onPositionChanged: _onPositionChanged,
              onMapEvent: (event) {
                if (event is MapEventMoveStart) {
                  setState(() {
                    _isDragging = true;
                  });
                } else if (event is MapEventMoveEnd) {
                  setState(() {
                    _isDragging = false;
                    _currentCenter = event.camera.center;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hoppa',
              ),
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: kWorldOuterBounds,
                    holePointsList: [kKktcPolygon],
                    color: Colors.black.withValues(alpha: 0.45),
                    borderColor: const Color(0xFFFF6B00),
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
            ],
          ),
          // ANIMATED CENTER PIN & TARGET DOT
          Center(
            child: MapPinWidget(
              isDragging: _isDragging,
              primaryColor: Theme.of(context).primaryColor,
              isOutsideKktc: !isInsideKktc,
            ),
          ),
          // FLOATING KKTC ACTIVE ZONE BADGE
          Positioned(
            top: 76,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF6B00), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, color: Color(0xFF00A651), size: 14),
                  SizedBox(width: 5),
                  Text(
                    "Hizmet Bölgesi: KKTC",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // OUTSIDE KKTC WARNING BANNER
          if (!isInsideKktc)
            Positioned(
              bottom: 96,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Seçilen konum KKTC dışındadır. Lütfen haritayı KKTC sınırlarına kaydırın.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // SEARCH BAR & LAYER TOGGLE CARD
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'KKTC içi Konum Ara...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: _debounceSearch,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                            });
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _isSatellite ? Icons.map_outlined : Icons.satellite_alt_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSatellite = !_isSatellite;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                          title: Text(
                            item['display_name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () {
                            final lat = item['lat'] as double;
                            final lon = item['lon'] as double;
                            if (!isLocationInKktc(lat, lon)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("⚠️ Seçilen arama sonucu KKTC sınırları dışındadır."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            _mapController.move(LatLng(lat, lon), 16.0);
                            setState(() {
                              _currentCenter = LatLng(lat, lon);
                              _searchResults = [];
                              _searchController.text = item['display_name'] ?? '';
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: isInsideKktc
                  ? () {
                      Navigator.pop(context, _currentCenter);
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("⚠️ Yalnızca KKTC sınırları içerisinden konum seçebilirsiniz."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isInsideKktc ? Theme.of(context).primaryColor : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isInsideKktc) ...[
                    const Icon(Icons.block, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isInsideKktc ? "Bu Konumu Seç" : "KKTC Dışı Konum Seçilemez",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

class MapPinWidget extends StatelessWidget {
  final bool isDragging;
  final Color primaryColor;
  final bool isOutsideKktc;

  const MapPinWidget({
    super.key,
    required this.isDragging,
    required this.primaryColor,
    this.isOutsideKktc = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = isOutsideKktc ? const Color(0xFFDC2626) : primaryColor;
    return SizedBox(
      width: 100,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Static Dot and Shadow at the bottom (exact target point)
          Positioned(
            bottom: 50,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isDragging ? 16 : 8,
              height: isDragging ? 6 : 8,
              decoration: BoxDecoration(
                color: isDragging
                    ? (isOutsideKktc ? Colors.red.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.15))
                    : (isOutsideKktc ? Colors.red.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.all(Radius.elliptical(isDragging ? 8 : 4, isDragging ? 3 : 4)),
              ),
            ),
          ),
          // 2. Connecting Line (vertical line from target point to pin tip)
          if (isDragging)
            Positioned(
              bottom: 50,
              child: CustomPaint(
                size: const Size(2, 35),
                painter: DashedLinePainter(color: effectiveColor),
              ),
            ),
          // 3. Floating Pin
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            bottom: isDragging ? 85 : 50,
            child: _buildPinBody(effectiveColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPinBody(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isOutsideKktc ? Colors.red.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isOutsideKktc ? Icons.location_off : Icons.location_on,
            color: color,
            size: 32,
          ),
        ),
        CustomPaint(
          size: const Size(12, 8),
          painter: TrianglePainter(color: Colors.white),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..style = PaintingStyle.stroke;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

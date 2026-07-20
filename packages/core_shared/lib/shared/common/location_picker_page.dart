import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPickerPage extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const LocationPickerPage({
    super.key,
    this.initialLatitude = 35.1856, // Default default (Nicosia approx)
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
    _currentCenter = LatLng(widget.initialLatitude, widget.initialLongitude);
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
    _currentCenter = camera.center;
  }

  @override
  Widget build(BuildContext context) {
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
              onPositionChanged: _onPositionChanged,
              onMapEvent: (event) {
                if (event is MapEventMoveStart) {
                  setState(() {
                    _isDragging = true;
                  });
                } else if (event is MapEventMoveEnd) {
                  setState(() {
                    _isDragging = false;
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
            ],
          ),
          // ANIMATED CENTER PIN & TARGET DOT
          Center(
            child: MapPinWidget(
              isDragging: _isDragging,
              primaryColor: Theme.of(context).primaryColor,
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
                            hintText: 'Konum Ara...',
                            border: InputBorder.none,
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
              onPressed: () {
                Navigator.pop(context, _currentCenter);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Bu Konumu Seç",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  const MapPinWidget({
    super.key,
    required this.isDragging,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
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
                color: isDragging ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.4),
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
                painter: DashedLinePainter(color: primaryColor),
              ),
            ),
          // 3. Floating Pin
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            bottom: isDragging ? 85 : 50,
            child: _buildPinBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildPinBody() {
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
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.location_on,
            color: primaryColor,
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

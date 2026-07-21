import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:consumer_app/apps/consumer/repositories/address_repository.dart';
import 'package:core_shared/shared/models/address.dart';
import 'package:core_shared/shared/core/data/kktc_districts.dart';
import 'package:consumer_app/apps/consumer/providers/consumer_location_controller.dart';
import 'package:core_auth/core_auth.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';

class AddAddressPage extends ConsumerStatefulWidget {
  final Address? addressToEdit; // Düzenlenecek adres (Opsiyonel)

  const AddAddressPage({super.key, this.addressToEdit});

  @override
  ConsumerState<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends ConsumerState<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;

  String? _selectedCity;
  String? _selectedDistrict;

  bool _isLoading = false;
  bool _isLocationGetting = false;
  bool _isSatellite = false;
  bool _isLocationVerified = false;
  bool _isDragging = false;
  double _latitude = 35.1856; // Default: Nicosia
  double _longitude = 33.3823;

  final List<String> _cities = kKktcDistricts.keys.toList()..sort();
  final List<String> _quickTitles = ['Ev', 'İş', 'Diğer'];
  String _selectedQuickTitle = '';

  @override
  void initState() {
    super.initState();
    _isLocationVerified = widget.addressToEdit != null;

    // EĞER DÜZENLEME MODUYSA VERİLERİ DOLDUR
    if (widget.addressToEdit != null) {
      final addr = widget.addressToEdit!;
      _titleController.text = addr.title;
      _detailsController.text = addr.fullDetails;
      _latitude = addr.latitude;
      _longitude = addr.longitude;

      // Şehir ve Bölge Seçimi
      if (_cities.contains(addr.city)) {
        _selectedCity = addr.city;
        if (kKktcDistricts[_selectedCity]!.contains(addr.district)) {
          _selectedDistrict = addr.district;
        } else {
          _selectedDistrict = kKktcDistricts[_selectedCity]!.first;
        }
      } else {
        _selectedCity = _cities.first;
        _selectedDistrict = kKktcDistricts[_selectedCity]!.first;
      }

      // Hızlı başlık kontrolü
      if (_quickTitles.contains(addr.title)) {
        _selectedQuickTitle = addr.title;
      }
    } else {
      // YENİ EKLEME MODU
      _selectedCity = _cities.first;
      _selectedDistrict = kKktcDistricts[_selectedCity]!.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
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

  Future<void> _fetchAndSetLocation() async {
    setState(() => _isLocationGetting = true);

    try {
      final result = await ref.read(consumerLocationProvider.notifier).determineLocation();
      
      if (result != null) {
        setState(() {
          _latitude = result.latitude;
          _longitude = result.longitude;
          
          if (_cities.contains(result.city)) {
            _selectedCity = result.city;
            if (kKktcDistricts[result.city]!.contains(result.district)) {
              _selectedDistrict = result.district;
            } else {
              _selectedDistrict = null;
            }
          } else {
            _selectedCity = null;
            _selectedDistrict = null;
          }
          
          _detailsController.text = result.streetAddress;
        });

        _mapController.move(LatLng(result.latitude, result.longitude), 15.0);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Konum başarıyla alındı.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Konum alınamadı, lütfen manuel giriniz."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocationGetting = false);
      }
    }
  }

  Future<void> _resolveAddress(double lat, double lng) async {
    setState(() {
      _latitude = lat;
      _longitude = lng;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String? foundCity;

        for (var city in _cities) {
          if (place.administrativeArea?.contains(city) == true ||
              place.subAdministrativeArea?.contains(city) == true ||
              place.locality?.contains(city) == true) {
            foundCity = city;
            break;
          }
        }

        String street = place.thoroughfare ?? '';
        String number = place.subThoroughfare ?? '';
        if (street.toLowerCase().contains("unnamed road")) {
          street = "";
        }

        if (foundCity != null) {
          if (mounted) {
            setState(() {
              _selectedCity = foundCity;
              if (kKktcDistricts[foundCity]!.contains(place.subLocality)) {
                _selectedDistrict = place.subLocality;
              } else {
                _selectedDistrict = kKktcDistricts[foundCity]!.first;
              }
            });

            if (street.isNotEmpty) {
              _detailsController.text = "$street $number".trim();
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _selectedCity = null;
              _selectedDistrict = null;
            });
            if (street.isNotEmpty) {
              _detailsController.text = "$street $number".trim();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Adres çözümleme hatası: $e");
    }
  }

  void _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Lütfen şehir ve bölge seçiniz"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authControllerProvider);
      final bool isGuest = authState is! AuthAuthenticated;

      Address savedAddress;
      if (isGuest) {
        savedAddress = Address(
          id: widget.addressToEdit?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
          title: _titleController.text,
          city: _selectedCity!,
          district: _selectedDistrict!,
          fullDetails: _detailsController.text,
          latitude: _latitude,
          longitude: _longitude,
        );
      } else {
        final addressData = Address(
          id: widget.addressToEdit?.id ?? '',
          title: _titleController.text,
          city: _selectedCity!,
          district: _selectedDistrict!,
          fullDetails: _detailsController.text,
          latitude: _latitude,
          longitude: _longitude,
        );

        final repo = ref.read(addressRepositoryProvider);
        if (widget.addressToEdit != null) {
          savedAddress = await repo.updateAddress(addressData);
        } else {
          savedAddress = await repo.createAddress(addressData);
        }
        ref.invalidate(addressesProvider);
      }

      if (mounted) {
        Navigator.pop(context, savedAddress);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectQuickTitle(String title) {
    setState(() {
      _selectedQuickTitle = title;
      _titleController.text = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.addressToEdit != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE95D22), // Hoppa Orange
              Color(0xFFFF8C00), // Orange-Yellow
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          children: [
            HoppaHeader(
              height: 70,
              child: Row(
                children: [
                  const BackButton(color: Colors.white),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 48.0),
                        child: Text(
                          isEditing ? "Adresi Düzenle" : "Yeni Adres Ekle",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: Column(
        children: [
          // --- HARİTA BÖLÜMÜ ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isLocationVerified ? 180 : (MediaQuery.of(context).size.height - 250),
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_latitude, _longitude),
                    initialZoom: 15.0,
                    interactionOptions: InteractionOptions(
                      flags: _isLocationVerified
                          ? InteractiveFlag.none
                          : InteractiveFlag.all,
                    ),
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture) {
                        _latitude = position.center.latitude;
                        _longitude = position.center.longitude;
                      }
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMoveStart) {
                        setState(() {
                          _isDragging = true;
                        });
                      } else if (event is MapEventMoveEnd) {
                        setState(() {
                          _isDragging = false;
                        });
                        if (event.source != MapEventSource.mapController) {
                          _resolveAddress(
                            event.camera.center.latitude,
                            event.camera.center.longitude,
                          );
                        }
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _isSatellite
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.kktc.market',
                    ),
                  ],
                ),
                // ANIMATED CENTER PIN & TARGET DOT
                Center(
                  child: MapPinWidget(
                    isDragging: _isDragging,
                    primaryColor: theme.primaryColor,
                  ),
                ),
                // SEARCH BAR & LAYER TOGGLE CARD
                if (!_isLocationVerified)
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
                                    hintText: 'Adres Ara...',
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
                                  color: theme.primaryColor,
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
                                      _latitude = lat;
                                      _longitude = lon;
                                      _searchResults = [];
                                      _searchController.text = item['display_name'] ?? '';
                                    });
                                    _resolveAddress(lat, lon);
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                if (!_isLocationVerified)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: "btn_location",
                      backgroundColor: Colors.white,
                      onPressed: _isLocationGetting
                          ? null
                          : _fetchAndSetLocation,
                      child: _isLocationGetting
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.my_location, color: theme.primaryColor),
                    ),
                  ),
              ],
            ),
          ),

          // --- ALT BÖLÜM: FORM VEYA DOĞRULAMA BUTONU ---
          Expanded(
            child: _isLocationVerified
                ? SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Adres Başlığı",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: _quickTitles.map((title) {
                                final isSelected = _selectedQuickTitle == title;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(title),
                                    selected: isSelected,
                                    selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                                    checkmarkColor: theme.primaryColor,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? theme.primaryColor
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    onSelected: (_) => _selectQuickTitle(title),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected
                                            ? theme.primaryColor
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    showCheckmark: false,
                                    avatar: isSelected
                                        ? Icon(
                                            Icons.check,
                                            size: 16,
                                            color: theme.primaryColor,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: "Örn: Evim, İş Yerim",
                                border: theme.inputDecorationTheme.border,
                                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                                focusedBorder: theme.inputDecorationTheme.focusedBorder,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? "Başlık giriniz" : null,
                              onChanged: (val) {
                                if (!_quickTitles.contains(val)) {
                                  setState(() => _selectedQuickTitle = '');
                                }
                              },
                            ),

                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Lokasyon Bilgileri",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isLocationVerified = false;
                                    });
                                  },
                                  icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                                  label: const Text(
                                    "Konumu Değiştir",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: _selectedCity,
                                        hint: const Text("Şehir"),
                                        items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedCity = val;
                                              _selectedDistrict = kKktcDistricts[val]!.first;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: _selectedDistrict,
                                        hint: const Text("Bölge"),
                                        items: _selectedCity == null
                                            ? []
                                            : (List<String>.from(kKktcDistricts[_selectedCity]!)..sort())
                                                .map((dist) => DropdownMenuItem(value: dist, child: Text(dist)))
                                                .toList(),
                                        onChanged: _selectedCity == null
                                            ? null
                                            : (val) => setState(() => _selectedDistrict = val),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _detailsController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "Sokak adı, bina no, daire no ve tarif...",
                                border: theme.inputDecorationTheme.border,
                                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                                focusedBorder: theme.inputDecorationTheme.focusedBorder,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.all(16),
                                suffixIcon: null,
                              ),
                              validator: (v) => v!.isEmpty ? "Adres detayı giriniz" : null,
                            ),

                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveAddress,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        isEditing ? "Değişiklikleri Kaydet" : "Adresi Kaydet",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "İşaretçi pinini tam adresinizin üzerine getirin.",
                            style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isLocationVerified = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: theme.primaryColor.withValues(alpha: 0.3),
                              ),
                              child: const Text(
                                "Konumu Doğrula",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
                    ],
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

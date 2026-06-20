import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hoppa/apps/consumer/repositories/address_repository.dart';
import 'package:hoppa/shared/models/address.dart';
import 'package:hoppa/shared/core/data/kktc_districts.dart';
import 'package:hoppa/apps/consumer/providers/consumer_location_controller.dart';

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

  String? _selectedCity;
  String? _selectedDistrict;

  bool _isLoading = false;
  bool _isLocationGetting = false;
  double _latitude = 35.1856; // Default: Nicosia
  double _longitude = 33.3823;

  final List<String> _cities = kKktcDistricts.keys.toList();
  final List<String> _quickTitles = ['Ev', 'İş', 'Diğer'];
  String _selectedQuickTitle = '';

  @override
  void initState() {
    super.initState();

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

  Future<void> _fetchAndSetLocation() async {
    setState(() => _isLocationGetting = true);

    try {
      final result = await ref.read(consumerLocationProvider.notifier).determineLocation();
      
      if (result != null) {
        setState(() {
          _latitude = result.latitude;
          _longitude = result.longitude;
          
          // Dropdown Mismatch Protection (Safe Assignment)
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

        // Apply Unnamed Road filtering
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

          debugPrint("📍 ADRES ÇÖZÜMLENDİ: $foundCity, $street");
        } else {
          // Dropdown Mismatch Protection
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen Şehir ve Bölge seçiniz"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final addressData = Address(
        id: widget.addressToEdit?.id ?? '', // Eğer düzenleme ise ID'yi koru
        title: _titleController.text,
        city: _selectedCity!,
        district: _selectedDistrict!,
        fullDetails: _detailsController.text,
        latitude: _latitude,
        longitude: _longitude,
      );

      final repo = ref.read(addressRepositoryProvider);
      Address savedAddress;
      if (widget.addressToEdit != null) {
        // GÜNCELLEME
        savedAddress = await repo.updateAddress(addressData);
      } else {
        // YENİ EKLEME
        savedAddress = await repo.createAddress(addressData);
      }

      ref.invalidate(addressesProvider);

      if (mounted) {
        Navigator.pop(context, savedAddress); // Güncellenen datayı geri dön
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
      appBar: AppBar(
        title: Text(
          isEditing ? "Adresi Düzenle" : "Yeni Adres Ekle",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HARİTA ---
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_latitude, _longitude),
                      initialZoom: 15.0,
                      onPositionChanged: (position, hasGesture) {
                        if (hasGesture) {
                          _latitude = position.center.latitude;
                          _longitude = position.center.longitude;
                        }
                      },
                      onMapEvent: (event) {
                        if (event is MapEventMoveEnd &&
                            event.source != MapEventSource.mapController) {
                          _resolveAddress(
                            event.camera.center.latitude,
                            event.camera.center.longitude,
                          );
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.kktc.market',
                      ),
                      // Marker Layer KALDIRILDI, yerine Stack içinde sabit ikon var
                    ],
                  ),
                  // ORTA NOKTA PİNİ
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: 40,
                      ), // Pinin ucu merkeze gelsin diye yukarı kaydırıyoruz
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
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

            // --- FORM ---
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
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

                      // Title Chips
                      Row(
                        children: _quickTitles.map((title) {
                          final isSelected = _selectedQuickTitle == title;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(title),
                              selected: isSelected,
                              selectedColor: theme.primaryColor.withOpacity(
                                0.2,
                              ),
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
                          enabledBorder:
                              theme.inputDecorationTheme.enabledBorder,
                          focusedBorder:
                              theme.inputDecorationTheme.focusedBorder,
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
                      const Text(
                        "Lokasyon Bilgileri",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedCity,
                                  hint: const Text("Şehir"),
                                  items: _cities
                                      .map(
                                        (city) => DropdownMenuItem(
                                          value: city,
                                          child: Text(city),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedCity = val;
                                        _selectedDistrict =
                                            kKktcDistricts[val]!.first;
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedDistrict,
                                  hint: const Text("Bölge"),
                                  items: _selectedCity == null
                                      ? []
                                      : kKktcDistricts[_selectedCity]!
                                          .map(
                                            (dist) => DropdownMenuItem(
                                              value: dist,
                                              child: Text(dist),
                                            ),
                                          )
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
                          enabledBorder:
                              theme.inputDecorationTheme.enabledBorder,
                          focusedBorder:
                              theme.inputDecorationTheme.focusedBorder,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                          suffixIcon: _isLocationGetting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.my_location),
                                  onPressed: _fetchAndSetLocation,
                                  tooltip: "Konumumu Bul",
                                  color: theme.primaryColor,
                                ),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? "Adres detayı giriniz" : null,
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
                            shadowColor: theme.primaryColor.withOpacity(0.4),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  isEditing
                                      ? "Değişiklikleri Kaydet"
                                      : "Adresi Kaydet",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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

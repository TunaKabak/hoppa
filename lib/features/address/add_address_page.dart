import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hoppa/core/services/address_service.dart';
import 'package:hoppa/models/address.dart';
import 'package:hoppa/core/data/kktc_districts.dart';

class AddAddressPage extends StatefulWidget {
  final Address? addressToEdit; // Düzenlenecek adres (Opsiyonel)

  const AddAddressPage({super.key, this.addressToEdit});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
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
  bool _locationFound = false;

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
      _locationFound = true;

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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationGetting = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Konum izni reddedildi");
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _mapController.move(LatLng(position.latitude, position.longitude), 15);
      // _resolveAddress zaten map hareket ettiği için tetiklenecek mi?
      // Hayır, programatik hareket InteractionEnd tetiklemez. Manuel çağıralım.
      await _resolveAddress(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Konum hatası: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLocationGetting = false);
    }
  }

  Future<void> _resolveAddress(double lat, double lng) async {
    setState(() {
      _latitude = lat;
      _longitude = lng;
      _locationFound = true;
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

        if (foundCity != null) {
          setState(() {
            _selectedCity = foundCity;
            if (kKktcDistricts[foundCity]!.contains(place.subLocality)) {
              _selectedDistrict = place.subLocality;
            } else {
              _selectedDistrict = kKktcDistricts[foundCity]!.first;
            }
          });

          String street = place.thoroughfare ?? '';
          String number = place.subThoroughfare ?? '';
          if (street.isNotEmpty) {
            _detailsController.text = "$street $number";
          }

          debugPrint("📍 ADRES ÇÖZÜMLENDİ: $foundCity, $street");
        }
      }
    } catch (e) {
      debugPrint("Adres çözümleme hatası: $e");
    }
  }

  void _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
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

      if (widget.addressToEdit != null) {
        // GÜNCELLEME
        await AddressService().updateAddress(addressData);
      } else {
        // YENİ EKLEME
        await AddressService().addAddress(addressData);
      }

      if (mounted) {
        Navigator.pop(context, addressData); // Güncellenen datayı geri dön
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
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
                          : _getCurrentLocation,
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
                                  items: kKktcDistricts[_selectedCity]!
                                      .map(
                                        (dist) => DropdownMenuItem(
                                          value: dist,
                                          child: Text(dist),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedDistrict = val!),
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/apps/merchant/merchant_main_layout.dart';
import 'package:hoppa/apps/merchant/repositories/merchant_shop_repository.dart';
import 'package:hoppa/apps/merchant/providers/merchant_api_providers.dart';
import 'package:hoppa/shared/common/location_picker_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hoppa/shared/core/services/media_service.dart';
import 'package:core_auth/core_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hoppa/apps/merchant/providers/merchant_location_controller.dart';
import 'package:hoppa/shared/core/data/kktc_districts.dart';

class MerchantSettingsPage extends ConsumerStatefulWidget {
  final String businessId;

  const MerchantSettingsPage({super.key, required this.businessId});

  @override
  ConsumerState<MerchantSettingsPage> createState() => _MerchantSettingsPageState();
}

class _MerchantSettingsPageState extends ConsumerState<MerchantSettingsPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  bool _isInitialized = false;
  MerchantShop? _shop;

  // Controllers - Profile
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _taxController;
  late TextEditingController _identityController;

  // Controllers - Operation
  late TextEditingController _minBasketController;
  late TextEditingController _deliveryTimeController;

  // Delivery Radius
  double _deliveryRadius = 5.0;

  // Working Hours (Weekly)
  Map<String, dynamic> _workingHours = {};

  double? _latitude;
  double? _longitude;
  String? _imageUrl;
  String? _headerImageUrl;
  bool _isUploadingImage = false;
  bool _isUploadingHeader = false;
  bool _isFetchingLocation = false;
  
  late final MapController _mapController;
  String? _selectedCity;
  late TextEditingController _districtController;

  final List<String> _kktcCities = [
    'Lefkoşa',
    'Girne',
    'Gazimağusa',
    'İskele',
    'Güzelyurt',
    'Lefke',
  ];

  void _parseAddress(String address) {
    String city = '';
    String district = '';
    String openAddress = address;

    // Split by comma
    final parts = address.split(',');
    if (parts.length >= 3) {
      // Format: Open Address, District, City
      final cityCandidate = parts.last.trim();
      final districtCandidate = parts[parts.length - 2].trim();
      
      if (_kktcCities.any((c) => c.toLowerCase() == cityCandidate.toLowerCase())) {
        city = _kktcCities.firstWhere((c) => c.toLowerCase() == cityCandidate.toLowerCase());
        district = districtCandidate;
        openAddress = parts.sublist(0, parts.length - 2).join(',').trim();
      }
    } else if (parts.length == 2) {
      // Format: Open Address, City or Open Address, District
      final cityCandidate = parts.last.trim();
      if (_kktcCities.any((c) => c.toLowerCase() == cityCandidate.toLowerCase())) {
        city = _kktcCities.firstWhere((c) => c.toLowerCase() == cityCandidate.toLowerCase());
        openAddress = parts.first.trim();
      } else {
        district = cityCandidate;
        openAddress = parts.first.trim();
      }
    } else {
      // Attempt to search for city name in single string
      for (final c in _kktcCities) {
        if (address.toLowerCase().contains(c.toLowerCase())) {
          city = c;
          // Remove city from address
          openAddress = address.replaceAll(RegExp(c, caseSensitive: false), '').trim();
          // Clean up trailing/leading commas or spaces
          openAddress = openAddress.replaceAll(RegExp(r'^,\s*|,\s*$'), '').trim();
          break;
        }
      }
    }

    setState(() {
      _selectedCity = city.isNotEmpty ? city : null;
      _districtController.text = district;
      _addressController.text = openAddress;
    });
  }

  String? _getMatchedDistrict(String? city, String districtText) {
    if (city == null || districtText.isEmpty) return null;
    final list = kKktcDistricts[city] ?? [];
    if (list.contains(districtText)) return districtText;
    final lowerText = districtText.trim().toLowerCase();
    for (final d in list) {
      if (d.toLowerCase() == lowerText) return d;
    }
    for (final d in list) {
      if (lowerText.contains(d.toLowerCase()) || d.toLowerCase().contains(lowerText)) {
        return d;
      }
    }
    return null;
  }

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, String> _dayLabels = {
    'monday': 'Pazartesi',
    'tuesday': 'Salı',
    'wednesday': 'Çarşamba',
    'thursday': 'Perşembe',
    'friday': 'Cuma',
    'saturday': 'Cumartesi',
    'sunday': 'Pazar',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _minBasketController = TextEditingController();
    _deliveryTimeController = TextEditingController();
    _taxController = TextEditingController();
    _identityController = TextEditingController();
    _districtController = TextEditingController();
    _mapController = MapController();

    // Invalidate shopControllerProvider to clear any previous failed toggle error states
    // and load fresh shop data safely. Also initialize the MediaService global client.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(shopControllerProvider);
      MediaService.globalApiClient = ref.read(apiClientProvider);
    });
  }

  void _initControllers(MerchantShop shop) {
    if (_isInitialized) return;
    
    _shop = shop;
    _nameController.text = shop.name;
    _phoneController.text = shop.businessPhone ?? '';
    _addressController.text = '';
    _parseAddress(shop.address ?? '');
    _minBasketController.text = shop.minOrderAmount?.toString() ?? '0.0';
    _deliveryRadius = shop.deliveryRadiusKm ?? 5.0;
    _taxController.text = shop.taxNumber ?? '';
    _identityController.text = shop.identityNumber ?? '';
    _latitude = shop.latitude;
    _longitude = shop.longitude;
    _imageUrl = shop.imageUrl;
    _headerImageUrl = shop.headerImageUrl;

    if (shop.workingHours == null || shop.workingHours!.isEmpty) {
      for (var day in _days) {
        _workingHours[day] = {
          'isOpen': true,
          'open': '08:00',
          'close': '22:00',
        };
      }
    } else {
      _workingHours = Map<String, dynamic>.from(shop.workingHours!);
      for (var day in _days) {
        if (!_workingHours.containsKey(day)) {
          _workingHours[day] = {
            'isOpen': true,
            'open': '08:00',
            'close': '22:00',
          };
        }
      }
    }
    _isInitialized = true;

    // Trigger auto GPS location fetch if address is empty
    if (shop.address == null || shop.address!.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchAndSetLocation(autoTriggered: true);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _minBasketController.dispose();
    _deliveryTimeController.dispose();
    _taxController.dispose();
    _identityController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(String day, String key) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _workingHours[day][key] = formattedTime;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_shop == null) return;

    final combinedAddress = [
      _addressController.text.trim(),
      _districtController.text.trim(),
      _selectedCity,
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');

    try {
      await ref.read(shopControllerProvider.notifier).updateShop({
        'name': _nameController.text,
        'address': combinedAddress,
        'minOrderAmount': double.tryParse(_minBasketController.text) ?? 0.0,
        'deliveryRadiusKm': _deliveryRadius,
        'workingHours': _workingHours,
        'isActive': _shop?.isActive ?? true,
        'businessPhone': _phoneController.text,
        'taxNumber': _taxController.text,
        'identityNumber': _identityController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'imageUrl': _imageUrl,
        'headerImageUrl': _headerImageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ayarlar kaydedildi!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopControllerProvider);

    // If we have cached/loaded data, immediately render the settings forms even if there was a transient mutation error.
    if (shopAsync.hasValue && shopAsync.value != null) {
      final shop = shopAsync.value!;

      if (!_isInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _initControllers(shop);
          });
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "İşletme Ayarları",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => merchantDrawerKey.currentState?.openDrawer(),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: "Profil"),
              Tab(text: "Operasyon"),
              Tab(text: "Teslimat"),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(),
              _buildOperationTab(),
              _buildDeliveryTab(),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Değişiklikleri Kaydet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Handle true loading and error states (where no cached data exists)
    if (shopAsync.hasError) {
      final error = shopAsync.error;
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  "Ayarlar Yüklenemedi",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(shopControllerProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Yeniden Dene"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Temel Bilgiler",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "İşletme Adı",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.store),
            ),
            validator: (value) => value!.isEmpty ? "Zorunlu alan" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: "Telefon",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) => value!.isEmpty ? "Zorunlu alan" : null,
          ),
          const SizedBox(height: 24),
          const Text(
            "Resmi İşletme Bilgileri",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _taxController,
            decoration: const InputDecoration(
              labelText: "Vergi Numarası",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.assignment),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _identityController,
            decoration: const InputDecoration(
              labelText: "Şahıs / Kimlik Numarası",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Görseller",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      key: ValueKey(_imageUrl ?? ''),
                      radius: 40,
                      backgroundImage: (_imageUrl ?? '').isNotEmpty
                          ? NetworkImage(_imageUrl!)
                          : null,
                      child: _isUploadingImage
                          ? const CircularProgressIndicator()
                          : (_imageUrl ?? '').isEmpty
                              ? const Icon(Icons.camera_alt)
                              : null,
                    ),
                    TextButton(
                      onPressed: _pickAndUploadLogo,
                      child: const Text("Logo Yükle"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      color: Colors.grey.shade200,
                      child: _isUploadingHeader
                          ? const Center(child: CircularProgressIndicator())
                          : (_headerImageUrl ?? '').isNotEmpty
                              ? Image.network(
                                  _headerImageUrl!,
                                  key: ValueKey(_headerImageUrl),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : const Center(child: Icon(Icons.image)),
                    ),
                    TextButton(
                      onPressed: _pickAndUploadHeader,
                      child: const Text("Kapak Yükle"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sipariş Ayarları",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minBasketController,
                  decoration: const InputDecoration(
                    labelText: "Min. Sepet Tutarı (₺)",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _deliveryTimeController,
                  decoration: const InputDecoration(
                    labelText: "Ort. Teslimat Süresi",
                    border: OutlineInputBorder(),
                    hintText: "30-45 dk",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Çalışma Saatleri",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _copyMondayToAll,
                icon: const Icon(Icons.copy_all),
                label: const Text("Pazartesi'yi Tümüne Uygula"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._days.map((day) {
            final schedule = _workingHours[day];
            final isOpen = schedule['isOpen'] ?? true;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        _dayLabels[day]!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Switch(
                      value: isOpen,
                      onChanged: (val) {
                        setState(() {
                          _workingHours[day]['isOpen'] = val;
                        });
                      },
                    ),
                    if (isOpen) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _selectTime(day, 'open'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(schedule['open']),
                        ),
                      ),
                      const Text(" - "),
                      InkWell(
                        onTap: () => _selectTime(day, 'close'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(schedule['close']),
                        ),
                      ),
                    ] else
                      const Text(
                        "KAPALI",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadLogo() async {
    final MediaService mediaService = MediaService(ref.read(apiClientProvider));
    final file = await mediaService.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final String? url = await mediaService.uploadImage(
        file: file,
        path: '', // Unused in direct uploads
      );

      if (url != null) {
        setState(() {
          _imageUrl = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Görsel başarıyla yüklendi!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Yükleme hatası: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadHeader() async {
    final MediaService mediaService = MediaService(ref.read(apiClientProvider));
    final file = await mediaService.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _isUploadingHeader = true;
    });

    try {
      final String? url = await mediaService.uploadImage(
        file: file,
        path: '', // Unused in direct uploads
      );

      if (url != null) {
        setState(() {
          _headerImageUrl = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Görsel başarıyla yüklendi!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Yükleme hatası: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingHeader = false;
        });
      }
    }
  }

  Future<void> _pickLocation() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          initialLatitude: _latitude ?? 41.0082,
          initialLongitude: _longitude ?? 28.9784,
        ),
      ),
    );

    if (result != null) {
      if (!mounted) return;

      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });

      // Reverse Geocoding with Timeout
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        ).timeout(const Duration(seconds: 5));

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          
          String streetAddress = '';
          String thoroughfareField = place.thoroughfare ?? '';
          String streetField = place.street ?? '';

          if (streetField.toLowerCase().contains("unnamed road")) streetField = "";
          if (thoroughfareField.toLowerCase().contains("unnamed road")) thoroughfareField = "";

          if (streetField.isNotEmpty) {
            streetAddress = streetField;
          } else if (thoroughfareField.isNotEmpty) {
            streetAddress = thoroughfareField;
          }

          String resolvedCity = '';
          for (final field in [place.locality, place.subAdministrativeArea, place.administrativeArea]) {
            if (field != null && field.isNotEmpty) {
              for (final kc in _kktcCities) {
                if (field.toLowerCase().contains(kc.toLowerCase()) || kc.toLowerCase().contains(field.toLowerCase())) {
                  resolvedCity = kc;
                  break;
                }
              }
            }
            if (resolvedCity.isNotEmpty) break;
          }

          String resolvedDistrict = '';
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            resolvedDistrict = place.subLocality!;
          } else if (place.subAdministrativeArea != null && 
                     place.subAdministrativeArea!.isNotEmpty && 
                     resolvedCity.isNotEmpty &&
                     !place.subAdministrativeArea!.toLowerCase().contains(resolvedCity.toLowerCase())) {
            resolvedDistrict = place.subAdministrativeArea!;
          }

          setState(() {
            _addressController.text = streetAddress;
            _selectedCity = resolvedCity.isNotEmpty ? resolvedCity : null;
            _districtController.text = resolvedDistrict;
          });

          // Move map camera
          _mapController.move(LatLng(result.latitude, result.longitude), 15.0);
        }
      } catch (e) {
        debugPrint("Reverse geocoding failed or timed out: $e");
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text("Konum güncellendi. Kaydetmek için 'Değişiklikleri Kaydet' butonuna basın."),
          ),
        );
      }
    }
  }

  Future<void> _fetchAndSetLocation({bool autoTriggered = false}) async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      final result = await ref.read(merchantLocationProvider.notifier).determineLocation();
      setState(() {
        _addressController.text = result.streetAddress;
        _selectedCity = result.city.isNotEmpty && _kktcCities.contains(result.city) ? result.city : null;
        _districtController.text = result.district;
        _latitude = result.latitude;
        _longitude = result.longitude;
      });

      // Move map camera
      _mapController.move(LatLng(result.latitude, result.longitude), 15.0);

      if (!autoTriggered && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Konum başarıyla alındı.")),
        );
      }
    } catch (e) {
      debugPrint("Konum alma hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              autoTriggered
                  ? "Otomatik konum alınamadı, lütfen adresi manuel giriniz veya seçiniz."
                  : "Konum alınamadı, lütfen adresi manuel giriniz veya seçiniz."
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  void _copyMondayToAll() {
    final mondaySchedule = _workingHours['monday'];
    if (mondaySchedule == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tüm Günlere Uygula"),
        content: const Text(
          "Pazartesi gününe ait açılış/kapanış saatleri ve açık/kapalı durumu diğer tüm günlere kopyalanacak. Onaylıyor musunuz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                for (var day in _days) {
                  if (day == 'monday') continue;
                  _workingHours[day] = Map<String, dynamic>.from(
                    mondaySchedule,
                  );
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Saatler tüm haftaya uygulandı.")),
              );
            },
            child: const Text("Uygula"),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dükkan Adresi",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('city_$_selectedCity'),
            initialValue: _selectedCity,
            decoration: const InputDecoration(
              labelText: "Şehir (İl)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
            items: _kktcCities.map((city) {
              return DropdownMenuItem<String>(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
                final districtsList = kKktcDistricts[value] ?? [];
                if (districtsList.isNotEmpty) {
                  _districtController.text = districtsList.first;
                } else {
                  _districtController.text = '';
                }
              });
            },
            validator: (value) => value == null ? "Şehir seçimi zorunludur" : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('district_${_selectedCity}_${_districtController.text}'),
            initialValue: _getMatchedDistrict(_selectedCity, _districtController.text),
            decoration: const InputDecoration(
              labelText: "Semt (İlçe/Bölge)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.maps_home_work),
            ),
            hint: const Text("İlçe seçiniz"),
            disabledHint: const Text("Önce Şehir Seçiniz"),
            items: _selectedCity == null
                ? null
                : (kKktcDistricts[_selectedCity] ?? []).map((district) {
                    return DropdownMenuItem<String>(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
            onChanged: _selectedCity == null
                ? null
                : (value) {
                    setState(() {
                      if (value != null) {
                        _districtController.text = value;
                      }
                    });
                  },
            validator: (value) {
              if (_selectedCity != null && (value == null || value.isEmpty)) {
                return "İlçe seçimi zorunludur";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: "Açık Adres (Sokak, Apartman, No)",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on),
              suffixIcon: _isFetchingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () => _fetchAndSetLocation(),
                      tooltip: "Konumumu Getir",
                    ),
            ),
            maxLines: 3,
            validator: (value) => value!.isEmpty ? "Zorunlu alan" : null,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickLocation,
            icon: const Icon(Icons.map),
            label: const Text("Konumu Haritada Düzenle"),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            "Teslimat Bölgesi",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Hizmet verdiğiniz makismum mesafeyi belirleyin.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Yarıçap (km):", style: TextStyle(fontSize: 16)),
              Text(
                "${_deliveryRadius.toStringAsFixed(1)} km",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          Slider(
            value: _deliveryRadius,
            min: 1.0,
            max: 20.0,
            divisions: 38, // 0.5 km steps
            label: "${_deliveryRadius.toStringAsFixed(1)} km",
            onChanged: (val) {
              setState(() {
                _deliveryRadius = val;
              });
            },
          ),
          const SizedBox(height: 24),
          // Mock Map Preview
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    (_latitude ?? 0) != 0 ? _latitude! : 41.0082,
                    (_longitude ?? 0) != 0 ? _longitude! : 28.9784,
                  ),
                  initialZoom: 13.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.hoppa',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                          (_latitude ?? 0) != 0
                              ? _latitude!
                              : 41.0082,
                          (_longitude ?? 0) != 0
                              ? _longitude!
                              : 28.9784,
                        ),
                        radius: _deliveryRadius * 1000, // Convert km to meters
                        useRadiusInMeter: true,
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          (_latitude ?? 0) != 0
                              ? _latitude!
                              : 41.0082,
                          (_longitude ?? 0) != 0
                              ? _longitude!
                              : 28.9784,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
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

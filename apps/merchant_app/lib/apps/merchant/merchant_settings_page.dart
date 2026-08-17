import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merchant_app/apps/merchant/merchant_main_layout.dart';
import 'package:merchant_app/apps/merchant/repositories/merchant_shop_repository.dart';
import 'package:merchant_app/apps/merchant/providers/merchant_api_providers.dart';
import 'package:core_shared/shared/common/location_picker_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:core_shared/shared/core/services/media_service.dart';
import 'package:core_auth/core_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:merchant_app/apps/merchant/providers/merchant_location_controller.dart';
import 'package:core_shared/shared/core/data/kktc_districts.dart';

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

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _taxController;
  late TextEditingController _identityController;

  // Controllers - Operation & Delivery
  late TextEditingController _minBasketController;
  late TextEditingController _baseDeliveryFeeController;
  late TextEditingController _deliveryFeePerKmController;
  late TextEditingController _freeDeliveryThresholdController;
  
  String _selectedDeliveryTime = '30-45 dk';
  String _deliveryPricingType = 'FIXED';

  bool _supportsOnline = true;
  bool _supportsCash = true;
  bool _supportsCard = true;

  bool _supportsPlatformDelivery = true;
  bool _supportsSelfDelivery = false;
  bool _supportsPickup = true;
  
  final List<String> _deliveryTimeOptions = ['15-30 dk', '30-45 dk', '45-60 dk', '60+ dk'];
  // Delivery Radius & Polygon
  double _deliveryRadius = 5.0;
  bool _isPolygonMode = false;
  List<LatLng> _deliveryPolygon = [];

  // Working Hours (Weekly)
  Map<String, dynamic> _workingHours = {};

  double? _latitude;
  double? _longitude;
  String? _imageUrl;
  String? _headerImageUrl;
  File? _localLogoFile;
  File? _localHeaderFile;
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

  double _calculateZoomForRadius(double radiusKm) {
    if (radiusKm <= 0) return 13.0;
    final zoom = 14.5 - (math.log(radiusKm) / math.log(2));
    return zoom.clamp(10.0, 16.0);
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
    _baseDeliveryFeeController = TextEditingController();
    _deliveryFeePerKmController = TextEditingController();
    _freeDeliveryThresholdController = TextEditingController();
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
    if (_isInitialized && _shop?.id == shop.id) return;
    
    _shop = shop;
    _nameController.text = shop.name;
    _phoneController.text = shop.businessPhone ?? '';
    _addressController.text = '';
    _parseAddress(shop.address ?? '');
    _minBasketController.text = shop.minOrderAmount?.toString() ?? '150.0';
    _baseDeliveryFeeController.text = shop.baseDeliveryFee?.toString() ?? '30.0';
    _deliveryFeePerKmController.text = shop.deliveryFeePerKm?.toString() ?? '5.0';
    _freeDeliveryThresholdController.text = shop.freeDeliveryThreshold?.toString() ?? '';

    final allowed = shop.allowedPaymentMethods ?? ['ONLINE_PAYMENT', 'CASH_ON_DELIVERY', 'CARD_ON_DELIVERY'];
    _supportsOnline = allowed.contains('ONLINE_PAYMENT');
    _supportsCash = allowed.contains('CASH_ON_DELIVERY');
    _supportsCard = allowed.contains('CARD_ON_DELIVERY');

    final allowedModels = shop.allowedFulfillmentModels ?? ['PLATFORM_DELIVERY', 'PICKUP'];
    _supportsPlatformDelivery = allowedModels.contains('PLATFORM_DELIVERY');
    _supportsSelfDelivery = allowedModels.contains('SELF_DELIVERY');
    _supportsPickup = allowedModels.contains('PICKUP');
    
    if (_deliveryTimeOptions.contains(shop.deliveryTime)) {
      _selectedDeliveryTime = shop.deliveryTime!;
    }
    _deliveryPricingType = shop.deliveryPricingType ?? 'FIXED';
    
    _deliveryRadius = shop.deliveryRadiusKm ?? 5.0;
    if (shop.deliveryPolygon != null && shop.deliveryPolygon!.isNotEmpty) {
      _isPolygonMode = true;
      try {
        _deliveryPolygon = shop.deliveryPolygon!.map((point) {
          return LatLng(
            double.parse(point['lat'].toString()),
            double.parse(point['lng'].toString()),
          );
        }).toList();
      } catch (e) {
        _deliveryPolygon = [];
      }
    } else {
      _isPolygonMode = false;
      _deliveryPolygon = [];
    }
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
    _baseDeliveryFeeController.dispose();
    _deliveryFeePerKmController.dispose();
    _freeDeliveryThresholdController.dispose();
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

    if (!_supportsOnline && !_supportsCash && !_supportsCard) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("En az bir ödeme yöntemi kabul edilmelidir."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_supportsPlatformDelivery && !_supportsSelfDelivery && !_supportsPickup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("En az bir teslimat/hizmet yöntemi kabul edilmelidir."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
        'deliveryRadiusKm': _isPolygonMode ? null : _deliveryRadius,
        'deliveryPolygon': _isPolygonMode ? _deliveryPolygon.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList() : null,
        'workingHours': _workingHours,
        'isActive': _shop?.isActive ?? true,
        'businessPhone': _phoneController.text,
        'taxNumber': _taxController.text,
        'identityNumber': _identityController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'imageUrl': _imageUrl,
        'headerImageUrl': _headerImageUrl,
        'deliveryTime': _selectedDeliveryTime,
        'deliveryPricingType': _deliveryPricingType,
        'baseDeliveryFee': double.tryParse(_baseDeliveryFeeController.text) ?? 30.0,
        'deliveryFeePerKm': double.tryParse(_deliveryFeePerKmController.text) ?? 5.0,
        'freeDeliveryThreshold': double.tryParse(_freeDeliveryThresholdController.text),
        'allowedPaymentMethods': [
          if (_supportsOnline) 'ONLINE_PAYMENT',
          if (_supportsCash) 'CASH_ON_DELIVERY',
          if (_supportsCard) 'CARD_ON_DELIVERY',
        ],
        'allowedFulfillmentModels': [
          if (_supportsPlatformDelivery) 'PLATFORM_DELIVERY',
          if (_supportsSelfDelivery) 'SELF_DELIVERY',
          if (_supportsPickup) 'PICKUP',
        ],
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

      if (_isInitialized && _shop?.id != shop.id) {
        _isInitialized = false;
      }

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
                    _isUploadingImage
                        ? const CircleAvatar(
                            radius: 40,
                            child: CircularProgressIndicator(),
                          )
                        : _buildLogoWidget(_imageUrl, _nameController.text),
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
                          : _buildHeaderWidget(_headerImageUrl, _nameController.text, height: 80),
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
                child: DropdownButtonFormField<String>(
                  value: _selectedDeliveryTime,
                  decoration: const InputDecoration(
                    labelText: "Ort. Teslimat Süresi",
                    border: OutlineInputBorder(),
                  ),
                  items: _deliveryTimeOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedDeliveryTime = newValue;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _deliveryPricingType,
                  decoration: const InputDecoration(
                    labelText: "Ücretlendirme Tipi",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'FIXED', child: Text('Sabit Ücret')),
                    DropdownMenuItem(value: 'DISTANCE_BASED', child: Text('Mesafeye Göre')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _deliveryPricingType = newValue;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _baseDeliveryFeeController,
                  decoration: const InputDecoration(
                    labelText: "Temel Teslimat Ücreti (₺)",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          if (_deliveryPricingType == 'DISTANCE_BASED') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _deliveryFeePerKmController,
              decoration: const InputDecoration(
                labelText: "Km Başına Ekstra Ücret (₺)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _freeDeliveryThresholdController,
            decoration: const InputDecoration(
              labelText: "Ücretsiz Teslimat Limiti (₺) - İsteğe Bağlı",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text(
            "Kabul Edilen Ödeme Yöntemleri",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text("Online Ödeme (Kredi/Banka Kartı)"),
            subtitle: const Text("Müşteriler sipariş verirken uygulama üzerinden online ödeyebilir."),
            value: _supportsOnline,
            onChanged: (val) {
              setState(() {
                _supportsOnline = val;
              });
            },
          ),
          SwitchListTile(
            title: const Text("Kapıda Nakit"),
            subtitle: const Text("Müşteriler siparişi teslim alırken nakit ödeyebilir."),
            value: _supportsCash,
            onChanged: (val) {
              setState(() {
                _supportsCash = val;
              });
            },
          ),
          SwitchListTile(
            title: const Text("Kapıda Kredi Kartı"),
            subtitle: const Text("Müşteriler siparişi teslim alırken POS cihazı ile ödeyebilir."),
            value: _supportsCard,
            onChanged: (val) {
              setState(() {
                _supportsCard = val;
              });
            },
          ),
          const SizedBox(height: 24),
          const Text(
            "Teslimat ve Hizmet Seçenekleri",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text("Hoppa Kuryesi (Platform Teslimatı)"),
            subtitle: const Text("Siparişleri bağımsız Hoppa kuryeleri taşır. Kuryesi olmayan işletmeler için idealdir."),
            value: _supportsPlatformDelivery,
            onChanged: (val) {
              setState(() {
                _supportsPlatformDelivery = val;
              });
            },
          ),
          SwitchListTile(
            title: const Text("İşletme Kuryesi (Esnaf Teslimatı)"),
            subtitle: const Text("Siparişleri kendi moto-kurye ekibiniz veya kuryeleriniz taşır."),
            value: _supportsSelfDelivery,
            onChanged: (val) {
              setState(() {
                _supportsSelfDelivery = val;
              });
            },
          ),
          SwitchListTile(
            title: const Text("Gel-Al (Müşteri Alımı)"),
            subtitle: const Text("Müşteriler siparişi uygulama üzerinden verip dükkandan kendileri teslim alır."),
            value: _supportsPickup,
            onChanged: (val) {
              setState(() {
                _supportsPickup = val;
              });
            },
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
      _localLogoFile = file;
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
      _localHeaderFile = file;
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

          final Map<String, String> cityMapping = {
            'nicosia': 'Lefkoşa',
            'lefkosia': 'Lefkoşa',
            'kyrenia': 'Girne',
            'keryneia': 'Girne',
            'famagusta': 'Gazimağusa',
            'gazimagusa': 'Gazimağusa',
            'magusa': 'Gazimağusa',
            'ammochostos': 'Gazimağusa',
            'iskele': 'İskele',
            'trikomo': 'İskele',
            'güzelyurt': 'Güzelyurt',
            'guzelyurt': 'Güzelyurt',
            'morphou': 'Güzelyurt',
            'lefke': 'Lefke',
            'lefka': 'Lefke',
          };

          String resolvedCity = '';
          for (final field in [place.locality, place.subAdministrativeArea, place.administrativeArea]) {
            if (field != null && field.isNotEmpty) {
              final valLower = field.toLowerCase();
              for (final entry in cityMapping.entries) {
                if (valLower.contains(entry.key) || entry.key.contains(valLower)) {
                  resolvedCity = entry.value;
                  break;
                }
              }
              if (resolvedCity.isEmpty) {
                for (final kc in _kktcCities) {
                  if (valLower.contains(kc.toLowerCase()) || kc.toLowerCase().contains(valLower)) {
                    resolvedCity = kc;
                    break;
                  }
                }
              }
            }
            if (resolvedCity.isNotEmpty) break;
          }

          String resolvedDistrict = '';
          if (resolvedCity.isNotEmpty) {
            final districts = kKktcDistricts[resolvedCity] ?? [];
            for (final field in [place.subLocality, place.thoroughfare, place.street, place.name]) {
              if (field != null && field.isNotEmpty) {
                final fLower = field.toLowerCase();
                for (final d in districts) {
                  if (fLower.contains(d.toLowerCase()) || d.toLowerCase().contains(fLower)) {
                    resolvedDistrict = d;
                    break;
                  }
                }
              }
              if (resolvedDistrict.isNotEmpty) break;
            }
          }

          if (resolvedDistrict.isEmpty) {
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              resolvedDistrict = place.subLocality!;
            } else if (place.subAdministrativeArea != null && 
                       place.subAdministrativeArea!.isNotEmpty && 
                       resolvedCity.isNotEmpty &&
                       !place.subAdministrativeArea!.toLowerCase().contains(resolvedCity.toLowerCase())) {
              resolvedDistrict = place.subAdministrativeArea!;
            }
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
              const Text(
                "Teslimat Bölgesi Modu",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ToggleButtons(
                isSelected: [!_isPolygonMode, _isPolygonMode],
                onPressed: (index) {
                  setState(() {
                    _isPolygonMode = index == 1;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 36, minWidth: 100),
                children: const [
                  Text("Yarıçap"),
                  Text("Özel Bölge"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!_isPolygonMode) ...[
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
                _mapController.move(
                  LatLng(_latitude ?? 35.1856, _longitude ?? 33.3823),
                  _calculateZoomForRadius(val),
                );
              },
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Poligon Sınırları:", style: TextStyle(fontSize: 16)),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _deliveryPolygon.clear();
                    });
                  },
                  icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                  label: const Text("Temizle", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            const Text(
              "Harita üzerine tıklayarak bölgenizin sınır noktalarını (köşelerini) belirleyin. En az 3 nokta gereklidir.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          // Map Preview
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
                  onTap: _isPolygonMode
                      ? (tapPosition, point) {
                          setState(() {
                            _deliveryPolygon.add(point);
                          });
                        }
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.hoppa',
                  ),
                  if (!_isPolygonMode)
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
                    )
                  else ...[
                    PolygonLayer(
                      polygons: [
                        if (_deliveryPolygon.length >= 3)
                          Polygon(
                            points: _deliveryPolygon,
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderColor: Colors.blue,
                            borderStrokeWidth: 2,
                          ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        if (_deliveryPolygon.isNotEmpty)
                          Polyline(
                            points: [
                              ..._deliveryPolygon,
                              if (_deliveryPolygon.length >= 3) _deliveryPolygon.first,
                            ],
                            color: Colors.blue,
                            strokeWidth: 2,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: _deliveryPolygon.map((p) => Marker(
                        point: p,
                        width: 16,
                        height: 16,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _deliveryPolygon.remove(p);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blue, width: 3),
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
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

  Widget _buildLogoWidget(String? url, String shopName, {double radius = 40}) {
    if (_localLogoFile != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(_localLogoFile!),
      );
    }

    final hasImage = url != null && url.trim().isNotEmpty && url.startsWith('http');
    if (hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url),
        key: ValueKey(url),
      );
    }

    // Modern Gradient Initials Fallback
    final initial = shopName.isNotEmpty ? shopName[0].toUpperCase() : 'H';
    
    // Choose a stable gradient based on the shop's name hash
    final hash = shopName.hashCode;
    final List<Color> colors = hash % 3 == 0
        ? [const Color(0xFFE95D22), const Color(0xFFFF8C00)] // Orange gradient
        : hash % 3 == 1
            ? [const Color(0xFF00A651), const Color(0xFF007A3E)] // Green gradient
            : [const Color(0xFF2979FF), const Color(0xFF1565C0)]; // Blue gradient

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: radius * 0.9,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWidget(String? url, String shopName, {double height = 120}) {
    if (_localHeaderFile != null) {
      return Image.file(
        _localHeaderFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
      );
    }

    final hasImage = url != null && url.trim().isNotEmpty && url.startsWith('http');
    if (hasImage) {
      return Image.network(
        url,
        key: ValueKey(url),
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildAbstractGradientHeader(shopName, height),
      );
    }

    return _buildAbstractGradientHeader(shopName, height);
  }

  Widget _buildAbstractGradientHeader(String shopName, double height) {
    final hash = shopName.hashCode;
    final List<Color> colors = hash % 3 == 0
        ? [const Color(0xFFFFF3EE), const Color(0xFFFFE0D3)] // Soft Warm gradient
        : hash % 3 == 1
            ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)] // Soft Green gradient
            : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)]; // Soft Blue gradient

    final primaryColor = hash % 3 == 0
        ? const Color(0xFFE95D22)
        : hash % 3 == 1
            ? const Color(0xFF00A651)
            : const Color(0xFF2979FF);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Subtle decorative shapes
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.storefront_rounded,
                size: height * 1.2,
                color: primaryColor,
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 20,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                Icons.bubble_chart_rounded,
                size: height * 0.5,
                color: primaryColor,
              ),
            ),
          ),
          Center(
            child: Opacity(
              opacity: 0.35,
              child: Text(
                shopName,
                style: GoogleFonts.poppins(
                  fontSize: height * 0.18,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


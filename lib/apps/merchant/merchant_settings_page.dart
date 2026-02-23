import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hoppa/shared/core/services/business_service.dart';
import 'package:hoppa/apps/merchant/merchant_main_layout.dart';
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/shared/core/services/media_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hoppa/shared/common/location_picker_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class MerchantSettingsPage extends StatefulWidget {
  final String businessId;

  const MerchantSettingsPage({super.key, required this.businessId});

  @override
  State<MerchantSettingsPage> createState() => _MerchantSettingsPageState();
}

class _MerchantSettingsPageState extends State<MerchantSettingsPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final BusinessService _businessService = BusinessService();
  final MediaService _mediaService = MediaService();
  late TabController _tabController;

  bool _isLoading = true;
  Business? _business;

  // Controllers - Profile
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  // Controllers - Operation
  late TextEditingController _minBasketController;
  late TextEditingController _deliveryTimeController;

  // Delivery Radius
  double _deliveryRadius = 5.0;

  // Working Hours (Weekly)
  Map<String, dynamic> _workingHours = {};

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
    _fetchBusinessData();
  }

  Future<void> _fetchBusinessData() async {
    try {
      final business = await _businessService.getBusinessById(
        widget.businessId,
      );
      if (business != null) {
        setState(() {
          _business = business;
          _nameController.text = business.name;
          _phoneController.text = business.phone;
          _addressController.text = business.address;
          _minBasketController.text = business.minBasketAmount.toString();
          _deliveryTimeController.text = business.averageDeliveryTime;
          _deliveryRadius = business.deliveryRadius;

          // Initialize working hours if empty
          if (business.workingHours.isEmpty) {
            for (var day in _days) {
              _workingHours[day] = {
                'isOpen': true,
                'open': '08:00',
                'close': '22:00',
              };
            }
          } else {
            _workingHours = Map.from(business.workingHours);
            // Ensure all days exist
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
        });
      }
    } catch (e) {
      debugPrint("Settings Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _minBasketController.dispose();
    _deliveryTimeController.dispose();
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
    if (_business == null) return;

    setState(() => _isLoading = true);

    try {
      await _businessService.updateBusiness(widget.businessId, {
        // Profile
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        // Operation
        'minBasketAmount': double.tryParse(_minBasketController.text) ?? 0.0,
        'averageDeliveryTime': _deliveryTimeController.text,
        // Delivery
        'deliveryRadius': _deliveryRadius,
        'workingHours': _workingHours,
        // Maintain others
        'isOpen': _business!.isOpen,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_business == null) {
      return const Center(child: Text("İşletme bilgisi bulunamadı."));
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
      bottomNavigationBar: Padding(
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: "Açık Adres",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
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
                      key: ValueKey(_business!.logoUrl), // Force rebuild
                      radius: 40,
                      backgroundImage: _business!.logoUrl.isNotEmpty
                          ? NetworkImage(_business!.logoUrl)
                          : null,
                      child: _business!.logoUrl.isEmpty
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
                      child: _business!.headerImageUrl.isNotEmpty
                          ? Image.network(
                              _business!.headerImageUrl,
                              key: ValueKey(
                                _business!.headerImageUrl,
                              ), // Force rebuild
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
    if (widget.businessId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("İşletme ID bulunamadı!")));
      return;
    }

    final file = await _mediaService.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isLoading = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = await _mediaService.uploadImage(
        file: file,
        path: 'vendors/${widget.businessId}/logo_$timestamp.jpg',
      );

      if (url != null) {
        // 1. Update Local State Immediately
        setState(() {
          _business = _business!.copyWith(logoUrl: url);
        });

        // 2. Update Database
        await _businessService.updateBusiness(widget.businessId, {
          'logoUrl': url,
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Logo güncellendi")));
          // _fetchBusinessData(); // No need to fetch again immediately if we updated local state
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadHeader() async {
    if (widget.businessId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("İşletme ID bulunamadı!")));
      return;
    }

    final file = await _mediaService.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isLoading = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = await _mediaService.uploadImage(
        file: file,
        path: 'vendors/${widget.businessId}/header_$timestamp.jpg',
      );

      if (url != null) {
        // 1. Update Local State Immediately
        setState(() {
          _business = _business!.copyWith(headerImageUrl: url);
        });

        // 2. Update Database
        await _businessService.updateBusiness(widget.businessId, {
          'headerImageUrl': url,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kapak fotoğrafı güncellendi")),
          );
          // _fetchBusinessData(); // No need to fetch again
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLocation() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          initialLatitude: _business!.latitude,
          initialLongitude: _business!.longitude,
        ),
      ),
    );

    if (result != null) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        // Update coordinates
        await _businessService.updateBusiness(widget.businessId, {
          'latitude': result.latitude,
          'longitude': result.longitude,
        });

        // Reverse Geocoding with Timeout
        try {
          // Timeout ekleyelim ki sonsuz döngüye girmesin
          List<Placemark> placemarks = await placemarkFromCoordinates(
            result.latitude,
            result.longitude,
          ).timeout(const Duration(seconds: 5));

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            // Daha detaylı adres formatı
            final address =
                "${place.street ?? ''} ${place.thoroughfare ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}";

            _addressController.text = address;
            // Update address in DB as well
            await _businessService.updateBusiness(widget.businessId, {
              'address': address,
            });
          }
        } catch (e) {
          debugPrint("Reverse geocoding failed or timed out: $e");
          // Adres alınamasa bile koordinat güncellendi, devam et.
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Konum güncellendi")));
          await _fetchBusinessData(); // Await ekleyelim ki veri gelsin
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Hata: $e")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
                options: MapOptions(
                  initialCenter: LatLng(
                    _business!.latitude != 0 ? _business!.latitude : 41.0082,
                    _business!.longitude != 0 ? _business!.longitude : 28.9784,
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
                          _business!.latitude != 0
                              ? _business!.latitude
                              : 41.0082,
                          _business!.longitude != 0
                              ? _business!.longitude
                              : 28.9784,
                        ),
                        radius: _deliveryRadius * 1000, // Convert km to meters
                        useRadiusInMeter: true,
                        color: Colors.blue.withOpacity(0.2),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _business!.latitude != 0
                              ? _business!.latitude
                              : 41.0082,
                          _business!.longitude != 0
                              ? _business!.longitude
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

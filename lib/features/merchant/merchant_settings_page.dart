import 'package:flutter/material.dart';
import 'package:hoppa/core/services/business_service.dart';
import 'package:hoppa/models/business.dart';

class MerchantSettingsPage extends StatefulWidget {
  final String businessId;

  const MerchantSettingsPage({super.key, required this.businessId});

  @override
  State<MerchantSettingsPage> createState() => _MerchantSettingsPageState();
}

class _MerchantSettingsPageState extends State<MerchantSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final BusinessService _businessService = BusinessService();

  bool _isLoading = true;
  Business? _business;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _openingTimeController;
  late TextEditingController _closingTimeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _openingTimeController = TextEditingController();
    _closingTimeController = TextEditingController();
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
          _openingTimeController.text = business.openingTime;
          _closingTimeController.text = business.closingTime;
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
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(TextEditingController controller) async {
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
      // Format: 08:00
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        controller.text = formattedTime;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_business == null) return;

    setState(() => _isLoading = true);

    try {
      await _businessService.updateBusiness(widget.businessId, {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'openingTime': _openingTimeController.text,
        'closingTime': _closingTimeController.text,
        // isOpen switch ile anlık değişir, burada kaydetmeye gerek yok veya eklenebilir
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

  Future<void> _toggleStoreStatus(bool value) async {
    setState(() {
      _business = Business(
        id: _business!.id,
        name: _business!.name,
        address: _business!.address,
        phone: _business!.phone,
        logoUrl: _business!.logoUrl,
        headerImageUrl: _business!.headerImageUrl,
        isOpen: value,
        type: _business!.type,
        categories: _business!.categories,
        openingTime: _business!.openingTime,
        closingTime: _business!.closingTime,
      );
    });

    try {
      await _businessService.updateBusiness(widget.businessId, {
        'isOpen': value,
      });
    } catch (e) {
      // Revert if error
      if (mounted) _fetchBusinessData();
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switch: Dükkan Açık/Kapalı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _business!.isOpen
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _business!.isOpen ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _business!.isOpen ? "Dükkan AÇIK" : "Dükkan KAPALI",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _business!.isOpen ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _business!.isOpen
                            ? "Müşteriler sipariş verebilir"
                            : "Şu an sipariş kabul edilmiyor",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _business!.isOpen,
                    activeColor: Colors.green,
                    onChanged: _toggleStoreStatus,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Profil Bilgileri",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // İşletme Adı
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "İşletme Adı",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              validator: (value) =>
                  value!.isEmpty ? "İşletme adı boş olamaz" : null,
            ),
            const SizedBox(height: 16),

            // Telefon
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Telefon",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value!.isEmpty ? "Telefon boş olamaz" : null,
            ),
            const SizedBox(height: 16),

            // Adres
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Adres",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) => value!.isEmpty ? "Adres boş olamaz" : null,
            ),
            const SizedBox(height: 16),

            // İşletme Türü (Info)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blueGrey),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "İşletme Türü",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _business!.type.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Çalışma Saatleri",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _openingTimeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Açılış",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    onTap: () => _selectTime(_openingTimeController),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _closingTimeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Kapanış",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time_filled),
                    ),
                    onTap: () => _selectTime(_closingTimeController),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
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
          ],
        ),
      ),
    );
  }
}

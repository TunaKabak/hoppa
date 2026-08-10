import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_shared/shared/core/services/campaign_service.dart';
import 'package:core_shared/shared/core/services/media_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core_shared/shared/models/campaign.dart';
import '../providers/merchant_api_providers.dart';
import '../repositories/merchant_product_repository.dart';

class CreateCampaignWizard extends ConsumerStatefulWidget {
  final String businessId;

  const CreateCampaignWizard({super.key, required this.businessId});

  @override
  ConsumerState<CreateCampaignWizard> createState() => _CreateCampaignWizardState();
}

class _CreateCampaignWizardState extends ConsumerState<CreateCampaignWizard> {
  int _currentStep = 0;
  bool _isLoading = false;

  // STEP 1: INFO
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  String? _imageUrl;
  File? _localImageFile;
  bool _isUploadingImage = false;

  // STEP 2: PRODUCTS
  final _searchController = TextEditingController();
  final Set<String> _selectedProductIds = {}; // Selected Barcodes or Product IDs
  bool _selectAll = false;

  // STEP 3: DISCOUNT
  CampaignType _campaignType = CampaignType.percentage;
  final _discountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _createCampaign() async {
    if (_nameController.text.isEmpty ||
        _selectedDateRange == null ||
        _selectedProductIds.isEmpty ||
        _discountController.text.isEmpty ||
        _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurunuz.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final campaign = Campaign(
        id: '', // Firestore assign
        vendorId: widget.businessId,
        name: _nameController.text,
        description: _descriptionController.text,
        type: _campaignType,
        targetProducts: _selectedProductIds.toList(),
        discountValue: double.parse(_discountController.text),
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        imageUrl: _imageUrl!,
        isActive: true,
      );

      await CampaignService().createCampaign(campaign);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kampanya başarıyla oluşturuldu!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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

  Future<void> _pickAndUploadImage() async {
    final MediaService mediaService = MediaService();
    final file = await mediaService.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _localImageFile = file;
      _isUploadingImage = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = await mediaService.uploadImage(
        file: file,
        path: 'campaigns/${widget.businessId}/banner_$timestamp.jpg',
      );

      if (url != null) {
        setState(() => _imageUrl = url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kampanya görseli yüklendi!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Görsel yüklenemedi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Kampanya Oluştur"), centerTitle: true),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            // Validate Step 1
            if (_nameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Kampanya adı giriniz")),
              );
              return;
            }
            if (_selectedDateRange == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Tarih aralığı seçiniz")),
              );
              return;
            }
            if (_imageUrl == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Lütfen bir kampanya görseli yükleyin"),
                ),
              );
              return;
            }
          } else if (_currentStep == 1) {
            // Validate Step 2
            if (_selectedProductIds.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("En az bir ürün seçiniz")),
              );
              return;
            }
          } else if (_currentStep == 2) {
            // Validate Step 3
            if (_discountController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("İndirim tutarı giriniz")),
              );
              return;
            }
            // Submit
            _createCampaign();
            return;
          }

          setState(() => _currentStep++);
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  FilledButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 2 ? "Tamamla" : "Devam Et"),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text("Geri"),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text("Kampanya Bilgileri"),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Kampanya Adı",
                    hintText: "Örn: Yaz İndirimi",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Açıklama",
                    hintText: "Kampanya hakkında kısa bilgi (opsiyonel)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    _selectedDateRange == null
                        ? "Tarih Aralığı Seçin"
                        : "${_selectedDateRange!.start.day}.${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}.${_selectedDateRange!.end.month}",
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDateRange = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _localImageFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _localImageFile!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (_isUploadingImage)
                              const Center(child: CircularProgressIndicator())
                            else
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => setState(() {
                                    _imageUrl = null;
                                    _localImageFile = null;
                                  }),
                                ),
                              ),
                          ],
                        )
                      : _isUploadingImage
                          ? const Center(child: CircularProgressIndicator())
                          : _imageUrl != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _imageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => setState(() {
                                          _imageUrl = null;
                                        }),
                                      ),
                                    ),
                                  ],
                                )
                              : InkWell(
                          onTap: _pickAndUploadImage,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Kampanya Görseli Yükle",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text("Ürün Seçimi"),
            isActive: _currentStep >= 1,
            content: SizedBox(
              height: 420,
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Envanter ürünleri yüklenemedi: $err", style: const TextStyle(color: Colors.red)),
                      ElevatedButton(
                        onPressed: () => ref.refresh(productControllerProvider),
                        child: const Text("Tekrar Deneyin"),
                      )
                    ],
                  ),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(
                      child: Text("Envanterinizde henüz ürün bulunmamaktadır."),
                    );
                  }

                  final search = _searchController.text.trim().toLowerCase();
                  final filteredProducts = products.where((p) {
                    if (search.isEmpty) return true;
                    final nameMatch = p.name.toLowerCase().contains(search);
                    final brandMatch = (p.brand ?? '').toLowerCase().contains(search);
                    final barcodeMatch = (p.barcode ?? '').toLowerCase().contains(search);
                    return nameMatch || brandMatch || barcodeMatch;
                  }).toList();

                  return Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: "Ürün adı, marka veya barkod ile ara...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: Text(
                          "Tümünü Seç (${filteredProducts.length} Ürün)",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: _selectAll,
                        onChanged: (val) {
                          setState(() {
                            _selectAll = val ?? false;
                            if (_selectAll) {
                              for (final p in filteredProducts) {
                                final key = (p.barcode != null && p.barcode!.isNotEmpty) ? p.barcode! : p.id;
                                _selectedProductIds.add(key);
                              }
                            } else {
                              _selectedProductIds.clear();
                            }
                          });
                        },
                      ),
                      const Divider(),
                      Expanded(
                        child: filteredProducts.isEmpty
                            ? const Center(child: Text("Aramanıza uygun ürün bulunamadı."))
                            : ListView.builder(
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final p = filteredProducts[index];
                                  final pKey = (p.barcode != null && p.barcode!.isNotEmpty) ? p.barcode! : p.id;
                                  final isSelected = _selectedProductIds.contains(pKey);

                                  return CheckboxListTile(
                                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      "${p.price.toStringAsFixed(2)} ₺${p.brand != null && p.brand!.isNotEmpty ? ' • ${p.brand}' : ''}",
                                    ),
                                    secondary: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                                          ? Image.network(
                                              p.imageUrl!,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                            )
                                          : const Icon(Icons.image, size: 40, color: Colors.grey),
                                    ),
                                    value: isSelected,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedProductIds.add(pKey);
                                        } else {
                                          _selectedProductIds.remove(pKey);
                                          _selectAll = false;
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Step(
            title: const Text("İndirim Tutarı"),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                SegmentedButton<CampaignType>(
                  segments: const [
                    ButtonSegment(
                      value: CampaignType.percentage,
                      label: Text("Yüzde (%)"),
                      icon: Icon(Icons.percent),
                    ),
                    ButtonSegment(
                      value: CampaignType.fixedPrice,
                      label: Text("Sabit Fiyat"),
                      icon: Icon(Icons.money),
                    ),
                  ],
                  selected: {_campaignType},
                  onSelectionChanged: (Set<CampaignType> newSelection) {
                    setState(() {
                      _campaignType = newSelection.first;
                      _discountController.clear();
                    });
                  },
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _campaignType == CampaignType.percentage
                        ? "İndirim Oranı (%)"
                        : "Sabit Fiyat (₺)",
                    helperText: _campaignType == CampaignType.percentage
                        ? "Örn: 20 yazarsanız %20 indirim uygulanır."
                        : "Örn: 50 yazarsanız ürün 50 TL olur.",
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      _campaignType == CampaignType.percentage
                          ? Icons.percent
                          : Icons.currency_lira,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

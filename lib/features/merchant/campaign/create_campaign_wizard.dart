import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hoppa/core/services/campaign_service.dart';
import 'package:hoppa/core/services/product_service.dart';
import 'package:hoppa/models/campaign.dart';
import 'package:hoppa/models/business_product.dart';

class CreateCampaignWizard extends StatefulWidget {
  final String businessId;

  const CreateCampaignWizard({super.key, required this.businessId});

  @override
  State<CreateCampaignWizard> createState() => _CreateCampaignWizardState();
}

class _CreateCampaignWizardState extends State<CreateCampaignWizard> {
  int _currentStep = 0;
  bool _isLoading = false;

  // STEP 1: INFO
  // _formKey removed
  final _nameController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  // STEP 2: PRODUCTS
  final ProductService _productService = ProductService();
  // _allProducts removed
  final Set<String> _selectedProductIds = {}; // Selected Barcodes actually
  bool _selectAll = false;

  // STEP 3: DISCOUNT
  CampaignType _campaignType = CampaignType.percentage;
  final _discountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _createCampaign() async {
    if (_nameController.text.isEmpty ||
        _selectedDateRange == null ||
        _selectedProductIds.isEmpty ||
        _discountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurunuz.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final campaign = Campaign(
        id: '', // Firestore will assign
        vendorId: widget.businessId,
        name: _nameController.text,
        type: _campaignType,
        targetProducts: _selectedProductIds.toList(),
        discountValue: double.parse(_discountController.text),
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
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

  @override
  Widget build(BuildContext context) {
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
              ],
            ),
          ),
          Step(
            title: const Text("Ürün Seçimi"),
            isActive: _currentStep >= 1,
            content: SizedBox(
              height: 400, // Limit height for list
              child: StreamBuilder<QuerySnapshot>(
                stream: _productService.getBusinessProductsStream(
                  widget.businessId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData) return const Text("Ürün bulunamadı");

                  final docs = snapshot.data!.docs;
                  final products = docs
                      .map(
                        (doc) => BusinessProduct.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      )
                      .toList();

                  // Filter out only available products if needed? No, campaign can be for anything.

                  return Column(
                    children: [
                      CheckboxListTile(
                        title: const Text("Tümünü Seç"),
                        value: _selectAll,
                        onChanged: (val) {
                          setState(() {
                            _selectAll = val ?? false;
                            if (_selectAll) {
                              _selectedProductIds.addAll(
                                products.map((p) => p.productBarcode),
                              );
                            } else {
                              _selectedProductIds.clear();
                            }
                          });
                        },
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final p = products[index];
                            final isSelected = _selectedProductIds.contains(
                              p.productBarcode,
                            );
                            return CheckboxListTile(
                              title: Text(p.product.name),
                              subtitle: Text("${p.price} ₺"),
                              secondary: Image.network(
                                p.product.imageUrl,
                                width: 40,
                                height: 40,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image),
                              ),
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedProductIds.add(p.productBarcode);
                                  } else {
                                    _selectedProductIds.remove(
                                      p.productBarcode,
                                    );
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

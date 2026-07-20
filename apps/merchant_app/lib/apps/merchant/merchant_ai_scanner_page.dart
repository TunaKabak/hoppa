import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core_auth/core_auth.dart';
import 'package:merchant_app/apps/merchant/providers/merchant_api_providers.dart';

class MerchantAIScannerPage extends ConsumerStatefulWidget {
  const MerchantAIScannerPage({super.key});

  @override
  ConsumerState<MerchantAIScannerPage> createState() => _MerchantAIScannerPageState();
}

class _MerchantAIScannerPageState extends ConsumerState<MerchantAIScannerPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;
  String _loadingMessage = "";
  List<Map<String, dynamic>> _scannedProducts = [];

  final List<String> _units = ["ADET", "KG", "LITRE", "PAKET", "DEMET", "GR"];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _scannedProducts = [];
        });
        _analyzeImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Görsel seçilirken hata oluştu: $e")),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = "Yapay Zeka görseli analiz ediyor...\nBu işlem yaklaşık 5-10 saniye sürebilir.";
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/api/merchant/ai/scan-menu',
        body: {'image': base64Image},
      );

      if (response['error'] == false) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _scannedProducts = data.map((item) => {
            'name': item['name']?.toString() ?? '',
            'suggestedPrice': double.tryParse(item['suggestedPrice']?.toString() ?? '0') ?? 0.0,
            'unitCode': item['unitCode']?.toString() ?? 'ADET',
            'categoryName': item['categoryName']?.toString() ?? 'Genel',
            'matchedGlobalProductId': item['matchedGlobalProductId'],
            'imageUrl': item['imageUrl'],
            'barcode': item['barcode'],
            'isMatched': item['isMatched'] ?? false,
            'selected': true, // Default checked
          }).toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Bilinmeyen hata');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Yapay Zeka analizi başarısız oldu: $e")),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelectedProducts() async {
    final selectedItems = _scannedProducts.where((p) => p['selected'] == true).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen envantere eklemek için en az bir ürün seçin.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = "Ürünler envanterinize kaydediliyor...";
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      
      // 1. Katalogda Eşleşenleri Toplu Ekle (bulk-add)
      final matchedItems = selectedItems.where((p) => p['isMatched'] == true).map((p) => {
        'barcode': p['barcode'],
        'price': p['suggestedPrice'],
        'trackStock': false,
        'stockQuantity': 0
      }).toList();

      int savedCount = 0;

      if (matchedItems.isNotEmpty) {
        final response = await apiClient.post(
          '/api/merchant/products/catalog/bulk-add',
          body: {'items': matchedItems},
        );
        if (response['error'] == false) {
          final List<dynamic> saved = response['data'] ?? [];
          savedCount += saved.length;
        }
      }

      // 2. Katalogda Eşleşmeyen Özel Ürünleri Teker Teker Ekle
      final unmatchedItems = selectedItems.where((p) => p['isMatched'] == false).toList();
      for (final item in unmatchedItems) {
        final response = await apiClient.post(
          '/api/merchant/products',
          body: {
            'name': item['name'],
            'price': item['suggestedPrice'],
            'unit': item['unitCode'],
            'categoryName': item['categoryName'],
            'trackStock': false,
            'stockQuantity': 0
          },
        );
        if (response['error'] == false) {
          savedCount++;
        }
      }

      // Refresh product list provider
      ref.invalidate(productControllerProvider);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text("İşlem Başarılı"),
            ],
          ),
          content: Text("$savedCount adet ürün başarıyla envanterinize yüklendi ve yayına alındı."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to inventory
              },
              child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ürünler kaydedilirken hata oluştu: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yapay Zeka ile Menü/Fatura Tara"),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    _loadingMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : _selectedImage == null
              ? _buildImageSelectionPrompt(primaryColor)
              : _buildProductsList(primaryColor),
    );
  }

  Widget _buildImageSelectionPrompt(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        key: const ValueKey("image_selection_prompt"),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 80,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Dijital Ürün Entegrasyonu",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Fatura, menü veya ürün listesi fotoğrafını çekerek saniyeler içinde tüm ürünlerinizi envanterinize aktarabilirsiniz.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text("Fotoğraf Çek"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text("Galeriden Seç"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(Color primaryColor) {
    if (_scannedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Görselde okunabilir ürün bulunamadı. Lütfen tekrar deneyin."),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _selectedImage = null),
              child: const Text("Yeniden Dene"),
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        // Top Summary Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: primaryColor.withValues(alpha: 0.05),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Yapay Zeka ${_scannedProducts.length} adet ürün tespit etti. Fiyat ve birimleri düzenleyip onaylayabilirsiniz.",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _scannedProducts.length,
            itemBuilder: (context, index) {
              final product = _scannedProducts[index];
              final isMatched = product['isMatched'] as bool;

              return Card(
                key: ValueKey("scanned_product_$index"),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: product['selected'],
                            onChanged: (val) {
                              setState(() {
                                product['selected'] = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: product['name'],
                              decoration: const InputDecoration(
                                labelText: "Ürün Adı",
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              onChanged: (val) {
                                product['name'] = val;
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isMatched ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isMatched ? Icons.cloud_done_outlined : Icons.edit_note,
                                  size: 14,
                                  color: isMatched ? Colors.green[700] : Colors.orange[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isMatched ? "Eşleşti" : "Özel",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isMatched ? Colors.green[700] : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: product['suggestedPrice'].toString(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: "Fiyat (TL)",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (val) {
                                product['suggestedPrice'] = double.tryParse(val) ?? 0.0;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _units.contains(product['unitCode'].toUpperCase())
                                  ? product['unitCode'].toUpperCase()
                                  : "ADET",
                              items: _units.map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              )).toList(),
                              decoration: const InputDecoration(
                                labelText: "Birim",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  product['unitCode'] = val;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom Action Buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selectedImage = null),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Yeniden Çek"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saveSelectedProducts,
                    icon: const Icon(Icons.inventory),
                    label: const Text("Seçilenleri Ekle"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

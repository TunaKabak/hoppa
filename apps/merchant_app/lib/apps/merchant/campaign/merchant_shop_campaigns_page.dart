import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core_shared/shared/core/services/media_service.dart';
import '../providers/merchant_api_providers.dart';
import '../merchant_main_layout.dart';

class MerchantShopCampaignsPage extends ConsumerStatefulWidget {
  const MerchantShopCampaignsPage({super.key});

  @override
  ConsumerState<MerchantShopCampaignsPage> createState() => _MerchantShopCampaignsPageState();
}

class _MerchantShopCampaignsPageState extends ConsumerState<MerchantShopCampaignsPage> {
  final _picker = ImagePicker();
  bool _isCreating = false;

  void _showCreateCampaignDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return const _CreateCampaignBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final campaignsAsync = ref.watch(merchantShopCampaignsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(
          "Kampanya & Reklam Yönetimi",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => merchantDrawerKey.currentState?.openDrawer(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCampaignDialog,
        backgroundColor: const Color(0xFFFF5200),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text("Yeni Kampanya", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(merchantShopCampaignsProvider);
        },
        child: campaignsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text("Kampanyalar yüklenemedi: $err", style: GoogleFonts.poppins(color: Colors.red)),
              ],
            ),
          ),
          data: (campaigns) {
            if (campaigns.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "Henüz bir kampanya veya reklam oluşturmadınız.",
                          style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Yeni Kampanya butonu ile dükkanınızı öne çıkarın!",
                          style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: campaigns.length,
              itemBuilder: (context, index) {
                final c = campaigns[index];
                final targetArea = c['targetArea'] as String;
                final status = c['status'] as String;
                final designService = c['designService'] as bool;
                final isActive = c['isActive'] as bool;

                Color statusColor;
                String statusLabel;
                if (status == "APPROVED") {
                  statusColor = const Color(0xFF00A651);
                  statusLabel = "Onaylandı";
                } else if (status == "REJECTED") {
                  statusColor = Colors.red;
                  statusLabel = "Reddedildi";
                } else {
                  statusColor = Colors.orange;
                  statusLabel = "Onay Bekliyor";
                }

                String areaLabel;
                String areaPrice;
                if (targetArea == "MAIN_SLIDER") {
                  areaLabel = "Ana Sayfa Tepe Slider";
                  areaPrice = "Haftalık 2.500 ₺ + %5 Komisyon";
                } else if (targetArea == "CATEGORY_SLIDER") {
                  areaLabel = "Kategori Slider";
                  areaPrice = "%10 Dinamik Komisyon";
                } else {
                  areaLabel = "Dükkan İçi Detay";
                  areaPrice = "Ücretsiz";
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (c['imageUrl'] != null && (c['imageUrl'] as String).isNotEmpty)
                          Image.network(
                            c['imageUrl'],
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        else if (designService)
                          Container(
                            height: 120,
                            color: Colors.blue.shade50,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.design_services_rounded, color: Colors.blue, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  "Afiş Hoppa Grafik Ekibi Tarafından Hazırlanıyor",
                                  style: GoogleFonts.poppins(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            height: 120,
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.campaign, color: Colors.grey, size: 40),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5200).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      areaLabel,
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFFFF5200),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: GoogleFonts.poppins(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                c['title'],
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c['description'],
                                style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Maliyet Modeli",
                                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                                      ),
                                      Text(
                                        areaPrice,
                                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  if (designService)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.amber.shade300),
                                      ),
                                      child: Text(
                                        "DaaS Tasarım (+250 ₺)",
                                        style: GoogleFonts.poppins(fontSize: 9, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CreateCampaignBottomSheet extends ConsumerStatefulWidget {
  const _CreateCampaignBottomSheet();

  @override
  ConsumerState<_CreateCampaignBottomSheet> createState() => _CreateCampaignBottomSheetState();
}

class _CreateCampaignBottomSheetState extends ConsumerState<_CreateCampaignBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _targetArea = "SHOP_DETAIL";
  bool _designService = false;
  String? _imageUrl;
  File? _localImageFile;
  bool _isUploading = false;
  bool _isSaving = false;

  final Set<String> _selectedProductIds = {};
  bool _selectAllProducts = false;

  Future<void> _pickImage() async {
    final MediaService mediaService = MediaService();
    final pickerFile = await mediaService.pickImage(source: ImageSource.gallery);
    if (pickerFile == null) return;

    setState(() {
      _localImageFile = pickerFile;
      _isUploading = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = await mediaService.uploadImage(
        file: pickerFile,
        path: 'campaigns/shop_banners_$timestamp.jpg',
      );
      if (url != null) {
        setState(() {
          _imageUrl = url;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Görsel yüklenirken hata oluştu: $e")),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm zorunlu alanları doldurun.")),
      );
      return;
    }

    if (!_designService && (_imageUrl == null || _imageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen kampanya afişi yükleyin veya Hoppa Tasarım Desteği seçeneğini işaretleyin.")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(merchantShopRepositoryProvider);
      await repo.createShopCampaign(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        imageUrl: _imageUrl ?? "",
        targetArea: _targetArea,
        designService: _designService,
        targetProducts: _selectedProductIds.toList(),
      );

      ref.invalidate(merchantShopCampaignsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kampanya başarıyla kaydedildi. Onaylandıktan sonra yayına alınacaktır."),
            backgroundColor: Color(0xFF00A651),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kaydedilemedi: $e")),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Yeni Kampanya & Reklam",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Kampanya Başlığı (Zorunlu)",
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Kampanya Detayı / Açıklaması (Zorunlu)",
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Kampanya Gösterim Alanı",
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _targetArea,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: "SHOP_DETAIL", child: Text("Dükkan İçi Detay (Ücretsiz)")),
                DropdownMenuItem(value: "CATEGORY_SLIDER", child: Text("Kategori Slaytı (%10 Komisyon)")),
                DropdownMenuItem(value: "MAIN_SLIDER", child: Text("Ana Sayfa Tepe Slaytı (Sabit + %5)")),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _targetArea = val;
                  });
                }
              },
            ),
            if (_targetArea == "MAIN_SLIDER") ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  "💡 Ana Sayfa Tepe Slaytı reklamı haftalık sabit 2.500 ₺ kiralama ücretiyle faturalandırılır ve siparişlerinizde %5 standart komisyon uygulanır.",
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.amber.shade900),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _designService,
                  activeColor: const Color(0xFFFF5200),
                  onChanged: (val) {
                    setState(() {
                      _designService = val ?? false;
                      if (_designService) {
                        _imageUrl = null;
                        _localImageFile = null;
                      }
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    "Profesyonel Tasarım Ekibinden Afiş Desteği İstiyorum (+250 ₺)",
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (!_designService) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: _localImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_localImageFile!, fit: BoxFit.cover),
                        )
                      : _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : _imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(_imageUrl!, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_rounded, color: Colors.grey, size: 36),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Kampanya Afiş Görseli Seçin",
                                      style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              "Kampanyaya Dahil Ürünler (Opsiyonel)",
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              "Boş bırakılırsa kampanya tüm ürünlerinizde geçerli sayılır.",
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final productsAsync = ref.watch(productControllerProvider);
                return productsAsync.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
                  error: (err, _) => Text("Ürünler yüklenemedi: $err", style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
                  data: (products) {
                    if (products.isEmpty) {
                      return Text("Envanterinizde ürün bulunmuyor.", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12));
                    }
                    return Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            dense: true,
                            title: Text("Tüm Ürünleri Seç (${products.length})", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                            value: _selectAllProducts,
                            onChanged: (val) {
                              setState(() {
                                _selectAllProducts = val ?? false;
                                if (_selectAllProducts) {
                                  for (final p in products) {
                                    final key = (p.barcode != null && p.barcode!.isNotEmpty) ? p.barcode! : p.id;
                                    _selectedProductIds.add(key);
                                  }
                                } else {
                                  _selectedProductIds.clear();
                                }
                              });
                            },
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final p = products[index];
                                final pKey = (p.barcode != null && p.barcode!.isNotEmpty) ? p.barcode! : p.id;
                                final isSelected = _selectedProductIds.contains(pKey);

                                return CheckboxListTile(
                                  dense: true,
                                  title: Text(p.name, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                                  subtitle: Text("${p.price.toStringAsFixed(2)} ₺", style: GoogleFonts.poppins(fontSize: 11)),
                                  value: isSelected,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedProductIds.add(pKey);
                                      } else {
                                        _selectedProductIds.remove(pKey);
                                        _selectAllProducts = false;
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Kampanyayı Kaydet",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

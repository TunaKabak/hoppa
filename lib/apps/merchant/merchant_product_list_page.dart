import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/shared/core/services/product_service.dart';
import 'package:hoppa/shared/models/business_product.dart';
import 'package:hoppa/shared/models/product.dart';
import 'package:hoppa/apps/merchant/merchant_main_layout.dart';

class MerchantProductListPage extends StatefulWidget {
  final String businessId;

  const MerchantProductListPage({super.key, required this.businessId});

  @override
  State<MerchantProductListPage> createState() =>
      _MerchantProductListPageState();
}

class _MerchantProductListPageState extends State<MerchantProductListPage>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  late TabController _tabController;

  // --- INVENTORY TAB VARIABLES ---
  final Set<String> _selectedInventoryIds = {};
  bool _isInventoryActionLoading = false;

  // --- CATALOG TAB VARIABLIES ---
  final TextEditingController _catalogSearchController =
      TextEditingController();
  List<Product> _catalogSearchResults = [];
  bool _isCatalogLoading = false;

  // --- CUSTOM PRODUCT VARIABLES ---
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _subCategoryController = TextEditingController(); // Basit Text alan
  final _imageUrlController = TextEditingController();
  final _descController = TextEditingController();
  final _initialPriceController = TextEditingController();
  final _initialStockController = TextEditingController();
  bool _isWeighted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _catalogSearchController.dispose();
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _imageUrlController.dispose();
    _descController.dispose();
    _initialPriceController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ürün Yönetimi",
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
            Tab(text: "Envanterim", icon: Icon(Icons.inventory)),
            Tab(text: "Katalogdan Ekle", icon: Icon(Icons.search)),
            Tab(text: "Özel Ürün", icon: Icon(Icons.add_box)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInventoryTab(),
          _buildCatalogTab(),
          _buildCustomProductTab(),
        ],
      ),
      bottomNavigationBar:
          _selectedInventoryIds.isNotEmpty && _tabController.index == 0
          ? _buildBulkActionBar()
          : null,
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: _isInventoryActionLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  Text(
                    "${_selectedInventoryIds.length} seçildi",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Active/Passive toggle
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      _performBulkStatusUpdate(val == 'active');
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'active',
                        child: Text("Seçili olanları Aktif Yap"),
                      ),
                      const PopupMenuItem(
                        value: 'passive',
                        child: Text("Seçili olanları Pasif Yap"),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.toggle_on, color: Colors.blue, size: 20),
                          SizedBox(width: 4),
                          Text(
                            "Durum",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Delete
                  InkWell(
                    onTap: () {
                      _confirmBulkDelete();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 4),
                          Text(
                            "Sil",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _performBulkStatusUpdate(bool isAvailable) async {
    setState(() => _isInventoryActionLoading = true);
    try {
      await _productService.bulkUpdateBusinessProductsStatus(
        _selectedInventoryIds.toList(),
        isAvailable,
      );
      if (mounted) {
        setState(() {
          _selectedInventoryIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Seçili ürünler ${isAvailable ? 'Aktif' : 'Pasif'} yapıldı!",
            ),
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
      if (mounted) setState(() => _isInventoryActionLoading = false);
    }
  }

  Future<void> _confirmBulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Toplu Silme"),
        content: Text(
          "Seçili ${_selectedInventoryIds.length} ürünü envanterden silmek istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isInventoryActionLoading = true);
      try {
        await _productService.bulkDeleteBusinessProducts(
          _selectedInventoryIds.toList(),
        );
        if (mounted) {
          setState(() {
            _selectedInventoryIds.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Seçili ürünler başarıyla silindi!"),
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
        if (mounted) setState(() => _isInventoryActionLoading = false);
      }
    }
  }

  // ===========================================================================
  // TAB 1: ENVANTER (INVENTORY)
  // ===========================================================================
  Widget _buildInventoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productService.getBusinessProductsStream(widget.businessId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Veri yüklenirken hata oluştu."));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Envanterinizde ürün yok.\n'Katalogdan Ekle' sekmesine giderek ürün ekleyin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final List<BusinessProduct> products = docs.map((doc) {
          return BusinessProduct.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        return Column(
          children: [
            // Select All Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedInventoryIds.length == products.length,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedInventoryIds.addAll(
                            products.map((p) => p.id),
                          );
                        } else {
                          _selectedInventoryIds.clear();
                        }
                      });
                    },
                  ),
                  const Text(
                    "Tümünü Seç",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final bp = products[index];
                  final isSelected = _selectedInventoryIds.contains(bp.id);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedInventoryIds.add(bp.id);
                                } else {
                                  _selectedInventoryIds.remove(bp.id);
                                }
                              });
                            },
                          ),
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              bp.product.imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Info & Stock Switch
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bp.product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // INLINE EDIT: PRICE & STOCK
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    // Price Edit Chip
                                    InkWell(
                                      onTap: () => _showInlineEditDialog(
                                        bp,
                                        type: 'price',
                                        currentValue: bp.price,
                                        title: "Fiyatı Güncelle",
                                        suffix: "₺",
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue[200]!,
                                          ),
                                        ),
                                        child: Text(
                                          "${bp.price.toStringAsFixed(2)} ₺",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Stock Edit Chip
                                    InkWell(
                                      onTap: () => _showInlineEditDialog(
                                        bp,
                                        type: 'stock',
                                        currentValue: bp.stock,
                                        title: "Stoğu Güncelle",
                                        suffix: "Adet",
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.orange[200]!,
                                          ),
                                        ),
                                        child: Text(
                                          "Stok: ${bp.stock.toStringAsFixed(0)}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[800],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Right Side Switches (Availability & Weighed)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Availability Switch
                              Column(
                                children: [
                                  Switch(
                                    value: bp.isAvailable,
                                    activeTrackColor: Colors.green,
                                    onChanged: (val) {
                                      _productService.updateBusinessProduct(
                                        bp.id,
                                        isAvailable: val,
                                      );
                                    },
                                  ),
                                  Text(
                                    bp.isAvailable ? "Aktif" : "Pasif",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: bp.isAvailable
                                          ? Colors.green
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // Tartılı Switch
                              Column(
                                children: [
                                  Switch(
                                    value: bp.product.isWeighted,
                                    activeTrackColor: Colors.blue,
                                    onChanged: (val) {
                                      _productService.updateBusinessProduct(
                                        bp.id,
                                        isWeighted: val,
                                      );
                                    },
                                  ),
                                  Text(
                                    "Tartılı",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: bp.product.isWeighted
                                          ? Colors.blue
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
          ],
        );
      },
    );
  }

  // ===========================================================================
  // TAB 2: KATALOG (CATALOG SEARCH)
  // ===========================================================================
  Widget _buildCatalogTab() {
    return Column(
      children: [
        // SEARCH BAR
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _catalogSearchController,
                      decoration: InputDecoration(
                        hintText: "Ürün ismi veya barkod ara...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onSubmitted: (val) => _performCatalogSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Search Button
                  ElevatedButton(
                    onPressed: _performCatalogSearch,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Barcode Scan Button (Placeholder but functional UI)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Barkod Okuyucu henüz aktif değil (simülasyon: '869' yazıp aratın)",
                        ),
                      ),
                    );
                    _catalogSearchController.text = "869"; // Demo
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("Barkod Tara"),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // RESULTS LIST
        Expanded(
          child: _isCatalogLoading
              ? const Center(child: CircularProgressIndicator())
              : _catalogSearchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        "Ürün bulunamadı veya arama yapılmadı.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _catalogSearchResults.length,
                  itemBuilder: (context, index) {
                    final product = _catalogSearchResults[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image),
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text("${product.brand} • ${product.category}"),
                      trailing: ElevatedButton(
                        onPressed: () => _showAddInventoryDialog(product),
                        child: const Text("Ekle"),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: CUSTOM PRODUCT (ÖZEL ÜRÜN)
  // ===========================================================================
  Widget _buildCustomProductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Yeni Ürün Oluştur",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Global katalogda bulamadığınız ürünleri buradan ekleyebilirsiniz.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Form Fields
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Ürün Adı",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: "Barkod",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Random Barcode gen
                    _barcodeController.text = DateTime.now()
                        .millisecondsSinceEpoch
                        .toString();
                  },
                ),
              ),
              validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: "Marka",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: "Resim URL (Opsiyonel)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Switch for Weighted Check
            SwitchListTile(
              title: const Text("Tartılı Ürün mü?"),
              value: _isWeighted,
              onChanged: (val) => setState(() => _isWeighted = val),
            ),

            const Divider(height: 32),
            const Text(
              "Envanter Bilgileri",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _initialPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Satış Fiyatı (₺)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _initialStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Stok Adedi",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createCustomProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "ÜRÜNÜ OLUŞTUR VE EKLE",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC METHODS ---

  Future<void> _performCatalogSearch() async {
    final query = _catalogSearchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isCatalogLoading = true);

    try {
      final results = await _productService.searchGlobalProducts(query);
      setState(() => _catalogSearchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _isCatalogLoading = false);
    }
  }

  void _showAddInventoryDialog(Product product) {
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: "100");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Satış Fiyatı",
                suffixText: "₺",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Stok",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceCtrl.text);
              final stock = double.tryParse(stockCtrl.text);

              if (price == null || stock == null) return;

              Navigator.pop(ctx);

              try {
                await _productService.addProductToInventory(
                  businessId: widget.businessId,
                  product: product,
                  price: price,
                  stock: stock,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Ürün envantere eklendi!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Switch to Inventory tab
                  _tabController.animateTo(0);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Hata: $e")));
                }
              }
            },
            child: const Text("EKLE"),
          ),
        ],
      ),
    );
  }

  Future<void> _createCustomProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      barcode: _barcodeController.text.trim(),
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      category: _categoryController.text.trim(),
      subCategory: "Genel", // Formda yoktu, varsayılan atadık
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? "https://placehold.co/400?text=No+Image" // Placeholder
          : _imageUrlController.text.trim(),
      isWeighted: _isWeighted,
      description: "Özel Ürün",
    );

    final price = double.parse(_initialPriceController.text);
    final stock = double.parse(_initialStockController.text);

    try {
      // 1. Global'e ekle (Custom olarak)
      await _productService.createGlobalProduct(product);

      // 2. Envantere ekle
      await _productService.addProductToInventory(
        businessId: widget.businessId,
        product: product,
        price: price,
        stock: stock,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Özel ürün oluşturuldu ve eklendi!"),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset(); // Formu temizle
        _tabController.animateTo(0); // Envantere git
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  void _showInlineEditDialog(
    BusinessProduct bp, {
    required String type,
    required double currentValue,
    required String title,
    required String suffix,
  }) {
    final controller = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            suffixText: suffix,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                if (type == 'price') {
                  _productService.updateBusinessProduct(bp.id, price: val);
                } else {
                  _productService.updateBusinessProduct(bp.id, stock: val);
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }
}

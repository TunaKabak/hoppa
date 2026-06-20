import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/apps/merchant/merchant_main_layout.dart';
import 'package:hoppa/apps/merchant/repositories/merchant_product_repository.dart';
import 'package:hoppa/apps/merchant/providers/merchant_api_providers.dart';

class MerchantProductListPage extends ConsumerStatefulWidget {
  final String businessId;
  final bool isActiveTab;

  const MerchantProductListPage({
    super.key,
    required this.businessId,
    this.isActiveTab = false,
  });

  @override
  ConsumerState<MerchantProductListPage> createState() =>
      _MerchantProductListPageState();
}

class _MerchantProductListPageState extends ConsumerState<MerchantProductListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- INVENTORY TAB VARIABLES ---
  List<String> _selectedCategories = [];
  List<String> _selectedBrands = [];
  final Set<String> _selectedInventoryIds = {};
  bool _isInventoryActionLoading = false;

  // --- CATALOG TAB VARIABLIES ---
  final TextEditingController _catalogSearchController = TextEditingController();
  List<CatalogProduct> _catalogSearchResults = [];
  bool _isCatalogLoading = false;
  final Set<String> _selectedCatalogBarcodes = {};
  CatalogFilters? _catalogFilters;
  String? _inventoryFilter = 'not_in';

  // Catalog Pagination
  int _catalogPage = 1;
  bool _hasMoreCatalogItems = true;
  bool _isCatalogPaginating = false;
  final ScrollController _catalogScrollController = ScrollController();

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
  final _weightOrVolumeController = TextEditingController();
  final _preparationTimeController = TextEditingController();
  final _depositPriceController = TextEditingController();
  bool _hasDeposit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
      if (_tabController.index == 1 && _catalogSearchResults.isEmpty && !_isCatalogLoading) {
        _performCatalogSearch();
      }
    });
    _loadCatalogFilters();
    _catalogScrollController.addListener(() {
      if (_catalogScrollController.position.pixels >= _catalogScrollController.position.maxScrollExtent - 200) {
        if (!_isCatalogLoading && !_isCatalogPaginating && _hasMoreCatalogItems) {
          _performCatalogSearch(isLoadMore: true);
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.index == 1 && _catalogSearchResults.isEmpty && mounted) {
        _performCatalogSearch();
      }
    });
  }

  void _loadCatalogFilters() async {
    try {
      final repo = ref.read(merchantProductRepositoryProvider);
      final filters = await repo.getCatalogFilters();
      if (mounted) {
        setState(() {
          _catalogFilters = filters;
        });
      }
    } catch (e) {
      // Slipped silently
    }
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
    _weightOrVolumeController.dispose();
    _preparationTimeController.dispose();
    _depositPriceController.dispose();
    _catalogScrollController.dispose();
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
      bottomNavigationBar: _tabController.index == 0 && _selectedInventoryIds.isNotEmpty
          ? _buildBulkActionBar()
          : _tabController.index == 1 && _selectedCatalogBarcodes.isNotEmpty
              ? _buildCatalogBulkActionBar()
              : null,
    );
  }

  Widget _buildCatalogBulkActionBar() {
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
        child: _isCatalogLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  Text(
                    "${_selectedCatalogBarcodes.length} seçildi",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  _buildResponsiveActionRow([
                    _ActionItem(
                      value: 'add',
                      label: "Envantere Ekle",
                      icon: Icons.add_box,
                      color: Colors.green,
                      onTap: () => _showBulkAddInventoryDialog(),
                    ),
                  ]),
                ],
              ),
      ),
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
                  _buildResponsiveActionRow([
                    _ActionItem(
                      value: 'active',
                      label: "Aktif Yap",
                      icon: Icons.toggle_on,
                      color: Colors.blue,
                      onTap: () => _performBulkStatusUpdate(true),
                    ),
                    _ActionItem(
                      value: 'passive',
                      label: "Pasif Yap",
                      icon: Icons.toggle_off,
                      color: Colors.grey,
                      onTap: () => _performBulkStatusUpdate(false),
                    ),
                    _ActionItem(
                      value: 'delete',
                      label: "Sil",
                      icon: Icons.delete,
                      color: Colors.red,
                      onTap: () => _confirmBulkDelete(),
                    ),
                  ]),
                ],
              ),
      ),
    );
  }

  Widget _buildResponsiveActionRow(List<_ActionItem> actions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Assume each action button takes roughly 100px width.
        // We will show as many as fit, and put the rest in a dropdown.
        final availableWidth = constraints.maxWidth;
        // In this case, we're inside a Row with Spacer(), so constraints.maxWidth is infinite.
        // We actually want MediaQuery for screen width.
        final screenWidth = MediaQuery.of(context).size.width;
        // The text "X seçildi" takes ~100px. Padding is ~32px.
        final spaceForActions = screenWidth - 140;
        final maxVisible = (spaceForActions / 100).floor();
        
        if (maxVisible >= actions.length) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: actions.map((a) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: InkWell(
                  onTap: a.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(a.icon, color: a.color, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          a.label,
                          style: TextStyle(color: a.color, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        } else {
          // Dropdown for all
          return PopupMenuButton<_ActionItem>(
            onSelected: (val) => val.onTap(),
            itemBuilder: (ctx) => actions.map((a) {
              return PopupMenuItem(
                value: a,
                child: Row(
                  children: [
                    Icon(a.icon, color: a.color, size: 20),
                    const SizedBox(width: 8),
                    Text(a.label, style: TextStyle(color: a.color)),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.more_vert, color: Colors.blue, size: 20),
                  SizedBox(width: 4),
                  Text(
                    "İşlemler",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _performBulkStatusUpdate(bool isAvailable) async {
    setState(() => _isInventoryActionLoading = true);
    try {
      final notif = ref.read(productControllerProvider.notifier);
      for (final id in _selectedInventoryIds) {
        await notif.toggleProductStatus(id, isAvailable);
      }
      
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
        final notif = ref.read(productControllerProvider.notifier);
        for (final id in _selectedInventoryIds) {
          await notif.deleteProduct(id);
        }

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
    final productsAsync = ref.watch(productControllerProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text("Veri yüklenirken hata oluştu: $e")),
      data: (products) {
        if (products.isEmpty) {
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
                  final p = products[index];
                  final isSelected = _selectedInventoryIds.contains(p.id);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.green.shade500
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedInventoryIds.remove(p.id);
                          } else {
                            _selectedInventoryIds.add(p.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              activeColor: Colors.green.shade500,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedInventoryIds.add(p.id);
                                  } else {
                                    _selectedInventoryIds.remove(p.id);
                                  }
                                });
                              },
                            ),
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              p.imageUrl ?? '',
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
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      // Price Edit Chip
                                      InkWell(
                                        onTap: () => _showInlineEditDialog(
                                          p,
                                          type: 'price',
                                          currentValue: p.price,
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
                                            "${p.price.toStringAsFixed(2)} ₺",
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
                                          p,
                                          type: 'stock',
                                          currentValue: (p.stock ?? 0).toDouble(),
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
                                            "Stok: ${p.stock}",
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
                                    value: p.isActive,
                                    activeTrackColor: Colors.green,
                                    onChanged: (val) {
                                      ref.read(productControllerProvider.notifier).toggleProductStatus(p.id, val);
                                    },
                                  ),
                                  Text(
                                    p.isActive ? "Aktif" : "Pasif",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: p.isActive
                                          ? Colors.green
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // Tartılı Switch has been removed as the new model does not support it
                            ],
                          ),
                        ],
                      ),
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
              const SizedBox(height: 12),
              // Filter Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (_catalogFilters == null) return;
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) => _MultiSelectFilterSheet(
                            title: "Kategoriler",
                            allItems: _catalogFilters!.categories,
                            selectedItems: _selectedCategories,
                            onSelectionChanged: (selections) {
                              setState(() {
                                _selectedCategories = selections;
                              });
                              _performCatalogSearch();
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.category, size: 18),
                      label: Text(_selectedCategories.isEmpty ? "Kategoriler" : "Kategori (${_selectedCategories.length})"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (_catalogFilters == null) return;
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) => _MultiSelectFilterSheet(
                            title: "Markalar",
                            allItems: _catalogFilters!.brands,
                            selectedItems: _selectedBrands,
                            onSelectionChanged: (selections) {
                              setState(() {
                                _selectedBrands = selections;
                              });
                              _performCatalogSearch();
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.branding_watermark, size: 18),
                      label: Text(_selectedBrands.isEmpty ? "Markalar" : "Marka (${_selectedBrands.length})"),
                    ),
                  ),
                ],
              ),
              // Envanter Filtresi Switch
              SwitchListTile(
                title: const Text("Envanterde Olanları Gizle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                value: _inventoryFilter == 'not_in',
                activeColor: Colors.green.shade500,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    _inventoryFilter = val ? 'not_in' : null;
                  });
                  _performCatalogSearch();
                },
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
              : ListView.separated(
                  controller: _catalogScrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _catalogSearchResults.length + (_hasMoreCatalogItems ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _catalogSearchResults.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final product = _catalogSearchResults[index];
                    final isSelected = _selectedCatalogBarcodes.contains(product.barcode);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.green.shade500 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCatalogBarcodes.remove(product.barcode);
                            } else {
                              _selectedCatalogBarcodes.add(product.barcode);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: Colors.green.shade500,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedCatalogBarcodes.add(product.barcode);
                                    } else {
                                      _selectedCatalogBarcodes.remove(product.barcode);
                                    }
                                  });
                                },
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${product.brand} • ${product.category}",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
    final shopAsync = ref.watch(shopControllerProvider);

    return shopAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Hata: $e", style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(shopControllerProvider);
                },
                child: const Text("Yeniden Dene"),
              ),
            ],
          ),
        ),
      ),
      data: (shop) {
        if (shop == null) {
          return const Center(child: Text("Dükkan bilgisi bulunamadı."));
        }

        final shopType = shop.type;

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
                Text(
                  "${shop.name} için özel ürün ekleyebilirsiniz.",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Ürün Adı (Herkes için)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Ürün Adı",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? "Zorunlu alan" : null,
                ),
                const SizedBox(height: 16),

                // Kategori (Herkes için)
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: "Kategori",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? "Zorunlu alan" : null,
                ),
                const SizedBox(height: 16),

                // Barkod & Marka (Restaurant hariç, Market için Zorunlu, diğerleri için Opsiyonel)
                if (shopType != 'RESTAURANT') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: shopType == 'MARKET' ? "Barkod (Zorunlu)" : "Barkod (Opsiyonel)",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                _barcodeController.text = DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString();
                              },
                            ),
                          ),
                          validator: (v) {
                            if (shopType == 'MARKET' && (v == null || v.isEmpty)) {
                              return "Zorunlu alan";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          decoration: InputDecoration(
                            labelText: shopType == 'MARKET' ? "Marka (Zorunlu)" : "Marka (Opsiyonel)",
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (shopType == 'MARKET' && (v == null || v.isEmpty)) {
                              return "Zorunlu alan";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Hazırlanma Süresi (Sadece RESTAURANT)
                if (shopType == 'RESTAURANT') ...[
                  TextFormField(
                    controller: _preparationTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Hazırlanma Süresi (Dakika)",
                      border: OutlineInputBorder(),
                      suffixText: "dk",
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Zorunlu alan";
                      if (int.tryParse(v) == null) return "Geçerli bir sayı girin.";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Ağırlık veya Hacim (Restaurant hariç)
                if (shopType != 'RESTAURANT') ...[
                  TextFormField(
                    controller: _weightOrVolumeController,
                    decoration: const InputDecoration(
                      labelText: "Ağırlık veya Hacim (Örn: 1.5L, 500g)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Resim URL
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: "Resim URL (Opsiyonel)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Açıklama
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: "Açıklama (Opsiyonel)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Depozito Bilgisi (Sadece WATER)
                if (shopType == 'WATER') ...[
                  SwitchListTile(
                    title: const Text("Depozito Var mı?"),
                    value: _hasDeposit,
                    onChanged: (val) => setState(() => _hasDeposit = val),
                  ),
                  if (_hasDeposit) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _depositPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Depozito Ücreti (₺)",
                        border: OutlineInputBorder(),
                        prefixText: "₺ ",
                      ),
                      validator: (v) {
                        if (_hasDeposit && (v == null || v.isEmpty)) {
                          return "Zorunlu alan";
                        }
                        if (_hasDeposit && double.tryParse(v!) == null) {
                          return "Geçerli bir sayı girin.";
                        }
                        return null;
                      },
                    ),
                  ],
                  const Divider(height: 32),
                ],

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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Satış Fiyatı (₺)",
                          border: OutlineInputBorder(),
                          prefixText: "₺ ",
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Zorunlu alan";
                          if (double.tryParse(v) == null) return "Geçerli bir sayı girin.";
                          return null;
                        },
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
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Zorunlu alan";
                          if (int.tryParse(v) == null) return "Geçerli bir tam sayı girin.";
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _createCustomProduct(shopType),
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
      },
    );
  }

  // --- LOGIC METHODS ---

  Future<void> _performCatalogSearch({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (_isCatalogPaginating || !_hasMoreCatalogItems) return;
      setState(() {
        _isCatalogPaginating = true;
        _catalogPage++;
      });
    } else {
      setState(() {
        _isCatalogLoading = true;
        _catalogPage = 1;
        _catalogSearchResults.clear();
      });
    }

    try {
      final repo = ref.read(merchantProductRepositoryProvider);
      final query = _catalogSearchController.text.trim();
      final results = await repo.searchCatalog(
        query,
        page: _catalogPage,
        limit: 20,
        category: _selectedCategories.isNotEmpty ? _selectedCategories.join(',') : null,
        brand: _selectedBrands.isNotEmpty ? _selectedBrands.join(',') : null,
        // The backend might not support the `inventoryFilter` yet, but we will apply it locally if needed,
        // or just pass it to the API if it's supported. 
      );
      
      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _catalogSearchResults.addAll(results);
          } else {
            _catalogSearchResults = results;
          }
          _hasMoreCatalogItems = results.length == 20;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Arama hatası: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCatalogLoading = false;
          _isCatalogPaginating = false;
        });
      }
    }
  }

  void _showAddInventoryDialog(CatalogProduct product) {
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Katalogdan Ürün Ekle\n${product.name}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: dialogFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Satış Fiyatı (₺)",
                  border: OutlineInputBorder(),
                  prefixText: "₺ ",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Fiyat girmelisiniz.";
                  if (double.tryParse(val) == null) return "Geçerli bir sayı girin.";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stok Miktarı (Adet)",
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Stok girmelisiniz.";
                  if (int.tryParse(val) == null) return "Geçerli bir tam sayı girin.";
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!dialogFormKey.currentState!.validate()) return;

              final price = double.parse(priceController.text);
              final stock = int.parse(stockController.text);

              Navigator.pop(ctx); // Close dialog

              // Show loading indicator
              setState(() {
                _isCatalogLoading = true;
              });

              try {
                await ref.read(productControllerProvider.notifier).addProductFromCatalog(
                  product.barcode,
                  price,
                  stock,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Ürün envanterinize başarıyla eklendi!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Animate back to Inventory tab
                  _tabController.animateTo(0);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Ürün eklenirken hata oluştu: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isCatalogLoading = false;
                  });
                }
              }
            },
            child: const Text("Envantere Ekle"),
          ),
        ],
      ),
    );
  }

  void _showBulkAddInventoryDialog() {
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Toplu Ürün Ekle\n${_selectedCatalogBarcodes.length} ürün seçildi",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: dialogFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Tüm seçili ürünler için varsayılan fiyat ve stok belirleyin:",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Satış Fiyatı (₺)",
                  border: OutlineInputBorder(),
                  prefixText: "₺ ",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Fiyat girmelisiniz.";
                  if (double.tryParse(val) == null) return "Geçerli bir sayı girin.";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stok Miktarı (Adet) - Opsiyonel",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!dialogFormKey.currentState!.validate()) return;

              final price = double.parse(priceController.text);
              final stock = stockController.text.isNotEmpty ? int.parse(stockController.text) : null;

              Navigator.pop(ctx);

              setState(() {
                _isCatalogLoading = true;
              });

              try {
                final repo = ref.read(merchantProductRepositoryProvider);
                final items = _selectedCatalogBarcodes.map((barcode) => {
                  'barcode': barcode,
                  'price': price,
                  'stock': stock ?? 0,
                }).toList();
                
                await repo.bulkAddFromCatalog(items);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Seçili ürünler envanterinize başarıyla eklendi!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {
                    _selectedCatalogBarcodes.clear();
                  });
                  // Refresh inventory list
                  ref.refresh(productControllerProvider);
                  _tabController.animateTo(0);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Toplu ekleme hatası: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isCatalogLoading = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Envantere Ekle"),
          ),
        ],
      ),
    );
  }

  Future<void> _createCustomProduct(String shopType) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isCatalogLoading = true;
    });

    try {
      final payload = <String, dynamic>{
        'shopId': widget.businessId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : "${_brandController.text.trim()} • ${_categoryController.text.trim()}",
        'price': double.tryParse(_initialPriceController.text) ?? 0.0,
        'stock': int.tryParse(_initialStockController.text) ?? 0,
        'imageUrl': _imageUrlController.text.trim(),
        'isActive': true,
        'categoryName': _categoryController.text.trim(),
      };

      if (shopType == 'RESTAURANT') {
        payload['preparationTime'] = int.tryParse(_preparationTimeController.text) ?? 0;
      } else if (shopType == 'MARKET') {
        payload['barcode'] = _barcodeController.text.trim();
        payload['brand'] = _brandController.text.trim();
        payload['stockQuantity'] = int.tryParse(_initialStockController.text) ?? 0;
        payload['weightOrVolume'] = _weightOrVolumeController.text.trim().isNotEmpty ? _weightOrVolumeController.text.trim() : null;
      } else if (shopType == 'WATER') {
        payload['barcode'] = _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null;
        payload['brand'] = _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null;
        payload['stockQuantity'] = int.tryParse(_initialStockController.text) ?? 0;
        payload['weightOrVolume'] = _weightOrVolumeController.text.trim().isNotEmpty ? _weightOrVolumeController.text.trim() : null;
        payload['hasDeposit'] = _hasDeposit;
        if (_hasDeposit) {
          payload['depositPrice'] = double.tryParse(_depositPriceController.text) ?? 0.0;
        }
      } else {
        payload['barcode'] = _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null;
        payload['brand'] = _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null;
        payload['stockQuantity'] = int.tryParse(_initialStockController.text) ?? 0;
        payload['weightOrVolume'] = _weightOrVolumeController.text.trim().isNotEmpty ? _weightOrVolumeController.text.trim() : null;
      }

      await ref.read(productControllerProvider.notifier).addProduct(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ürün başarıyla eklendi!"), backgroundColor: Colors.green)
        );
        _formKey.currentState!.reset();
        _barcodeController.clear();
        _nameController.clear();
        _brandController.clear();
        _categoryController.clear();
        _subCategoryController.clear();
        _imageUrlController.clear();
        _descController.clear();
        _initialPriceController.clear();
        _initialStockController.clear();
        _weightOrVolumeController.clear();
        _preparationTimeController.clear();
        _depositPriceController.clear();
        setState(() {
          _hasDeposit = false;
        });
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCatalogLoading = false;
        });
      }
    }
  }

  void _showInlineEditDialog(
    MerchantProduct p, {
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
                  ref.read(productControllerProvider.notifier).updateProduct(p.id, {'price': val});
                } else {
                  ref.read(productControllerProvider.notifier).updateProduct(p.id, {'stock': val.toInt()});
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

class _ActionItem {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _MultiSelectFilterSheet extends StatefulWidget {
  final String title;
  final List<String> allItems;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onSelectionChanged;

  const _MultiSelectFilterSheet({
    required this.title,
    required this.allItems,
    required this.selectedItems,
    required this.onSelectionChanged,
  });

  @override
  State<_MultiSelectFilterSheet> createState() => _MultiSelectFilterSheetState();
}

class _MultiSelectFilterSheetState extends State<_MultiSelectFilterSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];
  late List<String> _currentSelections;
  
  // Pagination variables
  List<String> _displayedItems = [];
  final int _pageSize = 20;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _currentSelections = List.from(widget.selectedItems);
    _filteredItems = widget.allItems;
    _updateDisplayedItems();
  }

  void _updateDisplayedItems() {
    _displayedItems = _filteredItems.take(_currentPage * _pageSize).toList();
  }

  void _loadMore() {
    if (_displayedItems.length < _filteredItems.length) {
      setState(() {
        _currentPage++;
        _updateDisplayedItems();
      });
    }
  }

  void _filter(String query) {
    setState(() {
      _currentPage = 1;
      if (query.isEmpty) {
        _filteredItems = widget.allItems;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredItems = widget.allItems
            .where((item) => item.toLowerCase().contains(lowerQuery))
            .toList();
      }
      _updateDisplayedItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Ara...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
                onChanged: _filter,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                    _loadMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _displayedItems.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _currentSelections.isEmpty;
                      return ListTile(
                        title: Text("Tümünü Temizle", style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                        onTap: () {
                          setState(() {
                            _currentSelections.clear();
                          });
                        },
                      );
                    }
                    if (index == _displayedItems.length + 1) {
                      if (_displayedItems.length < _filteredItems.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    
                    final item = _displayedItems[index - 1];
                    final isSelected = _currentSelections.contains(item);
                    return CheckboxListTile(
                      title: Text(item, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      value: isSelected,
                      activeColor: Colors.green.shade500,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _currentSelections.add(item);
                          } else {
                            _currentSelections.remove(item);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSelectionChanged(_currentSelections);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Uygula", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }
}

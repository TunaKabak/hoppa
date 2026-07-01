import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:hoppa/apps/consumer/business/business_provider.dart';
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/apps/consumer/cart/cart_provider.dart';
import 'package:hoppa/apps/consumer/cart/widgets/cart_price_badge.dart';
import 'package:hoppa/apps/consumer/home/widgets/modern_product_card.dart';
import 'package:hoppa/apps/consumer/orders/widgets/active_order_card.dart';
import 'package:hoppa/apps/consumer/product/product_detail_page.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:hoppa/shared/models/shop_category_data.dart';
import 'package:hoppa/apps/consumer/home/widgets/campaign_carousel.dart';
class ModernShopDetailPage extends ConsumerStatefulWidget {
  final Business shop;
  const ModernShopDetailPage({super.key, required this.shop});

  @override
  ConsumerState<ModernShopDetailPage> createState() => _ModernShopDetailPageState();
}

class _ModernShopDetailPageState extends ConsumerState<ModernShopDetailPage> {
  int _crossAxisCount = 2;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _sidebarScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  bool _isScrolled = false;

  final List<String> _sortOptions = [
    'Önerilen',
    'Fiyat Artan',
    'Fiyat Azalan',
    'İsim A-Z',
    'İsim Z-A',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shop.type.label == 'Çiçek') {
        ref.read(selectedCatalogCategoryProvider.notifier).state = 'Çiçek';
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _sidebarScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool previousScrolled = _isScrolled;
    _isScrolled = _scrollController.offset > 120.0;
    if (previousScrolled != _isScrolled) {
      setState(() {});
    }
  }

  void _changeGrid(int count) {
    setState(() => _crossAxisCount = count);
  }

  void _changeBusiness() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("İşletmeyi Değiştir"),
        content: const Text(
          "Farklı bir işletmeye geçerseniz, mevcut sepetiniz temizlenecektir. Devam etmek istiyor musunuz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(cartProvider.notifier).clearCart();
              ref.read(selectedCatalogCategoryProvider.notifier).state = 'Tümü';
              ref.read(selectedCatalogSubCategoryProvider.notifier).state = 'Tümü';
              ref.read(selectedCatalogSortOptionProvider.notifier).state = 'Önerilen';
              ref.read(catalogSearchQueryProvider.notifier).state = '';
              p.Provider.of<BusinessProvider>(
                context,
                listen: false,
              ).clearBusiness();
            },
            child: const Text(
              "Değiştir",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridIcon(int count, IconData icon) {
    bool isSelected = _crossAxisCount == count;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _changeGrid(count),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? theme.primaryColor : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'water_drop':
      case 'su & i̇çecek':
      case 'su':
        return Icons.water_drop;
      case 'apple':
      case 'meyve & sebze':
        return Icons.apple;
      case 'cookie':
      case 'atıştırmalık':
        return Icons.cookie;
      case 'breakfast_dining':
      case 'fırın':
        return Icons.breakfast_dining;
      case 'rice_bowl':
      case 'temel gıda':
        return Icons.rice_bowl;
      case 'egg_alt':
      case 'egg':
      case 'süt & kahvaltılık':
        return Icons.egg_alt;
      case 'cleaning_services':
      case 'temizlik':
        return Icons.cleaning_services;
      case 'local_florist':
      case 'flower':
      case 'çiçek':
        return Icons.local_florist;
      case 'grass':
        return Icons.grass;
      case 'redeem':
        return Icons.redeem;
      case 'circle_outlined':
        return Icons.circle_outlined;
      case 'shopping_basket':
      default:
        return Icons.shopping_basket;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedCatalogCategoryProvider);
    final selectedSubCategory = ref.watch(selectedCatalogSubCategoryProvider);
    final selectedSortOption = ref.watch(selectedCatalogSortOptionProvider);
    final searchQuery = ref.watch(catalogSearchQueryProvider);

    final productsAsync = ref.watch(filteredShopProductsProvider(widget.shop.id));
    final categoriesAsync = ref.watch(shopCategoriesProvider(widget.shop.id));

    List<String> currentSubCategories = [];
    if (selectedCategory != 'Tümü' && categoriesAsync.hasValue) {
      final matchingCat = categoriesAsync.value!.firstWhere(
        (c) => c.name == selectedCategory,
        orElse: () => ShopCategoryData(id: '', name: '', iconName: '', subCategories: []),
      );
      currentSubCategories = matchingCat.subCategories;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              expandedHeight: 250.0,
              backgroundColor: theme.primaryColor,
              elevation: _isScrolled ? 4 : 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  p.Provider.of<BusinessProvider>(context, listen: false).clearBusiness();
                },
              ),
              title: _isScrolled
                  ? GestureDetector(
                      onTap: _changeBusiness,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.shop.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  "İşletmeyi Değiştir",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    )
                  : null,
              actions: [
                AnimatedOpacity(
                  opacity: _isScrolled ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: const CartPriceBadge(),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.shop.headerImageUrl.isNotEmpty
                          ? widget.shop.headerImageUrl
                          : "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80",
                      fit: BoxFit.cover,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black45,
                            Colors.transparent,
                            Colors.black87,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    )
                                  ],
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    widget.shop.logoUrl.isNotEmpty
                                        ? widget.shop.logoUrl
                                        : "https://via.placeholder.com/100",
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.store,
                                      color: theme.colorScheme.primary,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.shop.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${widget.shop.averageRating.toStringAsFixed(1)} (${widget.shop.reviewCount} Değerlendirme)",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildHeaderBadge(
                                  Icons.access_time_filled_rounded,
                                  "${widget.shop.openingTime} - ${widget.shop.closingTime}",
                                  Colors.orangeAccent,
                                ),
                                _buildHeaderBadge(
                                  Icons.delivery_dining_rounded,
                                  widget.shop.averageDeliveryTime,
                                  Colors.greenAccent,
                                ),
                                _buildHeaderBadge(
                                  Icons.payments_rounded,
                                  widget.shop.baseDeliveryFee == 0
                                      ? "Ücretsiz Teslimat"
                                      : "${widget.shop.baseDeliveryFee.toStringAsFixed(0)} TL",
                                  Colors.lightBlueAccent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Pane: Sidebar categories list
            Container(
              width: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                ),
                data: (shopCategories) {
                  final List<Map<String, dynamic>> sidebarCategories = [
                    {'name': 'Tümü', 'icon': Icons.grid_view}
                  ];

                  for (final cat in shopCategories) {
                    sidebarCategories.add({
                      'name': cat.name,
                      'icon': _getCategoryIcon(cat.iconName),
                    });
                  }

                  return ListView.builder(
                    controller: _sidebarScrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sidebarCategories.length,
                    itemBuilder: (context, index) {
                      final cat = sidebarCategories[index];
                      final catName = cat['name'] as String;
                      final isSelected = catName == selectedCategory;

                      return GestureDetector(
                        onTap: () {
                          ref.read(selectedCatalogCategoryProvider.notifier).state = catName;
                          ref.read(selectedCatalogSubCategoryProvider.notifier).state = 'Tümü';
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? theme.primaryColor : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                size: 24,
                                color: isSelected ? theme.primaryColor : Colors.grey[500],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                catName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? theme.primaryColor : Colors.grey[700],
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

            // Right Pane: Products Scroll View
            Expanded(
              child: CustomScrollView(
                controller: _rightScrollController,
                slivers: [
                  // Search Input
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            ref.read(catalogSearchQueryProvider.notifier).state = val;
                          },
                          decoration: InputDecoration(
                            hintText: "Ürün, kategori veya marka ara...",
                            hintStyle: theme.inputDecorationTheme.hintStyle?.copyWith(fontSize: 13),
                            prefixIcon: Icon(
                              Icons.search,
                              color: theme.primaryColor,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Closed Shop Warning
                  if (!widget.shop.isOpen)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Bu işletme kapalıdır. Sipariş veremezsiniz. Saatler: ${widget.shop.openingTime} - ${widget.shop.closingTime}",
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Campaigns
                  if (selectedCategory == 'Tümü' && searchQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: ref.watch(activeCampaignsProvider).when(
                            loading: () => const SizedBox.shrink(),
                            error: (err, stack) => const SizedBox.shrink(),
                            data: (campaigns) {
                              if (campaigns.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: CampaignCarousel(campaigns: campaigns),
                              );
                            },
                          ),
                    ),

                  // Active Order card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ActiveOrderCard(businessId: widget.shop.id),
                    ),
                  ),

                  // Subcategory Horizontal chips
                  if (currentSubCategories.isNotEmpty && searchQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        height: 38,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: currentSubCategories.length,
                          itemBuilder: (context, index) {
                            final subCat = currentSubCategories[index];
                            final isSelected = subCat == selectedSubCategory;

                            return GestureDetector(
                              onTap: () {
                                ref.read(selectedCatalogSubCategoryProvider.notifier).state = subCat;
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.primaryColor : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : Colors.grey.shade300,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  subCat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[800],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Sorting and Grid size controls
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSortOption,
                                icon: const Icon(Icons.sort, size: 16, color: Colors.grey),
                                isDense: true,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: _sortOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    ref.read(selectedCatalogSortOptionProvider.notifier).state = newValue;
                                  }
                                },
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _buildGridIcon(1, Icons.view_list_rounded),
                              _buildGridIcon(2, Icons.grid_view_rounded),
                              _buildGridIcon(3, Icons.grid_on_rounded),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Products Grid
                  productsAsync.when(
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (err, stack) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Center(child: Text("Ürünler yüklenirken hata oluştu: $err")),
                      ),
                    ),
                    data: (filteredProducts) {
                      if (filteredProducts.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    "Bu kategoride ürün bulunamadı.",
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _crossAxisCount,
                            childAspectRatio: _crossAxisCount == 1
                                ? 2.8
                                : (_crossAxisCount == 2 ? 0.72 : 0.65),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = filteredProducts[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailPage(businessProduct: product),
                                    ),
                                  );
                                },
                                child: ModernProductCard(
                                  businessProduct: product,
                                  isListView: _crossAxisCount == 1,
                                  isCompact: _crossAxisCount > 2,
                                  campaign: null,
                                ),
                              );
                            },
                            childCount: filteredProducts.length,
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

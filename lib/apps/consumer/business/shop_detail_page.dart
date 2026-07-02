import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:hoppa/apps/consumer/business/business_provider.dart';
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/shared/models/business_product.dart';
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
  bool _showScrollToTop = false;
  bool _showMiniCategories = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shop.type.label == 'Çiçek') {
        ref.read(selectedCatalogCategoryProvider.notifier).state = 'Çiçek';
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
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

  Widget _buildMiniCategoriesList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ShopCategoryData>> categoriesAsync,
    AsyncValue<List<BusinessProduct>> allProductsAsync,
    String selectedCategory,
  ) {
    final theme = Theme.of(context);
    
    String normalize(String name) {
      return name
          .toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('ö', 'o')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ç', 'c')
          .replaceAll('ğ', 'g')
          .replaceAll('&', 've')
          .replaceAll(',', '')
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    return categoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (shopCategories) {
        final Set<String> productCategories = {};
        if (allProductsAsync.hasValue) {
          for (var bp in allProductsAsync.value!) {
            productCategories.add(normalize(bp.product.category));
          }
        }

        final activeShopCategories = shopCategories.where(
          (c) => productCategories.contains(normalize(c.name))
        ).toList();

        final List<ShopCategoryData> listCategories = [
          ShopCategoryData(
            id: 'all',
            name: 'Tümü',
            iconName: 'grid_view',
            subCategories: [],
          ),
          ...activeShopCategories
        ];

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: listCategories.length,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemBuilder: (context, index) {
            final cat = listCategories[index];
            final isSelected = cat.name == selectedCategory;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                selected: isSelected,
                label: Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selectedColor: theme.primaryColor,
                backgroundColor: theme.colorScheme.surface,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(selectedCatalogCategoryProvider.notifier).state = cat.name;
                    ref.read(selectedCatalogSubCategoryProvider.notifier).state = 'Tümü';
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedCatalogCategoryProvider);
    final selectedSubCategory = ref.watch(selectedCatalogSubCategoryProvider);
    final selectedSortOption = ref.watch(selectedCatalogSortOptionProvider);
    final searchQuery = ref.watch(catalogSearchQueryProvider);

    final productsAsync = ref.watch(filteredShopProductsProvider(widget.shop.id));
    final allProductsAsync = ref.watch(shopProductsProvider(widget.shop.id));
    final categoriesAsync = ref.watch(shopCategoriesProvider(widget.shop.id));

    String normalize(String name) {
      return name
          .toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('ö', 'o')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ç', 'c')
          .replaceAll('ğ', 'g')
          .replaceAll('&', 've')
          .replaceAll(',', '')
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    List<String> currentSubCategories = [];
    if (selectedCategory != 'Tümü' && categoriesAsync.hasValue) {
      final matchingCat = categoriesAsync.value!.firstWhere(
        (c) => normalize(c.name) == normalize(selectedCategory),
        orElse: () => ShopCategoryData(id: '', name: '', iconName: '', subCategories: []),
      );
      
      final String normSelectedCategory = normalize(selectedCategory);
      final Set<String> productSubCategories = {};
      if (allProductsAsync.hasValue) {
        for (var bp in allProductsAsync.value!) {
          if (normalize(bp.product.category) == normSelectedCategory) {
            productSubCategories.add(normalize(bp.product.subCategory));
          }
        }
      }
      
      currentSubCategories = matchingCat.subCategories.where(
        (sub) => sub == 'Tümü' || productSubCategories.contains(normalize(sub))
      ).toList();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final metrics = notification.metrics;
              final bool show = metrics.pixels > 300.0;
              if (show != _showScrollToTop) {
                setState(() {
                  _showScrollToTop = show;
                });
              }

              // Scroll detection for mini categories
              if (notification is ScrollUpdateNotification) {
                final double pixels = metrics.pixels;

                if (pixels >= 145.0) {
                  if (!_showMiniCategories) {
                    setState(() => _showMiniCategories = true);
                  }
                } else {
                  if (_showMiniCategories) {
                    setState(() => _showMiniCategories = false);
                  }
                }
              }
              return false;
            },
            child: NestedScrollView(
              controller: _scrollController,
              floatHeaderSlivers: false,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              expandedHeight: 145.0,
              backgroundColor: theme.primaryColor,
              elevation: innerBoxIsScrolled ? 4 : 0,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  p.Provider.of<BusinessProvider>(context, listen: false).clearBusiness();
                },
              ),
              title: innerBoxIsScrolled
                  ? GestureDetector(
                      onTap: _changeBusiness,
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: widget.shop.logoUrl.isNotEmpty
                                  ? Image.network(
                                      widget.shop.logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.store,
                                        size: 14,
                                        color: theme.primaryColor,
                                      ),
                                    )
                                  : Icon(
                                      Icons.store,
                                      size: 14,
                                      color: theme.primaryColor,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                Text(
                                  "Min: ₺${widget.shop.minBasketAmount.toStringAsFixed(0)} • Teslimat: ₺${widget.shop.baseDeliveryFee.toStringAsFixed(0)} • Değiştir",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
              actions: const [
                CartPriceBadge(),
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
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                           Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.5),
                              child: widget.shop.logoUrl.isNotEmpty
                                  ? Image.network(
                                      widget.shop.logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.store,
                                        color: theme.colorScheme.primary,
                                        size: 24,
                                      ),
                                    )
                                  : Icon(
                                      Icons.store,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.shop.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      "${widget.shop.averageRating.toStringAsFixed(1)} (${widget.shop.reviewCount}) • Min: ₺${widget.shop.minBasketAmount.toStringAsFixed(0)} • Teslimat: ₺${widget.shop.baseDeliveryFee.toStringAsFixed(0)} • ${widget.shop.openingTime}-${widget.shop.closingTime}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black45,
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
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
                  ],
                ),
              ),
            ),
          ];
        },
        body: CustomScrollView(
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
                      hintText: "Bu mağazada ara...",
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

            // Active Order card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ActiveOrderCard(businessId: widget.shop.id),
              ),
            ),

            // Categories list
            SliverToBoxAdapter(
              child: Container(
                height: 104,
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Icon(Icons.error_outline, color: Colors.red),
                  ),
                  data: (shopCategories) {
                    final Set<String> productCategories = {};
                    if (allProductsAsync.hasValue) {
                      for (var bp in allProductsAsync.value!) {
                        productCategories.add(normalize(bp.product.category));
                      }
                    }

                    final activeShopCategories = shopCategories.where(
                      (c) => productCategories.contains(normalize(c.name))
                    ).toList();

                    final List<ShopCategoryData> listCategories = [
                      ShopCategoryData(
                        id: 'all',
                        name: 'Tümü',
                        iconName: 'grid_view',
                        subCategories: [],
                      ),
                      ...activeShopCategories
                    ];

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: listCategories.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, index) {
                        final cat = listCategories[index];
                        final isSelected = cat.name == selectedCategory;
                        final hasImage = cat.backgroundImage != null && cat.backgroundImage!.isNotEmpty;

                        return GestureDetector(
                          onTap: () {
                            ref.read(selectedCatalogCategoryProvider.notifier).state = cat.name;
                            ref.read(selectedCatalogSubCategoryProvider.notifier).state = 'Tümü';
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? theme.primaryColor : Colors.grey.shade200,
                                      width: 1.5,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: hasImage
                                        ? Image.network(
                                            cat.backgroundImage!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                cat.name == 'Tümü'
                                                    ? Icons.grid_view_rounded
                                                    : _getCategoryIcon(cat.iconName),
                                                size: 20,
                                                color: isSelected ? theme.primaryColor : Colors.grey,
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey.shade100,
                                            child: Icon(
                                              cat.name == 'Tümü'
                                                  ? Icons.grid_view_rounded
                                                  : _getCategoryIcon(cat.iconName),
                                              size: 20,
                                              color: isSelected ? theme.primaryColor : Colors.grey,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    cat.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface,
                                    ),
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
            ),

            // Subcategories list
            if (selectedCategory != 'Tümü' && currentSubCategories.isNotEmpty && searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  height: 44,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: currentSubCategories.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final subCat = currentSubCategories[index];
                      final isSelected = subCat == selectedSubCategory;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          selected: isSelected,
                          label: Text(
                            subCat,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selectedColor: theme.primaryColor,
                          backgroundColor: theme.colorScheme.surface,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(selectedCatalogSubCategoryProvider.notifier).state = subCat;
                            }
                          },
                        ),
                      );
                    },
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
                                child: CampaignCarousel(
                                  campaigns: campaigns,
                                  allShopProducts: allProductsAsync.value ?? [],
                                ),
                              );
                            },
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
          ),
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top, // Right below the collapsed App Bar
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showMiniCategories,
              child: AnimatedSlide(
                offset: _showMiniCategories ? Offset.zero : const Offset(0, -1.2),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _showMiniCategories ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildMiniCategoriesList(
                      context,
                      ref,
                      categoriesAsync,
                      allProductsAsync,
                      selectedCategory,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              mini: true,
              backgroundColor: theme.primaryColor,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }
}

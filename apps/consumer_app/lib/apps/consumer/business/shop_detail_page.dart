import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:consumer_app/apps/consumer/business/business_provider.dart';
import 'package:core_shared/shared/models/business.dart';
import 'package:core_shared/shared/models/business_product.dart';
import 'package:consumer_app/apps/consumer/cart/cart_provider.dart';
import 'package:consumer_app/apps/consumer/cart/widgets/cart_price_badge.dart';
import 'package:consumer_app/apps/consumer/home/widgets/modern_product_card.dart';
import 'package:consumer_app/apps/consumer/orders/widgets/active_order_card.dart';
import 'package:consumer_app/apps/consumer/product/product_detail_page.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:core_shared/shared/models/shop_category_data.dart';
import 'package:consumer_app/apps/consumer/home/widgets/campaign_carousel.dart';
import 'package:consumer_app/apps/consumer/widgets/shop_badge.dart';
import 'package:share_plus/share_plus.dart';
import 'package:core_shared/shared/models/campaign.dart';
import 'package:consumer_app/apps/consumer/business/campaign_products_page.dart';
import 'package:consumer_app/apps/consumer/business/widgets/food_product_customization_sheet.dart';
import 'package:consumer_app/apps/consumer/main_layout/voice_assistant_dialog.dart';

class ModernShopDetailPage extends ConsumerStatefulWidget {
  final Business shop;
  const ModernShopDetailPage({super.key, required this.shop});

  @override
  ConsumerState<ModernShopDetailPage> createState() => _ModernShopDetailPageState();
}

class _ModernShopDetailPageState extends ConsumerState<ModernShopDetailPage> {
  int _crossAxisCount = 2;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _miniCategoryScrollController = ScrollController();
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
    _scrollController.addListener(_onScrollChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      p.Provider.of<BusinessProvider>(context, listen: false).selectBusiness(widget.shop);
      if (widget.shop.type.label == 'Çiçek') {
        ref.read(selectedCatalogCategoryProvider.notifier).state = 'Çiçek';
      }
    });
  }

  void _onScrollChange() {
    if (!_scrollController.hasClients) return;
    final double pixels = _scrollController.offset;
    final bool showMini = pixels >= 145.0;
    if (showMini != _showMiniCategories) {
      setState(() => _showMiniCategories = showMini);
    }
    final bool showTop = pixels > 300.0;
    if (showTop != _showScrollToTop) {
      setState(() => _showScrollToTop = showTop);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChange);
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _miniCategoryScrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(int index) {
    if (!_categoryScrollController.hasClients) return;
    const double itemWidth = 92.0; // 80 width + 12 horizontal margin
    const double paddingLeft = 12.0;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double itemCenter = paddingLeft + (index * itemWidth) + (itemWidth / 2);
    double targetOffset = itemCenter - (screenWidth / 2);

    final double maxScroll = _categoryScrollController.position.maxScrollExtent;
    targetOffset = targetOffset.clamp(0.0, maxScroll);

    _categoryScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToMiniCategory(int index) {
    if (!_miniCategoryScrollController.hasClients) return;
    const double approxChipWidth = 95.0;
    const double paddingLeft = 12.0;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double itemCenter = paddingLeft + (index * approxChipWidth) + (approxChipWidth / 2);
    double targetOffset = itemCenter - (screenWidth / 2);

    final double maxScroll = _miniCategoryScrollController.position.maxScrollExtent;
    targetOffset = targetOffset.clamp(0.0, maxScroll);

    _miniCategoryScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
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
    ref.read(selectedCatalogCategoryProvider.notifier).state = 'Tümü';
    ref.read(selectedCatalogSubCategoryProvider.notifier).state = 'Tümü';
    ref.read(selectedCatalogSortOptionProvider.notifier).state = 'Önerilen';
    ref.read(catalogSearchQueryProvider.notifier).state = '';
    p.Provider.of<BusinessProvider>(
      context,
      listen: false,
    ).clearBusiness();
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
          controller: _miniCategoryScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: listCategories.length,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemBuilder: (context, index) {
            final cat = listCategories[index];
            final isSelected = cat.name == selectedCategory;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                selected: isSelected,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                label: Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white : const Color(0xFFE95D22),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                selectedColor: const Color(0xFFE95D22),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? const Color(0xFFE95D22) : Colors.grey.shade300,
                ),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(selectedCatalogCategoryProvider.notifier).state = cat.name;
                    ref.read(selectedCatalogSubCategoryProvider.notifier).state = 'Tümü';
                    _scrollToCategory(index);
                    _scrollToMiniCategory(index);
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
    final activeShopCampaignsAsync = ref.watch(activeShopCampaignsProvider);
    final activeShopCampaigns = activeShopCampaignsAsync.value ?? [];
    final currentShopCampaigns = activeShopCampaigns.where((c) => c['shopId'] == widget.shop.id && c['targetArea'] == "SHOP_DETAIL").toList();

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

    ref.listen(selectedCatalogCategoryProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final double pixels = _scrollController.offset;
          final bool showMini = pixels >= 145.0;
          if (showMini != _showMiniCategories) {
            setState(() => _showMiniCategories = showMini);
          }
        } else {
          if (_showMiniCategories) {
            setState(() => _showMiniCategories = false);
          }
        }
      });
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis != Axis.vertical) {
                return false;
              }
              final metrics = notification.metrics;
              final double pixels = metrics.pixels;

              final bool showTop = pixels > 300.0;
              if (showTop != _showScrollToTop) {
                setState(() => _showScrollToTop = showTop);
              }

              if (pixels >= 145.0) {
                if (!_showMiniCategories) {
                  setState(() => _showMiniCategories = true);
                }
              } else {
                if (_showMiniCategories) {
                  setState(() => _showMiniCategories = false);
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
              backgroundColor: Colors.transparent,
              forceElevated: innerBoxIsScrolled,
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: "İşletmeyi Paylaş",
                  onPressed: () {
                    final text = "${widget.shop.name} Hoppa'da! 🚀\n"
                        "Hemen sipariş vermek için dükkanı görüntüle: https://hoppanow.com/shop/${widget.shop.id}";
                    Share.share(text);
                  },
                ),
                const CartPriceBadge(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF00A651),
                ),
              ],
              flexibleSpace: Stack(
                children: [
                  // Hoppa gradient base layer - visible when collapsed
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFE95D22), // Hoppa Orange
                          Color(0xFFFF8C00), // Orange-Yellow (lighter)
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  // Expanded content (shop image) - fades out on collapse
                  FlexibleSpaceBar(
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
                                        Expanded(
                                          child: Text(
                                            widget.shop.reviewCount == 0
                                                ? "Değerlendirme Yok • Min: ₺${widget.shop.minBasketAmount.toStringAsFixed(0)} • Teslimat: ₺${widget.shop.baseDeliveryFee.toStringAsFixed(0)} • ${widget.shop.openingTime}-${widget.shop.closingTime}"
                                                : "${widget.shop.averageRating.toStringAsFixed(1)} (${widget.shop.reviewCount}) • Min: ₺${widget.shop.minBasketAmount.toStringAsFixed(0)} • Teslimat: ₺${widget.shop.baseDeliveryFee.toStringAsFixed(0)} • ${widget.shop.openingTime}-${widget.shop.closingTime}",
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
                                            overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
          ];
        },
        body: Stack(
          children: [
            Container(
              color: theme.scaffoldBackgroundColor,
              child: CustomScrollView(
                slivers: [
                  // Shop Campaign Banner
                  if (currentShopCampaigns.isNotEmpty) ...[
                    for (final c in currentShopCampaigns)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
                          child: InkWell(
                            onTap: () {
                              final double discountVal = c['discountValue'] != null ? double.tryParse(c['discountValue'].toString()) ?? 0.0 : 0.0;
                              final targetProducts = c['targetProducts'] != null ? List<String>.from(c['targetProducts'] as List) : <String>[];
                              final campaignObj = Campaign(
                                id: c['id']?.toString() ?? '',
                                vendorId: widget.shop.id,
                                name: c['title'] ?? 'Dükkan Kampanyası',
                                description: c['description'] ?? '',
                                type: CampaignType.percentage,
                          discountValue: discountVal,
                          startDate: DateTime.tryParse(c['createdAt']?.toString() ?? '') ?? DateTime.now(),
                          endDate: DateTime.now().add(const Duration(days: 30)),
                          imageUrl: c['imageUrl'] ?? '',
                          targetProducts: targetProducts,
                          isActive: c['isActive'] ?? true,
                        );
                        
                        final allProducts = ref.read(shopProductsProvider(widget.shop.id)).value ?? [];
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CampaignProductsPage(
                              campaign: campaignObj,
                              allShopProducts: allProducts,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(c['imageUrl'] ?? ''),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['title'] ?? 'Kampanya',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (c['description'] != null && c['description'].toString().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  c['description'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ] else if (widget.shop.campaignText != null && widget.shop.campaignText!.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF7E40),
                        Color(0xFFFF5200),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5200).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "MAĞAZA KAMPANYASI",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.shop.campaignText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Shop Badges / Tags (placed modernly between header and search bar)
            if (widget.shop.allowedFulfillmentModels.isNotEmpty || widget.shop.tags.isNotEmpty)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      ...widget.shop.allowedFulfillmentModels.map((model) {
                        String label = "";
                        if (model == 'PLATFORM_DELIVERY') {
                          label = "Hoppa Kuryesi";
                        } else if (model == 'SELF_DELIVERY') {
                          label = "Esnaf Teslimatı";
                        } else if (model == 'PICKUP') {
                          label = "Gel-Al";
                        }
                        if (label.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ShopBadge(label: label, isOnImage: false),
                        );
                      }),
                      ...widget.shop.tags.map((tag) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ShopBadge(label: tag, isOnImage: false),
                          )),
                    ],
                  ),
                ),
              ),
            // Search Input
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
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
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => const VoiceAssistantDialog(),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE95D22).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            color: Color(0xFFE95D22),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
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

            // Sticky Category Bar inside downward curved container
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyCategoryHeaderDelegate(
                builder: (context, isPinned) => Container(
                  height: 104,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const Center(
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
                        controller: _categoryScrollController,
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
                              _scrollToCategory(index);
                              _scrollToMiniCategory(index);
                            },
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF00A651)
                                            : (isPinned ? Colors.white30 : Colors.grey.shade200),
                                        width: isSelected ? 2.5 : 1.0,
                                      ),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
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
                                                  color: isSelected ? const Color(0xFF00A651) : theme.primaryColor,
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
                                                color: isSelected ? const Color(0xFF00A651) : theme.primaryColor,
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
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isPinned
                                            ? (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9))
                                            : (isSelected ? const Color(0xFF00A651) : theme.colorScheme.onSurface),
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

                  // Popüler Lezzetler / Çok Satanlar Vitrini (Tümü seçiliyken)
                  if (selectedCategory == 'Tümü' && searchQuery.isEmpty && allProductsAsync.hasValue)
                    SliverToBoxAdapter(
                      child: _buildPopularSection(allProductsAsync.value ?? []),
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
                                : (_crossAxisCount == 2 ? 0.69 : 0.62),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = filteredProducts[index];
                              return GestureDetector(
                                onTap: () {
                                  if (product.product.optionGroups.isNotEmpty) {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (ctx) => FoodProductCustomizationSheet(
                                        product: product.product,
                                        onAddToCart: (prod, options, qty) {
                                          ref.read(cartProvider.notifier).addToCartWithOptions(
                                            product,
                                            options,
                                            qty.toDouble(),
                                          );
                                        },
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailPage(businessProduct: product),
                                      ),
                                    );
                                  }
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
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE95D22),
                          Color(0xFFFF8C00),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE95D22).withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
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
            ),
          ),
        ],
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

  Widget _buildPopularSection(List<BusinessProduct> allProducts) {
    if (allProducts.isEmpty) return const SizedBox.shrink();

    // Filtrele: Opsiyonlu, menü veya popüler ürünler
    final popularList = allProducts.where((p) => 
      p.product.optionGroups.isNotEmpty || 
      p.product.category.toLowerCase().contains('popüler') ||
      p.product.category.toLowerCase().contains('menü') ||
      p.product.category.toLowerCase().contains('burger') ||
      p.product.category.toLowerCase().contains('pizza')
    ).take(8).toList();

    final displayList = popularList.isNotEmpty ? popularList : allProducts.take(5).toList();
    if (displayList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF6B00), size: 18),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Popüler Lezzetler",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "İşletmenin en çok tercih edilenleri",
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final bp = displayList[index];
              return Container(
                width: 155,
                margin: const EdgeInsets.only(right: 10, bottom: 6),
                child: GestureDetector(
                  onTap: () {
                    if (bp.product.optionGroups.isNotEmpty) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => FoodProductCustomizationSheet(
                          product: bp.product,
                          onAddToCart: (prod, options, qty) {
                            ref.read(cartProvider.notifier).addToCartWithOptions(
                              bp,
                              options,
                              qty.toDouble(),
                            );
                          },
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailPage(businessProduct: bp),
                        ),
                      );
                    }
                  },
                  child: ModernProductCard(
                    businessProduct: bp,
                    isListView: false,
                    isCompact: true,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget Function(BuildContext context, bool isPinned) builder;

  _StickyCategoryHeaderDelegate({required this.builder});

  @override
  double get minExtent => 104.0;

  @override
  double get maxExtent => 104.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double progress = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    final isPinned = overlapsContent || shrinkOffset > 5;
    final double curveRadius = isPinned ? 24.0 : (24.0 * progress);

    return Container(
      decoration: BoxDecoration(
        gradient: isPinned
            ? const LinearGradient(
                colors: [
                  Color(0xFFE95D22),
                  Color(0xFFFF8C00),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isPinned ? null : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(curveRadius),
          bottomRight: Radius.circular(curveRadius),
        ),
        boxShadow: isPinned
            ? [
                BoxShadow(
                  color: const Color(0xFFE95D22).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(curveRadius),
          bottomRight: Radius.circular(curveRadius),
        ),
        child: builder(context, isPinned),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCategoryHeaderDelegate oldDelegate) {
    return true;
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:google_fonts/google_fonts.dart';
import 'package:core_shared/shared/models/business.dart';
import 'package:core_shared/shared/models/business_type.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:consumer_app/apps/consumer/home/widgets/modern_product_card.dart';
import 'package:core_shared/shared/core/services/navigation_provider.dart';
import 'package:consumer_app/apps/consumer/business/business_provider.dart';
import 'package:consumer_app/apps/consumer/product/product_detail_page.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Listen to navigation changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      p.Provider.of<NavigationProvider>(
        context,
        listen: false,
      ).addListener(_onNavChange);
    });
  }

  void _onNavChange() {
    if (!mounted) return;
    final navProvider = p.Provider.of<NavigationProvider>(context, listen: false);
    if (navProvider.currentIndex == 1) {
      // Small delay to ensure visibility
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    // Clear the search query when leaving search page to not affect other views
    ref.read(catalogSearchQueryProvider.notifier).state = '';
    
    p.Provider.of<NavigationProvider>(
      context,
      listen: false,
    ).removeListener(_onNavChange);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getCategoryNameFromShopType(BusinessType type) {
    switch (type) {
      case BusinessType.restaurant:
        return 'Restoran';
      case BusinessType.market:
        return 'Market';
      case BusinessType.water:
        return 'Su';
      case BusinessType.florist:
        return 'Çiçek';
      case BusinessType.greengrocer:
        return 'Manav';
      case BusinessType.butcher:
        return 'Kasap';
      case BusinessType.nuts:
        return 'Kuruyemiş';
      case BusinessType.cafe:
        return 'Kahve';
      default:
        return 'Market';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE95D22), // Hoppa Orange
              Color(0xFFFF8C00), // Orange-Yellow
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          children: [
            HoppaHeader(
              height: 76,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Ürün, kategori veya dükkan ara...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 15),
                                onChanged: (value) {
                                  setState(() {
                                    _query = value;
                                  });
                                  ref.read(catalogSearchQueryProvider.notifier).state = value;
                                },
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _searchController.clear();
                                    _query = '';
                                  });
                                  ref.read(catalogSearchQueryProvider.notifier).state = '';
                                },
                                child: const Icon(Icons.clear, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
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
                  child: _buildSearchResults(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final businessProvider = p.Provider.of<BusinessProvider>(context, listen: false);
    final selectedBusiness = businessProvider.selectedBusiness;

    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            const Text(
              "Arama yapmak için yazmaya başlayın",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // --- CASE 1: BUSINESS SELECTED (Search inside business catalog) ---
    if (selectedBusiness != null) {
      final productsAsync = ref.watch(filteredShopProductsProvider(selectedBusiness.id));

      return productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(
          child: Text(
            "Ürünler yüklenirken bir hata oluştu.",
            style: TextStyle(color: Colors.red),
          ),
        ),
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  const Text(
                    "Sonuç bulunamadı.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = results[index];

              return SizedBox(
                height: 120,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailPage(businessProduct: product),
                      ),
                    );
                  },
                  child: ModernProductCard(
                    businessProduct: product,
                    isListView: true,
                    campaign: null,
                  ),
                ),
              );
            },
          );
        },
      );
    }

    // --- CASE 2: GLOBAL SEARCH (Search categories, shops, and products globally) ---
    final searchAsync = ref.watch(globalSearchProvider);

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Center(
        child: Text(
          "Arama sonuçları yüklenirken bir hata oluştu.",
          style: TextStyle(color: Colors.red),
        ),
      ),
      data: (results) {
        final hasCats = results.categories.isNotEmpty;
        final hasShops = results.shops.isNotEmpty;
        final hasProds = results.products.isNotEmpty;

        if (!hasCats && !hasShops && !hasProds) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                const Text(
                  "Sonuç bulunamadı.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. KATEGORİLER
            if (hasCats) ...[
              Text(
                "Kategoriler",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: results.categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = results.categories[index];
                    return ActionChip(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.grey.shade50,
                      side: BorderSide(color: Colors.grey.shade200),
                      label: Text(
                        cat.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      onPressed: () {
                        // Kategoriye git
                        businessProvider.setCategory(cat.name);
                        p.Provider.of<NavigationProvider>(context, listen: false).setIndex(0);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 2. İŞLETMELER
            if (hasShops) ...[
              Text(
                "İşletmeler",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.shops.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final shop = results.shops[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade100),
                    ),
                    tileColor: Colors.grey.shade50,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        shop.logoUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.store, color: Colors.grey),
                        ),
                      ),
                    ),
                    title: Text(
                      shop.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          shop.averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time, color: Colors.grey, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          "${shop.deliveryRadius.toStringAsFixed(0)} km",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Dükkana git
                      final String typeName = _getCategoryNameFromShopType(shop.type);
                      businessProvider.setCategory(typeName);
                      businessProvider.selectBusiness(shop);
                      p.Provider.of<NavigationProvider>(context, listen: false).setIndex(0);
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // 3. ÜRÜNLER
            if (hasProds) ...[
              Text(
                "Ürünler",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.products.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = results.products[index];
                  return SizedBox(
                    height: 120,
                    child: GestureDetector(
                      onTap: () {
                        // Ürünün ait olduğu dükkanı bulalım
                        final shop = results.shops.firstWhere(
                          (s) => s.id == product.businessId,
                          orElse: () => Business.fromMap({
                            'name': 'İşletme',
                            'imageUrl': 'https://via.placeholder.com/150',
                            'headerImageUrl': 'https://via.placeholder.com/150',
                            'minOrderAmount': 0,
                            'deliveryRadiusKm': 5,
                            'averageRating': 5,
                            'reviewCount': 0,
                            'type': 'market',
                            'isActive': true,
                          }, product.businessId),
                        );
                        final String typeName = _getCategoryNameFromShopType(shop.type);
                        businessProvider.setCategory(typeName);
                        businessProvider.selectBusiness(shop);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(businessProduct: product),
                          ),
                        );
                      },
                      child: ModernProductCard(
                        businessProduct: product,
                        isListView: true,
                        campaign: null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:hoppa/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:hoppa/apps/consumer/home/widgets/modern_product_card.dart';
import 'package:hoppa/shared/core/services/navigation_provider.dart';
import 'package:hoppa/apps/consumer/business/business_provider.dart';
import 'package:hoppa/apps/consumer/product/product_detail_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.search, color: Colors.grey),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ürün, kategori veya marka ara...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16),
          onChanged: (value) {
            setState(() {
              _query = value;
            });
            ref.read(catalogSearchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _query = '';
                });
                ref.read(catalogSearchQueryProvider.notifier).state = '';
              },
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    final businessProvider = p.Provider.of<BusinessProvider>(context, listen: false);
    final selectedBusiness = businessProvider.selectedBusiness;

    if (selectedBusiness == null) {
      return const Center(
        child: Text(
          "Lütfen önce bir işletme seçin.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

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
}

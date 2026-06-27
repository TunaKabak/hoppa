import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:hoppa/apps/consumer/cart/cart_provider.dart';
import 'package:hoppa/shared/core/services/navigation_provider.dart';
import 'package:hoppa/apps/consumer/business/business_provider.dart';
import 'package:hoppa/apps/consumer/business/business_selection_page.dart';
import 'package:hoppa/apps/consumer/business/selection_category_page.dart';
import 'package:hoppa/apps/consumer/cart/widgets/cart_price_badge.dart';
import 'package:hoppa/apps/consumer/home/widgets/modern_product_card.dart';
import 'package:hoppa/apps/consumer/orders/widgets/active_order_card.dart';
import 'package:hoppa/apps/consumer/product/product_detail_page.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:hoppa/shared/models/shop_category_data.dart';


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _subCategoryScrollController = ScrollController();

  List<GlobalKey> _subCategoryKeys = [];

  int _crossAxisCount = 2;

  final List<String> _sortOptions = [
    'Önerilen',
    'Fiyat Artan',
    'Fiyat Azalan',
    'İsim A-Z',
    'İsim Z-A',
  ];

  // Market Kategorileri
  final List<Map<String, dynamic>> _marketCategories = [
    {'name': 'Tümü', 'icon': Icons.grid_view},
    {'name': 'Su & İçecek', 'icon': Icons.water_drop},
    {'name': 'Meyve & Sebze', 'icon': Icons.apple},
    {'name': 'Atıştırmalık', 'icon': Icons.cookie},
    {'name': 'Fırın', 'icon': Icons.breakfast_dining},
    {'name': 'Temel Gıda', 'icon': Icons.rice_bowl},
    {'name': 'Süt & Kahvaltılık', 'icon': Icons.egg_alt},
    {'name': 'Temizlik', 'icon': Icons.cleaning_services},
    {'name': 'Çiçek', 'icon': Icons.local_florist},
  ];

  // Çiçekçi Kategorileri (Aslında alt kategoriler ama üstte gösterilecek)
  final List<Map<String, dynamic>> _floristCategories = [
    {'name': 'Tümü', 'icon': Icons.grid_view},
    {'name': 'Buket', 'icon': Icons.local_florist},
    {'name': 'Saksı', 'icon': Icons.grass},
    {'name': 'Aranjman', 'icon': Icons.redeem},
    {'name': 'Çelenk', 'icon': Icons.circle_outlined}, // Çelenk ikonu
  ];

  final Map<String, List<String>> _subCategoriesMap = {
    'Su & İçecek': [
      'Tümü',
      'Su',
      'Gazlı İçecek',
      'Soğuk Çay & Kahve',
      'Meyve Suyu',
      'Maden Suyu',
      'Enerji',
      'Ayran & Şalgam',
      'Kahve',
    ],
    'Meyve & Sebze': ['Tümü', 'Meyve', 'Sebze'],
    'Atıştırmalık': [
      'Tümü',
      'Cips',
      'Çikolata & Gofret',
      'Bisküvi & Kek',
      'Kuruyemiş',
      'Şekerleme',
    ],
    'Fırın': ['Tümü', 'Ekmek', 'Unlu Mamül'],
    'Temel Gıda': [
      'Tümü',
      'Sıvı Yağ',
      'Bakliyat',
      'Makarna',
      'Salça & Sos',
      'Şeker & Tuz',
      'Un & İrmik',
      'Çay & Kahve',
      'Konserve',
    ],
    'Süt & Kahvaltılık': [
      'Tümü',
      'Süt',
      'Peynir',
      'Kahvaltılık',
      'Şarküteri',
      'Yoğurt',
      'Yumurta',
    ],
    'Temizlik': [
      'Tümü',
      'Genel Temizlik',
      'Bulaşık',
      'Çamaşır',
      'Kağıt Ürünler',
      'Oda Kokusu',
      'Çöp Torbası',
    ],
    'Çiçek': ['Tümü', 'Buket', 'Saksı', 'Aranjman'],
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessProvider = p.Provider.of<BusinessProvider>(
        context,
        listen: false,
      );
      if (businessProvider.selectedBusiness != null) {
        // Eğer Çiçekçi ise varsayılan kategori 'Çiçek' olmalı
        if (businessProvider.selectedBusiness!.type.label == 'Çiçek') {
          ref.read(selectedCatalogCategoryProvider.notifier).state = 'Çiçek';
        }
      }
    });

    _scrollController.addListener(_onScroll);
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

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _subCategoryScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Update _isScrolled based on scroll offset
    final bool previousScrolled = _isScrolled;
    _isScrolled =
        _scrollController.offset >
        kToolbarHeight; // kToolbarHeight is AppBar default height

    if (previousScrolled != _isScrolled) {
      setState(() {});
    }
  }

  void _onCategorySelected(int index, String categoryName) {
    ref.read(selectedCatalogCategoryProvider.notifier).state = categoryName;
    ref.read(selectedCatalogSubCategoryProvider.notifier).state = 'Tümü';

    _scrollToCenter(_categoryScrollController, index, 83.0);

    if (_subCategoryScrollController.hasClients) {
      _subCategoryScrollController.jumpTo(0);
    }
  }

  void _onSubCategorySelected(int index, String subCategory) {
    ref.read(selectedCatalogSubCategoryProvider.notifier).state = subCategory;

    if (index < _subCategoryKeys.length &&
        _subCategoryKeys[index].currentContext != null) {
      Scrollable.ensureVisible(
        _subCategoryKeys[index].currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToCenter(
    ScrollController controller,
    int index,
    double itemWidth,
  ) {
    if (!controller.hasClients) return;
    double screenWidth = MediaQuery.of(context).size.width;
    double targetOffset =
        (index * itemWidth) + (itemWidth / 2) - (screenWidth / 2);
    double maxScroll = controller.position.maxScrollExtent;
    if (targetOffset < 0) targetOffset = 0;
    if (targetOffset > maxScroll) targetOffset = maxScroll;
    controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _changeGrid(int count) {
    setState(() => _crossAxisCount = count);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final businessProvider = p.Provider.of<BusinessProvider>(context);

    // 1. KATEGORİ SEÇİLMEDİYSE -> KATEGORİ SAYFASI
    if (businessProvider.selectedCategory == null) {
      return const SelectionCategoryPage();
    }

    // 2. İŞLETME SEÇİLMEDİYSE -> İŞLETME LİSTESİ (KATEGORİYE GÖRE)
    if (businessProvider.selectedBusiness == null) {
      return BusinessSelectionPage(category: businessProvider.selectedCategory);
    }

    // 3. İŞLETME SEÇİLDİYSE -> ÜRÜN LİSTESİ (MEVCUT HOME)
    final selectedBusiness = businessProvider.selectedBusiness!;
    final productsAsync = ref.watch(filteredShopProductsProvider(selectedBusiness.id));
    final categoriesAsync = ref.watch(shopCategoriesProvider(selectedBusiness.id));

    return categoriesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text("Kategoriler yüklenirken hata oluştu: $err")),
      ),
      data: (shopCategories) {
        final theme = Theme.of(context);

        final selectedCategory = ref.watch(selectedCatalogCategoryProvider);
        final selectedSubCategory = ref.watch(selectedCatalogSubCategoryProvider);
        final selectedSortOption = ref.watch(selectedCatalogSortOptionProvider);

        List<String> currentSubCategories = [];
        if (selectedCategory != 'Tümü') {
          final matchingCat = shopCategories.firstWhere(
            (c) => c.name == selectedCategory,
            orElse: () => ShopCategoryData(id: '', name: '', iconName: '', subCategories: []),
          );
          currentSubCategories = matchingCat.subCategories;
        }

        if (_subCategoryKeys.length != currentSubCategories.length) {
          _subCategoryKeys = List.generate(
            currentSubCategories.length,
            (_) => GlobalKey(),
          );
        }

    // Klavye dışına tıklayınca kapat
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 110.0,
              backgroundColor: Colors.white,
              elevation: 4, // Hafif gölge
              shadowColor: Colors.black12, // Gölge rengi
              surfaceTintColor: Colors.transparent,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              title: GestureDetector(
                onTap: _changeBusiness,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.store,
                        color: theme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Alışveriş Yapılan ${selectedBusiness.type.label}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  selectedBusiness.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                AnimatedOpacity(
                  opacity: _isScrolled ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: const CartPriceBadge(), // Live Cart Total
                ),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Henüz yeni bir bildiriminiz yok."),
                      ),
                    );
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            readOnly: true,
                            onTap: () {
                              p.Provider.of<NavigationProvider>(
                                context,
                                listen: false,
                              ).setIndex(1);
                            },
                            decoration: InputDecoration(
                              hintText: "Ürün, kategori veya marka ara...",
                              hintStyle: theme.inputDecorationTheme.hintStyle,
                              prefixIcon: IconButton(
                                icon: Icon(
                                  Icons.search,
                                  color: theme.primaryColor,
                                ),
                                onPressed: () {
                                  p.Provider.of<NavigationProvider>(
                                    context,
                                    listen: false,
                                  ).setIndex(1);
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Animasyonlu genişlik ve opaklık değişimi
                      // Animasyonlu genişlik değişimi
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: SizedBox(
                          width: _isScrolled ? null : 0,
                          child: _isScrolled
                              ? const Row(
                                  children: [
                                    SizedBox(width: 12),
                                    CartPriceBadge(),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!selectedBusiness.isOpen)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      color: Colors.orange.shade100,
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Bu işletme şu an kapalı. Ürünleri inceleyebilirsiniz ancak sipariş veremezsiniz.",
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.orange.shade900),
                                    const SizedBox(width: 4),
                                    Text(
                                      "İşletme Saatleri: ${selectedBusiness.openingTime} - ${selectedBusiness.closingTime}",
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
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

                  if (selectedCategory == 'Tümü' &&
                      false) // Disabled campaigns for REST API
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: SizedBox.shrink(),
                    ),

                  // Active Order Banner (Moved here)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: ActiveOrderCard(businessId: selectedBusiness.id),
                  ),

                  const SizedBox(height: 24),

                  // Dinamik Kategori Listesi
                  Builder(
                    builder: (context) {
                      final List<Map<String, dynamic>> categories = [
                        {'name': 'Tümü', 'icon': Icons.grid_view}
                      ];

                      for (final cat in shopCategories) {
                        categories.add({
                          'name': cat.name,
                          'icon': _getCategoryIcon(cat.iconName),
                        });
                      }

                      return SizedBox(
                        height: 100,
                        child: ListView.builder(
                          controller: _categoryScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final catName = cat['name'] as String;

                            final isSelected = catName == selectedCategory;

                            return _buildCategoryItem(cat, isSelected, index);
                          },
                        ),
                      );
                    },
                  ),

                  // Alt kategoriler
                  if (currentSubCategories.isNotEmpty)
                    Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: SingleChildScrollView(
                        controller: _subCategoryScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: List.generate(currentSubCategories.length, (
                            index,
                          ) {
                            final subCat = currentSubCategories[index];
                            final isSelected =
                                subCat == selectedSubCategory;
                            return GestureDetector(
                              key: _subCategoryKeys[index],
                              onTap: () =>
                                  _onSubCategorySelected(index, subCat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.primaryColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  subCat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[800],
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSortOption,
                              icon: const Icon(
                                Icons.sort,
                                size: 18,
                                color: Colors.grey,
                              ),
                              isDense: true,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
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
                  const SizedBox(height: 8),
                ],
              ),
            ),

            ...productsAsync.when(
              loading: () => const [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
              error: (err, stack) => const [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(
                      child: Text(
                        "Dükkanlar yüklenirken bir hata oluştu",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
              data: (filteredProducts) {
                if (filteredProducts.isEmpty) {
                  return const [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.grey),
                              SizedBox(height: 10),
                              Text(
                                "Bu kategoride ürün bulunamadı.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ];
                }

                return [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _crossAxisCount,
                        childAspectRatio: _crossAxisCount == 1
                            ? 2.8
                            : (_crossAxisCount == 2 ? 0.72 : 0.65),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = filteredProducts[index];

                        return GestureDetector(
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
                            isListView: _crossAxisCount == 1,
                            isCompact: _crossAxisCount > 2,
                            campaign: null,
                          ),
                        );
                      }, childCount: filteredProducts.length),
                    ),
                  ),
                ];
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
      },
    );
  }

  // --- Widget Helpers ---
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

  Widget _buildCategoryItem(
    Map<String, dynamic> cat,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _onCategorySelected(index, cat['name']),
      child: Container(
        width: 75,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : const Color(0xFFE9ECEF),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                cat['icon'],
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cat['name'],
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : const Color(0xFF212529),
              ),
            ),
          ],
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
}

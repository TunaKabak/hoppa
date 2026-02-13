import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoppa/features/cart/cart_provider.dart';
import 'package:hoppa/features/home/product_provider.dart';
import 'package:hoppa/core/services/navigation_provider.dart';
import 'package:hoppa/features/business/business_provider.dart';
import 'package:hoppa/features/business/business_selection_page.dart';
import 'package:hoppa/features/business/selection_category_page.dart';
import 'package:hoppa/features/cart/widgets/cart_price_badge.dart';
import 'package:hoppa/features/home/widgets/modern_product_card.dart';
import 'package:hoppa/features/home/widgets/promo_slider.dart';
import 'package:hoppa/features/orders/widgets/active_order_card.dart';
import 'package:hoppa/features/product/product_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _subCategoryScrollController = ScrollController();

  List<GlobalKey> _subCategoryKeys = [];

  int _crossAxisCount = 2;
  final String _sortOption = 'Önerilen';

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
      final businessProvider = Provider.of<BusinessProvider>(
        context,
        listen: false,
      );
      if (businessProvider.selectedBusiness != null) {
        // Eğer Çiçekçi ise varsayılan kategori 'Çiçek' olmalı
        if (businessProvider.selectedBusiness!.type.label == 'Çiçek') {
          Provider.of<ProductProvider>(
            context,
            listen: false,
          ).setCategory('Çiçek');
        }

        Provider.of<ProductProvider>(
          context,
          listen: false,
        ).fetchProducts(businessId: businessProvider.selectedBusiness!.id);
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
              Provider.of<CartProvider>(
                context,
                listen: false,
              ).clearCart(deleteFromDb: true);
              Provider.of<BusinessProvider>(
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

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final businessId = Provider.of<BusinessProvider>(
        context,
        listen: false,
      ).selectedBusiness?.id;
      if (businessId != null) {
        Provider.of<ProductProvider>(
          context,
          listen: false,
        ).fetchProducts(businessId: businessId);
      }
    }
  }

  void _onCategorySelected(int index, String categoryName) {
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final isFlorist = businessProvider.selectedBusiness?.type.label == 'Çiçek';

    if (isFlorist) {
      // Çiçekçi mantığı: Ana kategori hep 'Çiçek', üstteki butonlar alt kategoriyi seçer
      if (categoryName == 'Tümü') {
        // Tümü seçilirse SubCategory de Tümü olsun
        productProvider.setSubCategory('Tümü');
      } else {
        productProvider.setSubCategory(categoryName);
      }
      // Ana kategori Çiçek olarak kalmalı (init'te set ediliyor ama garanti olsun)
      if (productProvider.selectedCategory != 'Çiçek') {
        // Bu method subcategory'i sıfırlıyor o yüzden dikkatli kullanılmalı
        // Ancak biz zaten subcategory set ettik, o yüzden setCategory çağırırsak ezilir.
        // Doğru sıra: setCategory -> setSubCategory
        // Ama setCategory zaten sıfırlıyor.
        // O yüzden önce Category set edip sonra SubCategory set etmeliyiz.
        // Fakat UI'da zaten Çiçek seçili varsayıyoruz.
      }
    } else {
      // Market mantığı: Normal kategori seçimi
      productProvider.setCategory(categoryName);
    }

    // FETCH TRIGGER
    final businessId = businessProvider.selectedBusiness?.id;
    if (businessId != null) {
      productProvider.fetchProducts(businessId: businessId);
    }

    _scrollToCenter(_categoryScrollController, index, 83.0);

    // Çiçekçide alt kategori barı gösterilmeyecek, o yüzden scroll reset'e gerek yok
    if (!isFlorist && _subCategoryScrollController.hasClients) {
      _subCategoryScrollController.jumpTo(0);
    }
  }

  void _onSubCategorySelected(int index, String subCategory) {
    Provider.of<ProductProvider>(
      context,
      listen: false,
    ).setSubCategory(subCategory);

    // FETCH TRIGGER
    final businessId = Provider.of<BusinessProvider>(
      context,
      listen: false,
    ).selectedBusiness?.id;
    if (businessId != null) {
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).fetchProducts(businessId: businessId);
    }
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
    final businessProvider = Provider.of<BusinessProvider>(context);

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
    final productProvider = Provider.of<ProductProvider>(context);
    final theme = Theme.of(context);

    List<String> currentSubCategories =
        _subCategoriesMap[productProvider.selectedCategory] ?? [];

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
                        color: theme.primaryColor.withOpacity(0.1),
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
                              Provider.of<NavigationProvider>(
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
                                  Provider.of<NavigationProvider>(
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
                  if (productProvider.selectedCategory == 'Tümü')
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: PromoSlider(),
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
                      final isFlorist =
                          businessProvider.selectedBusiness?.type.label ==
                          'Çiçek';
                      final categories = isFlorist
                          ? _floristCategories
                          : _marketCategories;

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

                            bool isSelected;
                            if (isFlorist) {
                              // Çiçekçide: Tümü ise subCategory'nin Tümü olması,
                              // Diğerlerinde subCategory'nin eşleşmesi
                              if (catName == 'Tümü') {
                                isSelected =
                                    productProvider.selectedSubCategory ==
                                    'Tümü';
                              } else {
                                isSelected =
                                    productProvider.selectedSubCategory ==
                                    catName;
                              }
                            } else {
                              isSelected =
                                  catName == productProvider.selectedCategory;
                            }

                            return _buildCategoryItem(cat, isSelected, index);
                          },
                        ),
                      );
                    },
                  ),

                  // Alt kategoriler sadece Market modunda gösterilecek
                  if (currentSubCategories.isNotEmpty &&
                      businessProvider.selectedBusiness?.type.label != 'Çiçek')
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
                                subCat == productProvider.selectedSubCategory;
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
                                                .withOpacity(0.3),
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
                              value: productProvider.selectedSortOption,
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
                                  Provider.of<ProductProvider>(
                                    context,
                                    listen: false,
                                  ).setSortOption(newValue);

                                  // FETCH TRIGGER
                                  final businessId =
                                      Provider.of<BusinessProvider>(
                                        context,
                                        listen: false,
                                      ).selectedBusiness?.id;
                                  if (businessId != null) {
                                    Provider.of<ProductProvider>(
                                      context,
                                      listen: false,
                                    ).fetchProducts(businessId: businessId);
                                  }
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

            if (productProvider.products.isEmpty && !productProvider.isLoading)
              const SliverToBoxAdapter(
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
              )
            else
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
                    final product = productProvider.products[index];
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
                      ),
                    );
                  }, childCount: productProvider.products.length),
                ),
              ),

            if (productProvider.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
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
              ? theme.primaryColor.withOpacity(0.1)
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
                          ).primaryColor.withOpacity(0.3),
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
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:hoppa/apps/consumer/home/home_page.dart';
import 'package:hoppa/apps/consumer/cart/cart_page.dart';
import 'package:hoppa/apps/consumer/cart/cart_provider.dart';
import 'package:hoppa/apps/consumer/profile/profile_page.dart';
import 'package:hoppa/shared/core/services/navigation_provider.dart'; // YENİ

import 'package:hoppa/apps/consumer/business/business_provider.dart'; // YENİ
import 'package:hoppa/apps/consumer/home/search_page.dart';
import 'package:hoppa/apps/consumer/services/customer_auth_service.dart';

class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  final PageStorageBucket _bucket = PageStorageBucket();
  final GlobalKey<NavigatorState> _profileNavigatorKey =
      GlobalKey<NavigatorState>();

  // Sayfalar: Home, Search, Cart, Profile
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Sayfa (veya Key) değiştiğinde Sepeti Getir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<CustomerAuthService>(
        context,
        listen: false,
      );
      final userId = authService.currentUser?.uid;
      if (userId != null) {
        Provider.of<CartProvider>(context, listen: false).fetchCart(userId);
      }
    });
    _pages = [
      const HomePage(),
      const SearchPage(), // Search
      const CartPage(), // Cart
      Navigator(
        key: _profileNavigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(builder: (context) => const ProfilePage());
        },
      ),
    ];

    // Splash'ten sonra veya Oturum açıldığında her zaman Kategoriler (Ana Sayfa) ile başla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final navProvider = Provider.of<NavigationProvider>(
          context,
          listen: false,
        );
        // NOT: Business verilerini burada temizlememelisiniz.
        // Eğer MainLayoutPage yeniden oluşturulursa (örn: Auth değişikliği),
        // mevcut seçimlerin kaybolmasına neden olur.
        navProvider.setIndex(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final navProvider = Provider.of<NavigationProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final businessProvider = Provider.of<BusinessProvider>(context);

    // Seçili sekmeyi belirle
    int currentIndex = navProvider.currentIndex;

    // Alt menüyü göster/gizle: Ana Sayfa (0) ve Kategori Seçilmemişse GİZLE.
    bool showBottomBar =
        !(currentIndex == 0 && businessProvider.selectedCategory == null);

    // FAB Tıklanınca yapılacak işlem (Hoppa! - Ana Kategoriye Dön)
    void onFabPressed() {
      // 1. Kategoriyi ve Marketi sıfırla (Böylece HomePage -> SelectionCategoryPage moduna geçer)
      businessProvider.clearCategory();
      businessProvider.clearBusiness();

      // 2. Ana Sayfa (0) sekmesine git
      navProvider.setIndex(0);
    }

    // Eğer üstümüzde başka bir sayfa varsa (ör: ProductDetailPage),
    // normal pop davranışına izin ver
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;

    return PopScope(
      canPop: !isCurrentRoute,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. Profil Sekmesindeysek (Index 3)
        if (currentIndex == 3) {
          final profileNavigator = _profileNavigatorKey.currentState;
          // İç navigator geri gidebiliyorsa (örn: Siparişlerim -> Profil)
          if (profileNavigator != null && profileNavigator.canPop()) {
            profileNavigator.pop();
            return;
          }
        }

        // 2. Ana Sayfa sekmesinde (Index 0): state-driven ekranlar arasında geri git
        if (currentIndex == 0) {
          if (businessProvider.selectedBusiness != null) {
            // Ürün listesi -> İşletme seçimi
            businessProvider.clearBusiness();
            return;
          }
          if (businessProvider.selectedCategory != null) {
            // İşletme seçimi -> Kategori seçimi
            businessProvider.clearCategory();
            return;
          }
        }

        // 3. Ana Sayfada Değilsek -> Ana Sayfaya Git
        if (currentIndex != 0) {
          navProvider.setIndex(0);
          return;
        }

        // 4. Ana Sayfadayız ve kök kategori ekranındayız -> Uygulamadan Çık
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: PageStorage(
          bucket: _bucket,
          child: IndexedStack(index: currentIndex, children: _pages),
        ),
        bottomNavigationBar: showBottomBar
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: SizedBox(
                      height: 70,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            0,
                            Icons.home_outlined,
                            Icons.home,
                            "Ana Sayfa",
                            navProvider,
                            primaryColor,
                          ),
                          _buildNavItem(
                            1,
                            Icons.search,
                            Icons.search,
                            "Ara",
                            navProvider,
                            primaryColor,
                          ),

                          // ORTA BUTON (HOPPA)
                          GestureDetector(
                            onTap: onFabPressed,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),

                          _buildCartNavItem(
                            2,
                            "Sepetim",
                            navProvider,
                            cart,
                            primaryColor,
                          ),
                          _buildNavItem(
                            3,
                            Icons.person_outline,
                            Icons.person,
                            "Profil",
                            navProvider,
                            primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null, // Kategori seçiminde Null
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    NavigationProvider navProvider,
    Color activeColor,
  ) {
    bool isSelected = navProvider.currentIndex == index;
    return MaterialButton(
      minWidth: 40,
      onPressed: () => navProvider.setIndex(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? activeColor : Colors.grey,
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartNavItem(
    int index,
    String label,
    NavigationProvider navProvider,
    CartProvider cart,
    Color activeColor,
  ) {
    bool isSelected = navProvider.currentIndex == index;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    return MaterialButton(
      minWidth: 40,
      onPressed: () => navProvider.setIndex(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            isLabelVisible: cart.items.isNotEmpty,
            label: Text(
              '${cart.items.length}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: secondaryColor,
            child: Icon(
              isSelected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
              color: isSelected ? activeColor : Colors.grey,
              size: 26,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

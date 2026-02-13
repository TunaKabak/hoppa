import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:hoppa/features/home/home_page.dart';
import 'package:hoppa/features/cart/cart_page.dart';
import 'package:hoppa/features/cart/cart_provider.dart';
import 'package:hoppa/features/profile/profile_page.dart';
import 'package:hoppa/core/services/navigation_provider.dart'; // YENİ

import 'package:hoppa/features/business/business_provider.dart'; // YENİ
import 'package:hoppa/features/home/search_page.dart';
import 'package:hoppa/core/services/auth_service.dart';

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
      final authService = Provider.of<AuthService>(context, listen: false);
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
        final businessProvider = Provider.of<BusinessProvider>(
          context,
          listen: false,
        );

        navProvider.setIndex(0);
        businessProvider.clearCategory();
        businessProvider.clearBusiness();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

    return PopScope(
      canPop: false,
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

        // 2. Ana Sayfada Değilsek -> Ana Sayfaya Git
        if (currentIndex != 0) {
          navProvider.setIndex(0);
          return;
        }

        // 3. Ana Sayfadayız (Index 0) -> Uygulamadan Çık
        // SystemNavigator.pop() ile düzgün çıkış yap (Android)
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  // SafeArea for bottom padding
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: SizedBox(
                      height: 70, // Slightly taller to accommodate big button
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround, // Distribute evenly
                        children: [
                          _buildNavItem(
                            0,
                            Icons.home_outlined,
                            Icons.home,
                            "Ana Sayfa",
                            navProvider,
                          ),
                          _buildNavItem(
                            1,
                            Icons.search,
                            Icons.search,
                            "Ara",
                            navProvider,
                          ),

                          // ORTA BUTON (HOPPA)
                          GestureDetector(
                            onTap: onFabPressed,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A651),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00A651,
                                    ).withOpacity(0.3),
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

                          _buildCartNavItem(2, "Sepetim", navProvider, cart),
                          _buildNavItem(
                            3,
                            Icons.person_outline,
                            Icons.person,
                            "Profil",
                            navProvider,
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
            color: isSelected ? const Color(0xFF00A651) : Colors.grey,
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00A651) : Colors.grey,
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
  ) {
    bool isSelected = navProvider.currentIndex == index;
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
            backgroundColor: const Color(0xFFFF6B00),
            child: Icon(
              isSelected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
              color: isSelected ? const Color(0xFF00A651) : Colors.grey,
              size: 26,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00A651) : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

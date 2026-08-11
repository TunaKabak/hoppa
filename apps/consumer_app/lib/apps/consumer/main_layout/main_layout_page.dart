import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:provider/provider.dart' as p;
import 'package:consumer_app/apps/consumer/home/home_page.dart';
import 'package:consumer_app/apps/consumer/cart/cart_page.dart';
import 'package:consumer_app/apps/consumer/cart/cart_provider.dart';
import 'package:consumer_app/apps/consumer/profile/profile_page.dart';
import 'package:core_shared/shared/core/services/navigation_provider.dart';
import 'package:consumer_app/apps/consumer/providers/consumer_location_controller.dart';

import 'package:consumer_app/apps/consumer/business/business_provider.dart';
import 'package:consumer_app/apps/consumer/home/search_page.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_shared/shared/core/services/notification_service.dart';
import 'package:consumer_app/apps/consumer/main_layout/voice_assistant_dialog.dart';
import 'package:consumer_app/apps/consumer/main_layout/widgets/floating_bottom_bar.dart';
import 'package:consumer_app/apps/consumer/main_layout/controllers/floating_nav_controller.dart';

class MainLayoutPage extends ConsumerStatefulWidget {
  const MainLayoutPage({super.key});

  @override
  ConsumerState<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends ConsumerState<MainLayoutPage> {
  final PageStorageBucket _bucket = PageStorageBucket();
  final GlobalKey<NavigatorState> _profileNavigatorKey =
      GlobalKey<NavigatorState>();

  // Sayfalar: Home, Search, Cart, Profile
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
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
        final navProvider = p.Provider.of<NavigationProvider>(
          context,
          listen: false,
        );
        navProvider.setIndex(0);

        // Firebase Cloud Messaging ve Notification kurulumu
        final apiClient = ref.read(apiClientProvider);
        final notificationService = NotificationService(apiClient);
        notificationService.initialize();

        // Otomatik konum alma ve yetkilendirme
        ref.read(consumerLocationProvider.notifier).determineLocation().catchError((e) {
          debugPrint("Startup location retrieval failed: $e");
          return ConsumerLocationResult(
            address: "",
            streetAddress: "",
            city: "",
            district: "",
            latitude: 0.0,
            longitude: 0.0,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = p.Provider.of<NavigationProvider>(context);
    final cart = ref.watch(cartProvider);
    final businessProvider = p.Provider.of<BusinessProvider>(context);
    final floatingNavState = ref.watch(floatingNavControllerProvider);
    // Seçili sekmeyi belirle
    int currentIndex = navProvider.currentIndex;

    // Alt menü görünürlük kuralları:
    // 1. Ana Sayfa sekmesinde (Index 0): Sadece bir dükkan seçilmişse (selectedBusiness != null) gösterilir.
    //    Kategori seçimi veya işletme listesi aşamasında (selectedBusiness == null) GİZLENİR.
    // 2. Sepet sekmesinde (Index 2): Sepet BOŞSA gösterilir, doluysa Checkout bar için GİZLENİR.
    // 3. Arama (Index 1) ve Profil (Index 3) sekmelerinde: GÖSTERİLİR.
    // 4. Görünür ekranlarda dikey kaydırmaya (floatingNavState.isBottomBarVisible) duyarlı çalışır.
    bool isMainTabWithNoBusiness = (currentIndex == 0 && businessProvider.selectedBusiness == null);
    bool isCartWithItems = (currentIndex == 2 && cart.items.isNotEmpty);

    bool showBottomBar = !isMainTabWithNoBusiness && !isCartWithItems && floatingNavState.isBottomBarVisible;

    // FAB Tıklanınca yapılacak işlem (Hoppa! - Ana Kategoriye Dön)
    void onFabPressed() {
      businessProvider.clearCategory();
      businessProvider.clearBusiness();
      navProvider.setIndex(0);
    }

    void onFabLongPressed() {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const VoiceAssistantDialog(),
      );
    }

    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;

    return PopScope(
      canPop: !isCurrentRoute,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. Profil Sekmesindeysek (Index 3)
        if (currentIndex == 3) {
          final profileNavigator = _profileNavigatorKey.currentState;
          if (profileNavigator != null && profileNavigator.canPop()) {
            profileNavigator.pop();
            return;
          }
        }

        // 2. Ana Sayfa sekmesinde (Index 0): state-driven ekranlar arasında geri git
        if (currentIndex == 0) {
          if (businessProvider.selectedBusiness != null) {
            businessProvider.clearBusiness();
            return;
          }
          if (businessProvider.selectedCategory != null) {
            businessProvider.clearCategory();
            return;
          }
        }

        // 3. Ana Sayfada Değilsek -> Ana Sayfaya Git
        if (currentIndex != 0) {
          navProvider.setIndex(0);
          return;
        }

        // 4. Uygulamadan Çık
        SystemNavigator.pop();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            final controller = ref.read(floatingNavControllerProvider.notifier);
            if (notification is UserScrollNotification) {
              controller.handleUserScroll(notification);
            } else if (notification is ScrollUpdateNotification) {
              controller.handleScrollUpdate(notification);
            }
            return false;
          },
          child: Stack(
            children: [
              // Main Page Stack
              PageStorage(
                bucket: _bucket,
                child: IndexedStack(index: currentIndex, children: _pages),
              ),

              // Modern Floating Capsule Bottom Navigation Dock
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FloatingBottomBar(
                  currentIndex: currentIndex,
                  onTabSelected: (index) {
                    ref.read(floatingNavControllerProvider.notifier).showBars();
                    navProvider.setIndex(index);
                  },
                  onFabPressed: () {
                    ref.read(floatingNavControllerProvider.notifier).showBars();
                    onFabPressed();
                  },
                  onFabLongPressed: onFabLongPressed,
                  cartItemCount: cart.items.length,
                  isVisible: showBottomBar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:core_auth/core_auth.dart';
import 'package:hoppa/apps/consumer/address/delivery_provider.dart';
import 'package:hoppa/apps/consumer/address/address_list_page.dart';
import 'package:hoppa/apps/consumer/business/business_provider.dart';
import 'package:hoppa/apps/consumer/business/widgets/category_grid_item.dart';
import 'package:hoppa/apps/consumer/home/widgets/promo_slider.dart';

class SelectionCategoryPage extends StatelessWidget {
  const SelectionCategoryPage({super.key});

  static final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Market',
      'icon': Icons.shopping_basket,
      'color': Colors.green,
      'badge': 'popular',
      'businessCount': 45,
      'avgDeliveryTime': '20-30 dk',
      'subtitle': 'Market alışverişi',
    },
    {
      'name': 'Restoran',
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'badge': 'popular',
      'businessCount': 32,
      'avgDeliveryTime': '25-35 dk',
      'subtitle': 'Yemek siparişi',
    },
    {
      'name': 'Su',
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'businessCount': 12,
      'avgDeliveryTime': '15-25 dk',
      'subtitle': 'Su ve içecek',
    },
    {
      'name': 'Kuruyemiş',
      'icon': Icons.grain,
      'color': Colors.brown,
      'badge': 'new',
      'businessCount': 8,
      'avgDeliveryTime': '20-30 dk',
      'subtitle': 'Kuruyemiş çeşitleri',
    },
    {
      'name': 'Kahve',
      'icon': Icons.coffee,
      'color': Colors.brown.shade700,
      'businessCount': 18,
      'avgDeliveryTime': '15-20 dk',
      'subtitle': 'Kahve ve içecek',
    },
    {
      'name': 'Çiçek',
      'icon': Icons.local_florist,
      'color': Colors.pink,
      'businessCount': 6,
      'avgDeliveryTime': '30-45 dk',
      'subtitle': 'Çiçek siparişi',
    },
  ];

  static const Map<String, String> _featuredImages = {
    'Market': 'assets/images/market_bg.png',
    'Restoran': 'assets/images/restaurant_bg.png',
    // Only Market and Restoran are featured with background images
    // Other categories will show detailed info instead
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // FIXED HEADER
            const _SelectionHeader(),
            const SizedBox(height: 10),

            // SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Promo Slider
                    // In a real scenario, these could be global platform-wide campaigns.
                    // For now, it stays empty on the category selection page.
                    const PromoSlider(campaigns: []),
                    const SizedBox(height: 24),

                    // Category Title (scrolls with content)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "İşletme Kategorisi",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Grid (non-scrollable, expands to content)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true, // Takes only needed space
                        physics:
                            const NeverScrollableScrollPhysics(), // Disable internal scroll
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.1,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final catName = cat['name'] as String;
                          final isFeatured = _featuredImages.containsKey(
                            catName,
                          );
                          final bgImage = _featuredImages[catName];

                          return CategoryGridItem(
                            category: cat,
                            isFeatured: isFeatured,
                            backgroundImage: bgImage,
                            badge: cat['badge'] as String?,
                            businessCount: cat['businessCount'] as int?,
                            avgDeliveryTime: cat['avgDeliveryTime'] as String?,
                            subtitle: cat['subtitle'] as String?,
                            index: index,
                            onTap: () {
                              Provider.of<BusinessProvider>(
                                context,
                                listen: false,
                              ).setCategory(catName);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionHeader extends rp.ConsumerWidget {
  const _SelectionHeader();

  @override
  Widget build(BuildContext context, rp.WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/hoppa_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      String displayName = "Hoppa";
                      if (authState is AuthAuthenticated) {
                        displayName = "Merhaba, ${authState.user.displayName}";
                      }

                      return Text(
                        displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      );
                    },
                  ),
                  Consumer<DeliveryProvider>(
                    builder: (context, provider, _) => GestureDetector(
                      onTap: () async {
                        final address = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AddressListPage(isSelectionMode: true),
                          ),
                        );
                        if (address != null) provider.setAddress(address);
                      },
                      child: Row(
                        children: [
                          Text(
                            provider.selectedAddress?.title ?? "Adres Seçiniz",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Account Menu
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(Icons.person_outline, color: theme.primaryColor),
            ),
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authControllerProvider.notifier).logout();
                // AuthStateChanges listener will handle navigation if setup in main.dart
                // Otherwise we might need to navigate manually:
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
              // Handle 'account' or other cases
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'account',
                child: Row(
                  children: [
                    Icon(Icons.person, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text("Hesabım"),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text("Çıkış Yap", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

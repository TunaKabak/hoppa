import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:core_auth/core_auth.dart';
import 'package:hoppa/apps/consumer/address/delivery_provider.dart';
import 'package:hoppa/apps/consumer/address/address_list_page.dart';
import 'package:hoppa/apps/consumer/home/widgets/account_bottom_sheet.dart';
import 'package:hoppa/apps/consumer/business/business_provider.dart';
import 'package:hoppa/apps/consumer/business/widgets/category_grid_item.dart';
import 'package:hoppa/apps/consumer/home/widgets/promo_slider.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_shop_repository.dart';

class SelectionCategoryPage extends rp.ConsumerWidget {
  const SelectionCategoryPage({super.key});

  static const Map<String, String> _featuredImages = {
    'Market': 'assets/images/market_bg.png',
    'Restoran': 'assets/images/restaurant_bg.png',
  };

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_basket':
        return Icons.shopping_basket;
      case 'restaurant':
        return Icons.restaurant;
      case 'water_drop':
        return Icons.water_drop;
      case 'grain':
        return Icons.grain;
      case 'coffee':
        return Icons.coffee;
      case 'local_florist':
        return Icons.local_florist;
      default:
        return Icons.store;
    }
  }

  Color _getColor(String hexColor) {
    try {
      if (hexColor.startsWith('#')) {
        hexColor = hexColor.substring(1);
      }
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (_) {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context, rp.WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(businessCategoriesProvider);

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
                      child: categoriesAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              "Kategoriler yüklenemedi: $err",
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                        data: (categoriesList) {
                          if (categoriesList.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text("Henüz kategori tanımlanmamış."),
                              ),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true, // Takes only needed space
                            physics: const NeverScrollableScrollPhysics(), // Disable internal scroll
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.1,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: categoriesList.length,
                            itemBuilder: (context, index) {
                              final cat = categoriesList[index];
                              final catName = cat.name;
                              final isFeatured = _featuredImages.containsKey(
                                catName,
                              );
                              final bgImage = _featuredImages[catName];

                              final catMap = {
                                'name': cat.name,
                                'icon': _getIconData(cat.icon),
                                'color': _getColor(cat.color),
                                'badge': cat.badge,
                                'avgDeliveryTime': cat.avgDeliveryTime,
                                'subtitle': cat.subtitle,
                              };

                              return CategoryGridItem(
                                category: catMap,
                                isFeatured: isFeatured,
                                backgroundImage: bgImage,
                                badge: cat.badge,
                                businessCount: null,
                                avgDeliveryTime: cat.avgDeliveryTime,
                                subtitle: cat.subtitle,
                                index: index,
                                onTap: () {
                                  Provider.of<BusinessProvider>(
                                    context,
                                    listen: false,
                                  ).setCategory(catName);
                                },
                              );
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
          GestureDetector(
            onTap: () => AccountBottomSheet.show(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(Icons.person_outline, color: theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/core/services/auth_service.dart';
import 'package:hoppa/features/address/delivery_provider.dart';
import 'package:hoppa/features/address/address_list_page.dart';
import 'package:hoppa/features/business/business_provider.dart';
import 'package:hoppa/features/business/widgets/category_grid_item.dart';
import 'package:hoppa/features/home/widgets/promo_slider.dart';

class SelectionCategoryPage extends StatelessWidget {
  const SelectionCategoryPage({super.key});

  static final List<Map<String, dynamic>> _categories = [
    {'name': 'Market', 'icon': Icons.shopping_basket, 'color': Colors.green},
    {'name': 'Restoran', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Su', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'Kuruyemiş', 'icon': Icons.grain, 'color': Colors.brown},
    {'name': 'Kahve', 'icon': Icons.coffee, 'color': Colors.brown.shade700},
    {'name': 'Çiçek', 'icon': Icons.local_florist, 'color': Colors.pink},
  ];

  static const Map<String, String> _featuredImages = {
    'Market': 'assets/images/market_bg.png',
    'Restoran': 'assets/images/restaurant_bg.png',
    'Su': 'assets/images/water_bg.png',
    'Kahve': 'assets/images/coffee_bg.png',
    'Kuruyemiş': 'assets/images/nuts_bg.png',
    'Çiçek': 'assets/images/flowers_bg.png',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const _SelectionHeader(),
            const SizedBox(height: 10),
            const PromoSlider(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "İşletme Kategorisi",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final catName = cat['name'] as String;
                  final isFeatured = _featuredImages.containsKey(catName);
                  final bgImage = _featuredImages[catName];

                  return CategoryGridItem(
                    category: cat,
                    isFeatured: isFeatured,
                    backgroundImage: bgImage,
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
          ],
        ),
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

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
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: authService.getUserStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      String displayName = "Hoppa";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data();
                        if (data != null && data.containsKey('name')) {
                          displayName = "Merhaba, ${data['name']}";
                        }
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
                await authService.signOut();
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

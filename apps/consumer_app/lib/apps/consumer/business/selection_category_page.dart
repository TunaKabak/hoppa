import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:google_fonts/google_fonts.dart';
import 'package:core_shared/shared/common/premium_image_views.dart';
import 'package:core_auth/core_auth.dart';
import 'package:consumer_app/apps/consumer/address/delivery_provider.dart';
import 'package:consumer_app/apps/consumer/address/address_list_page.dart';
import 'package:consumer_app/apps/consumer/home/widgets/account_bottom_sheet.dart';
import 'package:consumer_app/apps/consumer/home/widgets/hoppa_campaign_slider.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_video_player_dialog.dart';
import 'package:consumer_app/apps/consumer/business/business_provider.dart';
import 'package:consumer_app/apps/consumer/business/widgets/category_grid_item.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:consumer_app/apps/consumer/auth/consumer_login_page.dart';
import 'package:core_shared/shared/core/services/navigation_provider.dart';
import 'package:consumer_app/apps/consumer/cart/widgets/floating_cart_card.dart';
import 'package:consumer_app/apps/consumer/cart/cart_provider.dart';
import 'package:core_shared/shared/models/business.dart';
import 'package:latlong2/latlong.dart';
import 'package:core_shared/shared/core/utils/location_utils.dart';

class SelectionCategoryPage extends rp.ConsumerWidget {
  const SelectionCategoryPage({super.key});

  static const Map<String, String> _featuredImages = {
    'Market': 'assets/images/market_bg.png',
    'Restoran': 'assets/images/restaurant_bg.png',
    'Yemek': 'assets/images/restaurant_bg.png',
    'Su': 'assets/images/su_bg.png',
    'Kuruyemiş': 'assets/images/kuruyemis_bg.png',
    'Kahve': 'assets/images/kahve_bg.png',
    'Çiçek': 'assets/images/cicek_bg.png',
    'Manav': 'assets/images/manav_bg.png',
    'Kasap': 'assets/images/kasap_bg.png',
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
    final authState = ref.watch(authControllerProvider);
    final isGuest = authState is! AuthAuthenticated;
    final address = Provider.of<DeliveryProvider>(context).selectedAddress;

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
            // FIXED MODERN CURVED COLORFUL HEADER (Hepsiburada / Yemeksepeti Style)
            const HoppaHeader(
              child: _SelectionHeader(),
            ),
            // SCROLLABLE CONTENT IN WHITE CONTAINER WITH ROUNDED TOP CORNERS
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                  // HOPPA SPECIAL ADVERTISING CAROUSEL SLIDER (Campaigns right under header)
                  const HoppaCampaignSlider(),
                  const SizedBox(height: 16),

                  // WELCOME INFO AREA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            String titleText = "Hoş Geldiniz 👋";
                            if (authState is AuthAuthenticated) {
                              titleText =
                                  "Tekrar Hoş Geldin, ${authState.user.displayName} 👋";
                            }
                            return Text(
                              titleText,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Kuzey Kıbrıs'ın en hızlı teslimat ağını keşfedin.",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GLOBAL SEARCH BAR MOCK (Tapping triggers Navigation to Search Tab)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        Provider.of<NavigationProvider>(context, listen: false)
                            .setIndex(1);
                      },
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded,
                                color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Text(
                              "Kategori, işletme veya ürün ara...",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- ANA SAYFA ÖNE ÇIKAN MAĞAZALAR ---
                  ref.watch(consumerShopsProvider).when(
                    skipLoadingOnReload: true,
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => const SizedBox.shrink(),
                    data: (allBusinesses) {
                      final sponsored = allBusinesses
                          .where((b) => b.tags.contains("Öne Çıkan (Ana Sayfa)"))
                          .toList();
                      if (sponsored.isEmpty) return const SizedBox.shrink();

                      // Mesafe sıralaması (konum seçiliyse)
                      if (address != null) {
                        final Distance distance = const Distance();
                        sponsored.sort((a, b) {
                          final isAZero = a.latitude == 0 && a.longitude == 0;
                          final isBZero = b.latitude == 0 && b.longitude == 0;
                          if (isAZero && isBZero) return 0;
                          if (isAZero) return 1;
                          if (isBZero) return -1;

                          final distA = distance.as(
                            LengthUnit.Meter,
                            LatLng(address.latitude, address.longitude),
                            LatLng(a.latitude, a.longitude),
                          );
                          final distB = distance.as(
                            LengthUnit.Meter,
                            LatLng(address.latitude, address.longitude),
                            LatLng(b.latitude, b.longitude),
                          );
                          return distA.compareTo(distB);
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  "✨ Haftanın Öne Çıkanları",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 130,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: sponsored.length,
                              itemBuilder: (context, index) {
                                final business = sponsored[index];
                                String? distanceText;
                                if (address != null) {
                                  if (business.latitude == 0 && business.longitude == 0) {
                                    distanceText = "Mesafe Bilinmiyor";
                                  } else {
                                    const distance = Distance();
                                    final double km = distance.as(
                                      LengthUnit.Meter,
                                      LatLng(address.latitude, address.longitude),
                                      LatLng(business.latitude, business.longitude),
                                    ) / 1000.0;
                                    distanceText = LocationUtils.formatDistance(km);
                                  }
                                }
                                return _buildHomeFeaturedCard(context, ref, business, distanceText);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                  // Category Title (scrolls with content)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "İşletme Kategorileri",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Grid
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
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: categoriesList.length,
                          itemBuilder: (context, index) {
                            final cat = categoriesList[index];
                            final catName = cat.name;
                            final isFeatured = cat.imageUrl != null ||
                                _featuredImages.containsKey(catName);
                            final bgImage =
                                cat.imageUrl ?? _featuredImages[catName];

                            final catMap = {
                              'name': cat.name,
                              'icon': _getIconData(cat.icon),
                              'color': _getColor(cat.color),
                              'badge': cat.badge,
                              'avgDeliveryTime': cat.avgDeliveryTime,
                              'subtitle': cat.subtitle,
                              'imageUrl': cat.imageUrl,
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
                                if (cat.badge == 'yakında' || cat.badge == 'coming_soon') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.schedule_rounded, color: Colors.white),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "$catName kategorisindeki özenle seçilmiş işletmeler çok yakında Hoppa'da!",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFFFF6B00),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  return;
                                }

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
                  const SizedBox(height: 24),

                  // HOPPA SPECIAL ADVERTISING BANNER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withValues(alpha: 0.7),
                          builder: (context) => const HoppaVideoPlayerDialog(),
                        );
                      },
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE95D22), Color(0xFFFF8C00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFE95D22).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -15,
                                bottom: -15,
                                child: Opacity(
                                  opacity: 0.15,
                                  child: Icon(
                                    Icons.play_circle_fill_rounded,
                                    size: 150,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "HOPPA ÖZEL REKLAM",
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Hoppa ile Tanışın!",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Tek tıklamayla kapınızda. Tanıtım videomuzu izleyin.",
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: Colors.white
                                                  .withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Center(
                                      child: Container(
                                        height: 44,
                                        width: 44,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Color(0xFFE95D22),
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // LOGIN / REGISTER CTA CARD (Only for Guest mode)
                  if (isGuest)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 24),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hoppa Dünyasına Katılın!",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Siparişlerinizi hızlıca kapınıza getirmek, adreslerinizi güvenle kaydetmek ve size özel kampanyalardan yararlanmak için şimdi giriş yapın veya kayıt olun.",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 46,
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00A651),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginPage()),
                                  );
                                },
                                child: Text(
                                  "Giriş Yap / Üye Ol",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  rp.Consumer(
                    builder: (context, ref, child) {
                      final hasCarts = ref.watch(cartProvider).carts.isNotEmpty;
                      return SizedBox(height: hasCarts ? 100 : 32);
                    },
                  ),
                ],
              ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const FloatingCartCard(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Widget _buildHomeFeaturedCard(
    BuildContext context,
    rp.WidgetRef ref,
    Business business,
    String? distanceText,
  ) {
    return GestureDetector(
      onTap: () {
        final businessProvider = Provider.of<BusinessProvider>(
          context,
          listen: false,
        );

        // Reset and initialize Riverpod catalog providers
        ref.read(selectedCatalogCategoryProvider.notifier).state =
            business.type.label == 'Çiçek' ? 'Çiçek' : 'Tümü';
        ref.read(selectedCatalogSubCategoryProvider.notifier).state = 'Tümü';
        ref.read(selectedCatalogSortOptionProvider.notifier).state = 'Önerilen';
        ref.read(catalogSearchQueryProvider.notifier).state = '';

        businessProvider.setCategory(business.type.label);
        businessProvider.selectBusiness(business);
      },
      child: Opacity(
        opacity: business.isOpen ? 1.0 : 0.5,
        child: Container(
          width: 220,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 1. Background Cover Image/Gradient
                PremiumHeaderView(
                  imageUrl: business.headerImageUrl,
                  shopName: business.name,
                  height: 130,
                ),
                // 2. Black Gradient Overlay for perfect text legibility
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.75),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // 3. Gold Featured Badge (Top Left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          "ÖNE ÇIKAN",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 7.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 4. Closed Overlay (Top Right)
                if (!business.isOpen)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "KAPALI",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 7.5,
                        ),
                      ),
                    ),
                  ),
                // 5. Bottom Brand Logo & Content Row
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      PremiumLogoView(
                        imageUrl: business.logoUrl,
                        shopName: business.name,
                        radius: 15,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              business.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 11),
                                const SizedBox(width: 2),
                                Text(
                                  business.averageRating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 9,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.access_time_rounded, color: Colors.white60, size: 10),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    business.averageDeliveryTime,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: Colors.white60,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (distanceText != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    distanceText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: Colors.white60,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionHeader extends rp.ConsumerWidget {
  const _SelectionHeader();

  @override
  Widget build(BuildContext context, rp.WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isGuest = authState is! AuthAuthenticated;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Modern Logo Circle
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
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
                  Text(
                    isGuest
                        ? "Merhaba, Misafir"
                        : "Merhaba, ${authState.user.displayName}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Capsule Pill for Address
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              provider.selectedAddress?.title ?? "Adres Seçin",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // User Profile Menu Button
          GestureDetector(
            onTap: () => AccountBottomSheet.show(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

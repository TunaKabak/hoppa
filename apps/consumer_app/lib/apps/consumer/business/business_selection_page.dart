import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:consumer_app/apps/consumer/business/business_provider.dart';
import 'package:core_shared/shared/models/business.dart';
import 'package:consumer_app/apps/consumer/address/delivery_provider.dart';
import 'package:consumer_app/apps/consumer/address/address_list_page.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:consumer_app/apps/consumer/home/widgets/account_bottom_sheet.dart';
import 'package:consumer_app/apps/consumer/widgets/shop_badge.dart';
import 'package:latlong2/latlong.dart'; // Mesafe hesaplama için
import 'package:core_auth/core_auth.dart';
import 'package:consumer_app/apps/consumer/auth/consumer_login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';

class BusinessSelectionPage extends ConsumerWidget {
  final String? category; // Artık İşletme Türü veya Kategori filtresi olabilir

  const BusinessSelectionPage({super.key, this.category});

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // İzlenecek lifecycle provider'ı çağır
    ref.watch(shopLifecyclePollingProvider);
    
    const kPrimaryColor = Color(0xFF00A651);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: p.Consumer<DeliveryProvider>(
        builder: (context, deliveryProvider, child) {
          final address = deliveryProvider.selectedAddress;
          final authState = ref.watch(authControllerProvider);
          final isGuest = authState is! AuthAuthenticated;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FIXED MODERN CURVED COLORFUL HEADER (Hepsiburada / Yemeksepeti Style)
              HoppaHeader(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () {
                          // Kategoriyi temizle -> Kategori Seçimine döner
                          p.Provider.of<BusinessProvider>(
                            context,
                            listen: false,
                          ).clearCategory();
                        },
                      ),
                      Text(
                        category ?? "İşletme Seçimi",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => AccountBottomSheet.show(context),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
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
                ),
              ),
              const SizedBox(height: 8),

              // --- ADRES KARTI ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF3FAF6), // Soft mint green tint
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      splashColor: kPrimaryColor.withValues(alpha: 0.1),
                      onTap: () async {
                        if (isGuest) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        } else {
                          final selectedAddress = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AddressListPage(isSelectionMode: true),
                            ),
                          );
                          if (selectedAddress != null) {
                            deliveryProvider.setAddress(selectedAddress);
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Circular Location Icon Badge
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: kPrimaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Address Info text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    address != null
                                        ? "Teslimat: ${address.title}"
                                        : (isGuest ? "Nereye Gönderilsin?" : "Teslimat Adresi Seçin"),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    address != null
                                        ? "${address.district}, ${address.city}"
                                        : (isGuest ? "Adres girmek için lütfen giriş yapın" : "Lütfen bir teslimat adresi belirtin"),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Navigation Caret or Guest Badge
                            if (isGuest) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFECE5), // Soft orange tint
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Giriş Yapın",
                                      style: TextStyle(
                                        color: Color(0xFFE95D22), // Hoppa Orange
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFFE95D22),
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // --- İŞLETME LİSTESİ ---
              Expanded(
                child: ref.watch(consumerShopsProvider).when(
                  skipLoadingOnReload: true,
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Center(child: Text("Dükkanlar yüklenirken bir hata oluştu. Lütfen tekrar deneyin.")),
                  data: (allBusinesses) {
                    var businesses = List<Business>.from(allBusinesses);

                    if (businesses.isEmpty) {
                      return const Center(
                        child: Text("Aktif işletme bulunamadı."),
                      );
                    }

                    // FİLTRELEME (İşletme Türü veya Kategori)
                    if (category != null) {
                      // Hem tur ismine gore hem de kategorilere gore filtreleyelim
                      businesses = businesses
                          .where(
                            (b) =>
                                b.categories.contains(category) ||
                                b.type.label == category ||
                                b.type.name.toLowerCase() ==
                                    category!.toLowerCase(),
                          )
                          .toList();

                      if (businesses.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Bu kategoride hizmet veren\niş yeri bulunamadı.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }
                    }

                    // MESAFEYE GÖRE FILTRELEME VE SIRALAMA
                    if (address != null) {
                      final Distance distance = const Distance();

                      // 1. Filtreleme: Menzil dışındakileri gizle
                      businesses = businesses.where((b) {
                        // İşletmenin koordinatları 0 ise (hatalı veri) filtreleme yapma veya sonda göster
                        if (b.latitude == 0 && b.longitude == 0) return true;

                        final double km =
                            distance.as(
                              LengthUnit.Meter,
                              LatLng(address.latitude, address.longitude),
                              LatLng(b.latitude, b.longitude),
                            ) /
                            1000.0;
                        return km <=
                            (b.deliveryRadius > 0 ? b.deliveryRadius : 10.0);
                      }).toList();

                      if (businesses.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Seçilen adrese hizmet veren\niş yeri bulunamadı.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }

                      // 2. Sıralama: En yakından uzağa
                      businesses.sort((a, b) {
                        final isAZero = a.latitude == 0 && a.longitude == 0;
                        final isBZero = b.latitude == 0 && b.longitude == 0;
                        
                        // İkisi de 0 ise eşittir
                        if (isAZero && isBZero) return 0;
                        // Sadece a 0 ise b'den sonra gelsin
                        if (isAZero) return 1;
                        // Sadece b 0 ise a'dan sonra gelsin
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
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                category != null
                                    ? "$category Listesi"
                                    : "Yakındaki İşletmeler",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${businesses.length} İşletme",
                                  style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(consumerShopsProvider);
                              await ref.read(consumerShopsProvider.future);
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: businesses.length,
                              itemBuilder: (context, index) {
                                final business = businesses[index];

                                // Mesafeyi hesaplayıp karta gönderelim
                                String? distanceText;
                                if (address != null) {
                                  if (business.latitude == 0 && business.longitude == 0) {
                                    distanceText = "Mesafe\nBilinmiyor";
                                  } else {
                                    const distance = Distance();
                                    final double km =
                                        distance.as(
                                          LengthUnit.Meter,
                                          LatLng(address.latitude, address.longitude),
                                          LatLng(business.latitude, business.longitude),
                                        ) /
                                        1000.0;
                                    distanceText = "${km.toStringAsFixed(1)} km";
                                  }
                                }

                                return _buildCompactBusinessCard(
                                  context,
                                  ref,
                                  business,
                                  distanceText,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactBusinessCard(
    BuildContext context,
    WidgetRef ref,
    Business business,
    String? distanceText,
  ) {
    const kPrimaryColor = Color(0xFF00A651);

    return GestureDetector(
      onTap: () {
        final businessProvider = p.Provider.of<BusinessProvider>(
          context,
          listen: false,
        );

        // Reset and initialize Riverpod catalog providers
        ref.read(selectedCatalogCategoryProvider.notifier).state =
            business.type.label == 'Çiçek' ? 'Çiçek' : 'Tümü';
        ref.read(selectedCatalogSubCategoryProvider.notifier).state = 'Tümü';
        ref.read(selectedCatalogSortOptionProvider.notifier).state = 'Önerilen';
        ref.read(catalogSearchQueryProvider.notifier).state = '';

        businessProvider.selectBusiness(business);
      },
      child: Opacity(
        opacity: business.isOpen ? 1.0 : 0.5,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KAPAK FOTOĞRAFI & LOGO ALANI
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Kapak Fotoğrafı
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    child: _isValidImageUrl(business.headerImageUrl)
                        ? Image.network(
                            business.headerImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.network('https://via.placeholder.com/150', fit: BoxFit.cover),
                          )
                        : Image.network('https://via.placeholder.com/150', fit: BoxFit.cover),
                  ),
                ),

                // Kapalı Rozeti (Overlay)
                if (!business.isOpen)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "KAPALI",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                // Logo (Sol alt köşe, kapağın üstüne biniyor)
                Positioned(
                  left: 12,
                  bottom: -20,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _isValidImageUrl(business.logoUrl)
                          ? Image.network(
                              business.logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.network('https://via.placeholder.com/150', fit: BoxFit.cover),
                            )
                          : Image.network('https://via.placeholder.com/150', fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24), // Logo payı
            // İÇERİK ALANI
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          business.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Puan Eklenebilir
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              "${business.averageRating.toStringAsFixed(1)} (${business.reviewCount})",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${business.type.label} • ${business.address}", // Türü göster
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (business.tags.isNotEmpty || business.allowedFulfillmentModels.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ...business.allowedFulfillmentModels.map((model) {
                          String label = "";
                          if (model == 'PLATFORM_DELIVERY') {
                            label = "Hoppa Kuryesi";
                          } else if (model == 'SELF_DELIVERY') {
                            label = "Esnaf Teslimatı";
                          } else if (model == 'PICKUP') {
                            label = "Gel-Al";
                          }
                          if (label.isEmpty) return const SizedBox.shrink();
                          return ShopBadge(label: label);
                        }),
                        ...business.tags.map((tag) {
                          return ShopBadge(label: tag);
                        }),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),

                  // Bilgi Alt Satırı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Min Sepet Tutar
                      _buildInfoBadge(
                        Icons.shopping_basket_outlined,
                        "Min. ${business.minBasketAmount.toStringAsFixed(0)} ₺",
                      ),
                      // Teslimat Süresi
                      _buildInfoBadge(
                        Icons.access_time,
                        business.averageDeliveryTime,
                      ),
                      // Mesafe
                      if (distanceText != null)
                        _buildInfoBadge(
                          Icons.near_me,
                          distanceText,
                          isPrimary: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, {bool isPrimary = false}) {
    const kPrimaryColor = Color(0xFF00A651);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isPrimary ? kPrimaryColor : Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: isPrimary ? kPrimaryColor : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

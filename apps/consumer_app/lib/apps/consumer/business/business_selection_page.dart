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
import 'package:google_fonts/google_fonts.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';
import 'package:consumer_app/apps/consumer/providers/consumer_location_controller.dart';

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
        child: p.Consumer<DeliveryProvider>(
          builder: (context, deliveryProvider, child) {
            final address = deliveryProvider.selectedAddress;

            // Synchronize with Riverpod's consumerCoordinatesProvider
            if (address != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final currentCoords = ref.read(consumerCoordinatesProvider);
                if (currentCoords == null ||
                    currentCoords.latitude != address.latitude ||
                    currentCoords.longitude != address.longitude) {
                  ref.read(consumerCoordinatesProvider.notifier).state =
                      LatLng(address.latitude, address.longitude);
                }
              });
            }

            String pageTitle = "Yakındaki Mağazalar";
            if (category != null) {
              final catLower = category!.toLowerCase();
              if (catLower == 'market') {
                pageTitle = "Hoppa Market";
              } else if (catLower == 'restaurant') {
                pageTitle = "Restoran & Yemek";
              } else if (catLower == 'greengrocer') {
                pageTitle = "Manav & Taze Meyve";
              } else if (catLower == 'butcher') {
                pageTitle = "Kasap & Şarküteri";
              } else {
                pageTitle = category!;
              }
            }

            return Column(
              children: [
                // FIXED MODERN CURVED COLORFUL HEADER (Hepsiburada / Yemeksepeti Style)
                HoppaHeader(
                  height: 154,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
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
                              pageTitle,
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
                      ),
                      const SizedBox(height: 8),
                      // Floating Address Bar Card (integrated into orange gradient header)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFF3EE), // Soft orange peach tint
                                Colors.white,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFDDD2)), // Warm orange border
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
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
                              splashColor: const Color(0xFFE95D22).withValues(alpha: 0.1),
                              onTap: () async {
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
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // Circular Location Icon Badge
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE95D22).withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFFE95D22),
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
                                                : "Nereye Gönderilsin?",
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
                                                : "Lütfen bir teslimat adresi belirtin",
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
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F7F6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

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

                                // MESAFEYE GÖRE FILTRELEME
                                if (address != null) {
                                  final Distance distance = const Distance();
                                  businesses = businesses.where((b) {
                                    if (b.latitude == 0 && b.longitude == 0) return true;
                                    final double km = distance.as(
                                      LengthUnit.Meter,
                                      LatLng(address.latitude, address.longitude),
                                      LatLng(b.latitude, b.longitude),
                                    ) / 1000.0;
                                    return km <= (b.deliveryRadius > 0 ? b.deliveryRadius : 10.0);
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
                                }

                                // SPONSORLU VE NORMAL DÜKKANLARI AYIR (Story 49.2)
                                final sponsoredBusinesses = businesses.where((b) => b.tags.contains("Öne Çıkan")).toList();
                                final regularBusinesses = businesses.where((b) => !b.tags.contains("Öne Çıkan")).toList();

                                // Her iki listeyi de mesafeye göre sıralayalım
                                if (address != null) {
                                  final Distance distance = const Distance();
                                  final sortFunc = (Business a, Business b) {
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
                                  };

                                  sponsoredBusinesses.sort(sortFunc);
                                  regularBusinesses.sort(sortFunc);
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ─── ÖNE ÇIKAN İŞLETMELER YATAY KAROUSEL ───
                                    if (sponsoredBusinesses.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                        child: Row(
                                          children: [
                                            const Text(
                                              "🔥 Haftanın Öne Çıkanları",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.amber.shade200),
                                              ),
                                              child: const Text(
                                                "Ayrıcalıklı",
                                                style: TextStyle(
                                                  color: Colors.amber,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 180,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          itemCount: sponsoredBusinesses.length,
                                          itemBuilder: (context, index) {
                                            final business = sponsoredBusinesses[index];
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
                                                distanceText = "${km.toStringAsFixed(1)} km";
                                              }
                                            }
                                            return _buildPremiumFeaturedCard(context, ref, business, distanceText);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    // ─── DİĞER YAKINDAKİ TÜM İŞLETMELER DİKEY LİSTE ───
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            category != null
                                                ? "$pageTitle Listesi"
                                                : "Yakındaki Tüm İşletmeler",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              fontFamily: 'Poppins',
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
                                              "${regularBusinesses.length} İşletme",
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
                                        child: regularBusinesses.isEmpty
                                            ? Center(
                                                child: Text(
                                                  "Yakında başka işletme bulunamadı.",
                                                  style: TextStyle(color: Colors.grey.shade500),
                                                ),
                                              )
                                            : ListView.builder(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                itemCount: regularBusinesses.length,
                                                itemBuilder: (context, index) {
                                                  final business = regularBusinesses[index];
                                                  String? distanceText;
                                                  if (address != null) {
                                                    if (business.latitude == 0 && business.longitude == 0) {
                                                      distanceText = "Mesafe\nBilinmiyor";
                                                    } else {
                                                      const distance = Distance();
                                                      final double km = distance.as(
                                                        LengthUnit.Meter,
                                                        LatLng(address.latitude, address.longitude),
                                                        LatLng(business.latitude, business.longitude),
                                                      ) / 1000.0;
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
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumFeaturedCard(
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
          width: 280,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFE0B2), width: 1.5), // Golden peach border
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header image with overlay badge
                Stack(
                  children: [
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      child: _isValidImageUrl(business.headerImageUrl)
                          ? Image.network(
                              business.headerImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.network('https://via.placeholder.com/150', fit: BoxFit.cover),
                            )
                          : Image.network('https://via.placeholder.com/150', fit: BoxFit.cover),
                    ),
                    // Gold gradient overlay for premium look
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    // "Öne Çıkan" tag overlay
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE65100), Color(0xFFFF8C00)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              "ÖNE ÇIKAN",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!business.isOpen)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "KAPALI",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Card Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shop logo
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                        const SizedBox(width: 10),
                        // Shop Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                business.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                  const SizedBox(width: 2),
                                  const Text(
                                    "4.9",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.access_time_rounded, color: Colors.grey.shade600, size: 12),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      business.averageDeliveryTime,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (distanceText != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  distanceText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              const SizedBox(height: 24),
              // DETAY BİLGİ ALANI
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          business.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "4.9",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Etiketler & Badge'ler
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ...business.tags.map((tag) => ShopBadge(
                                    label: tag,
                                  )),
                              const ShopBadge(
                                label: "Gel-Al",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 12),
                    // Alt Bilgi İkonları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Teslimat Tipi
                        _buildInfoBadge(
                          Icons.delivery_dining,
                          business.allowedFulfillmentModels.contains('PICKUP') &&
                                  !business.allowedFulfillmentModels.any((m) => m.contains('DELIVERY'))
                              ? "Gel-Al"
                              : "Paket Servis",
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

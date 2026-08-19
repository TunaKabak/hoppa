import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:provider/provider.dart' as p;
import 'package:consumer_app/apps/consumer/business/business_provider.dart';
import 'package:core_shared/shared/models/business.dart';
import 'package:core_shared/shared/common/premium_image_views.dart';
import 'package:consumer_app/apps/consumer/address/delivery_provider.dart';
import 'package:consumer_app/apps/consumer/address/address_list_page.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:consumer_app/apps/consumer/home/widgets/account_bottom_sheet.dart';
import 'package:consumer_app/apps/consumer/widgets/shop_badge.dart';
import 'package:latlong2/latlong.dart'; // Mesafe hesaplama için
import 'package:google_fonts/google_fonts.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';
import 'package:consumer_app/apps/consumer/providers/consumer_location_controller.dart';
import 'package:consumer_app/apps/consumer/cart/widgets/floating_cart_card.dart';
import 'package:consumer_app/apps/consumer/cart/cart_provider.dart';
import 'package:core_shared/shared/core/utils/location_utils.dart';

final selectedBusinessFiltersProvider =
    StateProvider<List<String>>((ref) => []);
final selectedBusinessSortProvider = StateProvider<String>((ref) => 'Mesafe');
final selectedBusinessSubcategoryProvider =
    StateProvider<String>((ref) => 'Tümü');

class BusinessSelectionPage extends ConsumerStatefulWidget {
  final String? category; // Artık İşletme Türü veya Kategori filtresi olabilir

  const BusinessSelectionPage({super.key, this.category});

  @override
  ConsumerState<BusinessSelectionPage> createState() =>
      _BusinessSelectionPageState();
}

class _BusinessSelectionPageState extends ConsumerState<BusinessSelectionPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
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
            if (widget.category != null) {
              final catLower = widget.category!.toLowerCase();
              if (catLower == 'market') {
                pageTitle = "Hoppa Market";
              } else if (catLower == 'restaurant') {
                pageTitle = "Restoran & Yemek";
              } else if (catLower == 'greengrocer') {
                pageTitle = "Manav & Taze Meyve";
              } else if (catLower == 'butcher') {
                pageTitle = "Kasap & Şarküteri";
              } else {
                pageTitle = widget.category!;
              }
            }

            return Column(
              children: [
                // SLEEK FIXED COMPACT HEADER
                HoppaHeader(
                  height: 68.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                          onPressed: () {
                            // Kategoriyi temizle -> Kategori Seçimine döner
                            p.Provider.of<BusinessProvider>(
                              context,
                              listen: false,
                            ).clearCategory();
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pageTitle,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () async {
                                  final selectedAddress = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddressListPage(isSelectionMode: true),
                                    ),
                                  );
                                  if (selectedAddress != null) {
                                    deliveryProvider.setAddress(selectedAddress);
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white70,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        address != null ? "${address.title} (${address.district})" : "Teslimat Adresi Seçin",
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.white70,
                                      size: 15,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => AccountBottomSheet.show(context),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
                          const SizedBox(height: 4),

                          // --- İŞLETME LİSTESİ ---
                          Expanded(
                            child: ref.watch(consumerShopsProvider).when(
                                  skipLoadingOnReload: true,
                                  loading: () => const Center(
                                      child: CircularProgressIndicator()),
                                  error: (err, stack) {
                                    debugPrint("BusinessSelectionPage Error: $err\n$stack");
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.storefront_outlined,
                                              size: 56,
                                              color: Color(0xFFE95D22),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              "Dükkanlar yüklenirken bir hata oluştu.",
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.grey.shade800,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              onPressed: () => ref.invalidate(consumerShopsProvider),
                                              icon: const Icon(Icons.refresh_rounded, size: 18),
                                              label: const Text("Tekrar Deneyin"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFE95D22),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  data: (allBusinesses) {
                                    if (allBusinesses.isEmpty) {
                                      return const Center(
                                        child:
                                            Text("Aktif işletme bulunamadı."),
                                      );
                                    }

                                    final activeFilters = ref
                                        .watch(selectedBusinessFiltersProvider);
                                    final activeSort =
                                        ref.watch(selectedBusinessSortProvider);
                                    final activeSubcategory = ref.watch(
                                        selectedBusinessSubcategoryProvider);

                                    var businesses =
                                        List<Business>.from(allBusinesses);

                                    // 1. KATEGORİ FİLTRELEME (Restoran & Yemek, Market, Su, Çiçek vb.)
                                    if (widget.category != null) {
                                      final catLower = widget.category!.toLowerCase();
                                      businesses = businesses.where((b) {
                                        // A. Tam metin veya kategori dizisi eşleşmesi
                                        if (b.categories.any((c) => c.toLowerCase() == catLower)) return true;
                                        final typeNameLower = b.type.name.toLowerCase();
                                        final typeLabelLower = b.type.label.toLowerCase();

                                        if (typeNameLower == catLower || typeLabelLower == catLower) return true;

                                        // B. Takma ad (Alias) ve Grup Eşleştirmeleri
                                        if (catLower.contains('restoran') || catLower.contains('yemek') || catLower == 'restaurant') {
                                          return typeNameLower == 'restaurant' || typeNameLower == 'cafe' || typeLabelLower == 'yemek' || typeLabelLower == 'cafe';
                                        }
                                        if (catLower.contains('market')) {
                                          return typeNameLower == 'market' || typeLabelLower == 'market';
                                        }
                                        if (catLower.contains('manav') || catLower.contains('meyve') || catLower.contains('sebze')) {
                                          return typeNameLower == 'greengrocer' || typeLabelLower == 'manav';
                                        }
                                        if (catLower.contains('kasap') || catLower.contains('et') || catLower.contains('şarküteri')) {
                                          return typeNameLower == 'butcher' || typeLabelLower == 'kasap';
                                        }
                                        if (catLower.contains('su')) {
                                          return typeNameLower == 'water' || typeLabelLower == 'su';
                                        }
                                        if (catLower.contains('çiçek') || catLower.contains('cicek') || catLower.contains('flower')) {
                                          return typeNameLower == 'florist' || typeLabelLower == 'çiçek';
                                        }
                                        if (catLower.contains('fırın') || catLower.contains('firin') || catLower.contains('pastane') || catLower.contains('bakery')) {
                                          return typeNameLower == 'bakery' || typeLabelLower == 'fırın';
                                        }
                                        if (catLower.contains('kuruyemiş') || catLower.contains('kuruyemis') || catLower.contains('nuts')) {
                                          return typeNameLower == 'nuts' || typeLabelLower == 'kuruyemiş';
                                        }

                                        return false;
                                      }).toList();
                                    }

                                    // 2. MESAFEYE GÖRE FILTRELEME
                                    if (address != null) {
                                      final Distance distance =
                                          const Distance();
                                      businesses = businesses.where((b) {
                                        if (b.latitude == 0 && b.longitude == 0)
                                          return true;
                                        final double km = distance.as(
                                              LengthUnit.Meter,
                                              LatLng(address.latitude,
                                                  address.longitude),
                                              LatLng(b.latitude, b.longitude),
                                            ) /
                                            1000.0;
                                        return km <=
                                            (b.deliveryRadius > 0
                                                ? b.deliveryRadius
                                                : 15.0);
                                      }).toList();
                                    }

                                    // 3. SEÇİLİ AKTİF FİLTRELER (Çoklu Seçim)
                                    if (activeFilters
                                        .contains('Açık Olanlar')) {
                                      businesses = businesses
                                          .where((b) => b.isOpen)
                                          .toList();
                                    }
                                    if (activeFilters
                                        .contains('Ücretsiz Teslimat')) {
                                      businesses = businesses
                                          .where((b) =>
                                              b.baseDeliveryFee == 0 ||
                                              b.freeDeliveryThreshold != null)
                                          .toList();
                                    }
                                    if (activeFilters
                                        .contains('Hızlı Teslimat')) {
                                      businesses = businesses
                                          .where((b) =>
                                              b.averageDeliveryTime
                                                  .contains('15') ||
                                              b.averageDeliveryTime
                                                  .contains('30'))
                                          .toList();
                                    }

                                    // 4. SEÇİLİ AKTİF ALTKATEGORİ FİLTRESİ
                                    if (activeSubcategory != 'Tümü') {
                                      businesses = businesses.where((b) {
                                        final nameLower = b.name.toLowerCase();
                                        final subLower =
                                            activeSubcategory.toLowerCase();

                                        if (subLower == 'restoran') {
                                          return b.type.name == 'restaurant' &&
                                              (nameLower.contains('kebap') ||
                                                  nameLower.contains('pide') ||
                                                  nameLower.contains('balık') ||
                                                  nameLower.contains('döner') ||
                                                  nameLower.contains('burger'));
                                        }
                                        if (subLower == 'kafe') {
                                          return nameLower.contains('kahve') ||
                                              nameLower.contains('cafe') ||
                                              nameLower.contains('kafe') ||
                                              nameLower.contains('brew');
                                        }
                                        if (subLower == 'tatlı' ||
                                            subLower == 'pastane') {
                                          return nameLower.contains('tatlı') ||
                                              nameLower.contains('baklava') ||
                                              nameLower.contains('pastane') ||
                                              nameLower.contains('çikolata') ||
                                              b.categories.contains('Tatlılar');
                                        }
                                        if (subLower == 'market') {
                                          return b.type.name == 'market' &&
                                              (nameLower.contains('market') ||
                                                  nameLower.contains(
                                                      'süpermarket') ||
                                                  nameLower
                                                      .contains('bakkal') ||
                                                  nameLower.contains('koop'));
                                        }
                                        if (subLower == 'kasap') {
                                          return nameLower.contains('kasap') ||
                                              nameLower.contains('et');
                                        }
                                        if (subLower == 'manav') {
                                          return nameLower.contains('manav') ||
                                              nameLower.contains('yeşillik') ||
                                              b.categories
                                                  .contains('Sebzeler') ||
                                              b.categories.contains('Meyveler');
                                        }
                                        if (subLower == 'fırın') {
                                          return nameLower.contains('fırın') ||
                                              nameLower.contains('ekmek') ||
                                              nameLower.contains('unlu') ||
                                              b.categories.contains('Fırın');
                                        }
                                        if (subLower == 'hırdavat') {
                                          return nameLower
                                                  .contains('hırdavat') ||
                                              nameLower.contains('yapı') ||
                                              nameLower.contains('nalbur');
                                        }
                                        return nameLower.contains(subLower) ||
                                            b.categories.any((c) => c
                                                .toLowerCase()
                                                .contains(subLower));
                                      }).toList();
                                    }

                                    // SPONSORLU VE NORMAL DÜKKANLARI AYIR (Story 49.2)
                                    final sponsoredBusinesses = businesses
                                        .where((b) => b.tags
                                            .contains("Öne Çıkan (Kategori)"))
                                        .toList();
                                    final regularBusinesses = businesses
                                        .where((b) => !b.tags
                                            .contains("Öne Çıkan (Kategori)"))
                                        .toList();

                                    // 5. SEÇİLİ AKTİF SIRALAMA
                                    final Distance distance = const Distance();
                                    final sortFunc = (Business a, Business b) {
                                      if (activeSort == 'Mesafe') {
                                        if (address == null) return 0;
                                        final distA = distance.as(
                                            LengthUnit.Meter,
                                            LatLng(address.latitude,
                                                address.longitude),
                                            LatLng(a.latitude, a.longitude));
                                        final distB = distance.as(
                                            LengthUnit.Meter,
                                            LatLng(address.latitude,
                                                address.longitude),
                                            LatLng(b.latitude, b.longitude));
                                        return distA.compareTo(distB);
                                      } else if (activeSort == 'Puan') {
                                        return b.averageRating
                                            .compareTo(a.averageRating);
                                      } else if (activeSort == 'Hız') {
                                        final getWeight = (String val) {
                                          if (val.contains('15')) return 1;
                                          if (val.contains('30')) return 2;
                                          if (val.contains('45')) return 3;
                                          return 4;
                                        };
                                        return getWeight(a.averageDeliveryTime)
                                            .compareTo(getWeight(
                                                b.averageDeliveryTime));
                                      } else if (activeSort == 'Sepet Limiti') {
                                        return a.minBasketAmount
                                            .compareTo(b.minBasketAmount);
                                      }
                                      return 0;
                                    };

                                    sponsoredBusinesses.sort(sortFunc);
                                    regularBusinesses.sort(sortFunc);

                                    return RefreshIndicator(
                                      onRefresh: () async {
                                        ref.invalidate(consumerShopsProvider);
                                        await ref
                                            .read(consumerShopsProvider.future);
                                      },
                                      child: CustomScrollView(
                                        controller: _scrollController,
                                        slivers: [
                                          SliverPersistentHeader(
                                            pinned: true,
                                            delegate: _StickyFilterBarDelegate(
                                              child: _buildFilterAndSortBar(
                                                  context,
                                                  ref,
                                                  activeFilters,
                                                  activeSort,
                                                  activeSubcategory),
                                            ),
                                          ),
                                          if (businesses.isEmpty)
                                            SliverFillRemaining(
                                              hasScrollBody: false,
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .filter_list_off_rounded,
                                                      size: 64,
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      "Seçilen filtrelere uygun dükkan bulunamadı.",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors
                                                            .grey.shade600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else ...[
                                            // ─── ÖNE ÇIKAN İŞLETMELER YATAY KAROUSEL ───
                                            if (sponsoredBusinesses.isNotEmpty)
                                              SliverToBoxAdapter(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .fromLTRB(
                                                          16, 8, 16, 8),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            widget.category !=
                                                                    null
                                                                ? "Öne Çıkan $pageTitle"
                                                                : "Öne Çıkanlar",
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .black87,
                                                              fontFamily:
                                                                  'Poppins',
                                                            ),
                                                          ),
                                                          const ShopBadge(
                                                            label: "Sponsorlu",
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: 130,
                                                      child: ListView.builder(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16),
                                                        itemCount:
                                                            sponsoredBusinesses
                                                                .length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          final business =
                                                              sponsoredBusinesses[
                                                                  index];
                                                          String? distanceText;
                                                          if (address != null) {
                                                            if (business.latitude ==
                                                                    0 &&
                                                                business.longitude ==
                                                                    0) {
                                                              distanceText =
                                                                  "Mesafe Bilinmiyor";
                                                            } else {
                                                              const distance =
                                                                  Distance();
                                                              final double km =
                                                                  distance.as(
                                                                        LengthUnit
                                                                            .Meter,
                                                                        LatLng(
                                                                            address.latitude,
                                                                            address.longitude),
                                                                        LatLng(
                                                                            business.latitude,
                                                                            business.longitude),
                                                                      ) /
                                                                      1000.0;
                                                              distanceText =
                                                                  LocationUtils.formatDistance(km);
                                                            }
                                                          }
                                                          return _buildPremiumFeaturedCard(
                                                              context,
                                                              ref,
                                                              business,
                                                              distanceText);
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                  ],
                                                ),
                                              ),

                                            // ─── DİĞER YAKINDAKİ TÜM İŞLETMELER DİKEY LİSTE BAŞLIĞI ───
                                            SliverToBoxAdapter(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        16, 8, 16, 8),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      widget.category != null
                                                          ? "$pageTitle Listesi"
                                                          : "Yakındaki Tüm İşletmeler",
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black87,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: kPrimaryColor
                                                            .withValues(
                                                                alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        "${regularBusinesses.length} İşletme",
                                                        style: const TextStyle(
                                                          color: kPrimaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // ─── DİĞER YAKINDAKİ TÜM İŞLETMELER DİKEY LİSTE ───
                                            if (regularBusinesses.isEmpty)
                                              SliverToBoxAdapter(
                                                child: Container(
                                                  height: 200,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    "Yakında başka işletme bulunamadı.",
                                                    style: TextStyle(
                                                        color: Colors
                                                            .grey.shade500),
                                                  ),
                                                ),
                                              )
                                            else
                                              SliverPadding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 16),
                                                sliver: SliverList(
                                                  delegate:
                                                      SliverChildBuilderDelegate(
                                                    (context, index) {
                                                      final business =
                                                          regularBusinesses[
                                                              index];
                                                      String? distanceText;
                                                      if (address != null) {
                                                        if (business.latitude ==
                                                                0 &&
                                                            business.longitude ==
                                                                0) {
                                                          distanceText =
                                                              "Mesafe\nBilinmiyor";
                                                        } else {
                                                          const distance =
                                                              Distance();
                                                          final double km =
                                                              distance.as(
                                                                    LengthUnit
                                                                        .Meter,
                                                                    LatLng(
                                                                        address
                                                                            .latitude,
                                                                        address
                                                                            .longitude),
                                                                    LatLng(
                                                                        business
                                                                            .latitude,
                                                                        business
                                                                            .longitude),
                                                                  ) /
                                                                  1000.0;
                                                          distanceText =
                                                              LocationUtils.formatDistance(km);
                                                        }
                                                      }
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 6),
                                                        child:
                                                            _buildCompactBusinessCard(
                                                          context,
                                                          ref,
                                                          business,
                                                          distanceText,
                                                        ),
                                                      );
                                                    },
                                                    childCount:
                                                        regularBusinesses
                                                            .length,
                                                  ),
                                                ),
                                              ),
                                            // Sepette ürün varken alttaki floating cart bar'ın işletme kartlarını kapatmaması için dinamik boşluk
                                            SliverToBoxAdapter(
                                              child: SizedBox(
                                                height: ref.watch(cartProvider).carts.isNotEmpty ? 100 : 32,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
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
      floatingActionButton: const FloatingCartCard(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildPremiumFeaturedCard(
    BuildContext context,
    WidgetRef ref,
    Business business,
    String? distanceText,
  ) {
    return GestureDetector(
      onTap: () {
        final businessProvider = p.Provider.of<BusinessProvider>(
          context,
          listen: false,
        );

        ref.read(activeReferringSourceProvider.notifier).state =
            'CATEGORY_SLIDER';
        ref.read(activeShopCampaignIdProvider.notifier).state = null;

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.white, size: 10),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
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
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 11),
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
                                  const Icon(Icons.access_time_rounded,
                                      color: Colors.white60, size: 10),
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
                    child: PremiumHeaderView(
                      imageUrl: business.headerImageUrl,
                      shopName: business.name,
                      height: 120,
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
                      child: PremiumLogoView(
                        imageUrl: business.logoUrl,
                        shopName: business.name,
                        radius: 32,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(10),
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
                                    label: tag.startsWith("Öne Çıkan")
                                        ? "Öne Çıkan"
                                        : tag,
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
                        // Minimum Sepet Tutarı
                        _buildInfoBadge(
                          Icons.shopping_bag_outlined,
                          "Min: ₺${business.minBasketAmount.toStringAsFixed(0)}",
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

  Widget _buildFilterAndSortBar(BuildContext context, WidgetRef ref,
      List<String> activeFilters, String activeSort, String activeSubcategory) {
    List<String> subcategories = [];
    if (widget.category == 'Yemek') {
      subcategories = ['Tümü', 'Restoran', 'Kafe', 'Tatlı', 'Pastane'];
    } else if (widget.category == 'Market') {
      subcategories = ['Tümü', 'Market', 'Kasap', 'Manav', 'Fırın', 'Hırdavat'];
    }

    final hasActiveFilters = activeFilters.isNotEmpty;
    final hasActiveSort = activeSort != 'Önerilen';

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 0, top: 4, bottom: 8),
      child: Row(
        children: [
          // 1. Filtrele Butonu
          InkWell(
            onTap: () => _showFilterBottomSheet(context, ref),
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasActiveFilters
                          ? const Color(0xFFFF5200)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 16,
                        color: hasActiveFilters
                            ? const Color(0xFFFF5200)
                            : Colors.grey.shade700,
                      ),
                      if (hasActiveFilters) ...[
                        const SizedBox(width: 4),
                        Text(
                          'Filtrele',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF5200),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasActiveFilters)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5200),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${activeFilters.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 2. Sırala Butonu
          InkWell(
            onTap: () => _showSortBottomSheet(context, ref),
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasActiveSort
                          ? const Color(0xFFFF5200)
                          : Colors.grey.shade300,
                      width: hasActiveSort ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 16,
                        color: hasActiveSort
                            ? const Color(0xFFFF5200)
                            : Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
                if (hasActiveSort)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5200),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        activeSort == 'Mesafe'
                            ? Icons.near_me_rounded
                            : activeSort == 'Puan'
                                ? Icons.star_rounded
                                : activeSort == 'Hız'
                                    ? Icons.access_time_rounded
                                    : Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (subcategories.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: Colors.grey.shade300,
            ),
            const SizedBox(width: 8),
            // 3. Alt Kategoriler (Yatay Scroll)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...subcategories.map((sub) {
                      final isSelected = activeSubcategory == sub;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Builder(
                          builder: (chipContext) {
                            return ChoiceChip(
                              label: Text(
                                sub,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFFFF5200),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFFFF5200)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              onSelected: (selected) {
                                ref
                                    .read(
                                        selectedBusinessSubcategoryProvider.notifier)
                                    .state = sub;
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  Scrollable.ensureVisible(
                                    chipContext,
                                    alignment: 0.5,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                });
                              },
                            );
                          }
                        ),
                      );
                    }).toList(),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final activeFilters = ref.watch(selectedBusinessFiltersProvider);
            final filterOptions = [
              {
                'label': 'Açık Olanlar',
                'value': 'Açık Olanlar',
                'icon': Icons.lock_open_rounded,
                'desc': 'Şu anda hizmet vermeye devam edenler'
              },
              {
                'label': 'Ücretsiz Teslimat',
                'value': 'Ücretsiz Teslimat',
                'icon': Icons.local_shipping_rounded,
                'desc': 'Kurye ücreti olmayan işletmeler'
              },
              {
                'label': 'Hızlı Teslimat',
                'value': 'Hızlı Teslimat',
                'icon': Icons.bolt_rounded,
                'desc': '30 dakika ve altında teslimat sunanlar'
              },
            ];

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtrele',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...filterOptions.map((opt) {
                    final isChecked = activeFilters.contains(opt['value']);
                    return CheckboxListTile(
                      value: isChecked,
                      title: Text(opt['label'] as String,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(opt['desc'] as String,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey)),
                      secondary: Icon(opt['icon'] as IconData,
                          color: isChecked
                              ? const Color(0xFFFF5200)
                              : Colors.grey),
                      activeColor: const Color(0xFFFF5200),
                      onChanged: (val) {
                        final current = List<String>.from(activeFilters);
                        if (val == true) {
                          current.add(opt['value'] as String);
                        } else {
                          current.remove(opt['value'] as String);
                        }
                        ref
                            .read(selectedBusinessFiltersProvider.notifier)
                            .state = current;
                      },
                    );
                  }),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5200),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Uygula',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final activeSort = ref.watch(selectedBusinessSortProvider);
            final sortOptions = [
              {
                'label': 'Mesafe',
                'value': 'Mesafe',
                'icon': Icons.near_me_rounded
              },
              {
                'label': 'Puan (En Yüksek)',
                'value': 'Puan',
                'icon': Icons.star_rounded
              },
              {
                'label': 'Teslimat Hızı (En Hızlı)',
                'value': 'Hız',
                'icon': Icons.access_time_rounded
              },
              {
                'label': 'Sepet Limiti (En Düşük)',
                'value': 'Sepet Limiti',
                'icon': Icons.shopping_bag_rounded
              },
            ];

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sırala',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...sortOptions.map((opt) {
                    final isSelected = activeSort == opt['value'];
                    return RadioListTile<String>(
                      value: opt['value'] as String,
                      groupValue: activeSort,
                      title: Text(opt['label'] as String,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      secondary: Icon(opt['icon'] as IconData,
                          color: isSelected
                              ? const Color(0xFFFF5200)
                              : Colors.grey),
                      activeColor: const Color(0xFFFF5200),
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(selectedBusinessSortProvider.notifier)
                              .state = val;
                          Navigator.pop(context);
                        }
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StickyFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyFilterBarDelegate({required this.child});

  @override
  double get minExtent => 60.0;

  @override
  double get maxExtent => 60.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(
          0xFFF4F7F6), // Match background color of business selection page
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyFilterBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

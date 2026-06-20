import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:hoppa/apps/consumer/business/business_provider.dart';
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/apps/consumer/address/delivery_provider.dart';
import 'package:hoppa/apps/consumer/address/address_list_page.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:latlong2/latlong.dart'; // Mesafe hesaplama için

class BusinessSelectionPage extends ConsumerWidget {
  final String? category; // Artık İşletme Türü veya Kategori filtresi olabilir

  const BusinessSelectionPage({super.key, this.category});

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const kPrimaryColor = Color(0xFF00A651);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(
          category ?? "İşletme Seçimi",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Kategoriyi temizle -> Kategori Seçimine döner
            p.Provider.of<BusinessProvider>(
              context,
              listen: false,
            ).clearCategory();
          },
        ),
      ),
      body: p.Consumer<DeliveryProvider>(
        builder: (context, deliveryProvider, child) {
          final address = deliveryProvider.selectedAddress;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ADRES KARTI ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
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
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFBFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: kPrimaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address != null
                                    ? "Teslimat: ${address.title}"
                                    : "Teslimat Adresi Seçin",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              if (address != null)
                                Text(
                                  "${address.district}, ${address.city}",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  category != null
                      ? "$category Listesi"
                      : "Yakındaki İşletmeler",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // --- İŞLETME LİSTESİ ---
              Expanded(
                child: ref.watch(consumerShopsProvider).when(
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

                    return ListView.builder(
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
                            final Distance distance = const Distance();
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
        if (!business.isOpen) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bu işletme şu anda hizmet vermiyor."),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                          color: Colors.black.withOpacity(0.1),
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
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              "4.8", // Mock Puan
                              style: TextStyle(
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

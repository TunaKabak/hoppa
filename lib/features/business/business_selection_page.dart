import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kktc_market/core/services/business_service.dart';
import 'package:kktc_market/features/business/business_provider.dart';
import 'package:kktc_market/features/home/product_provider.dart';
import 'package:kktc_market/models/business.dart';
import 'package:kktc_market/features/address/delivery_provider.dart';
import 'package:kktc_market/features/address/address_list_page.dart';
import 'package:latlong2/latlong.dart'; // Mesafe hesaplama için

class BusinessSelectionPage extends StatelessWidget {
  final String? category; // Artık İşletme Türü veya Kategori filtresi olabilir

  const BusinessSelectionPage({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    const kPrimaryColor = Color(0xFF00A651);

    return WillPopScope(
      onWillPop: () async {
        Provider.of<BusinessProvider>(context, listen: false).clearCategory();
        return false;
      },
      child: Scaffold(
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
              Provider.of<BusinessProvider>(
                context,
                listen: false,
              ).clearCategory();
            },
          ),
        ),
        body: Consumer<DeliveryProvider>(
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
                  child: StreamBuilder<List<Business>>(
                    stream: BusinessService().getBusinesses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Hata: ${snapshot.error}"));
                      }

                      var businesses = snapshot.data ?? [];

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

                      // MESAFEYE GÖRE SIRALAMA
                      if (address != null) {
                        final Distance distance = const Distance();
                        businesses.sort((a, b) {
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

                          return _buildCompactBusinessCard(
                            context,
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
      ),
    );
  }

  Widget _buildCompactBusinessCard(
    BuildContext context,
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

        final productProvider = Provider.of<ProductProvider>(
          context,
          listen: false,
        );
        final businessProvider = Provider.of<BusinessProvider>(
          context,
          listen: false,
        );

        productProvider.resetState();
        businessProvider.selectBusiness(business);
        // fetchProducts artık businessId almalı (eski marketId)
        productProvider.fetchProducts(businessId: business.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Logo Alanı
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(business.logoUrl),
                  fit: BoxFit.cover,
                  onError: (e, s) {},
                ),
                border: Border.all(color: Colors.grey.shade200),
              ),
            ),

            const SizedBox(width: 12),

            // Bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          business.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: business.isOpen
                                ? Colors.black87
                                : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!business.isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "KAPALI",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Tür ve Adres
                  Text(
                    "${business.type.label} • ${business.address}", // Türü göster
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Alt Satır (Mesafe ve Durum)
                  Row(
                    children: [
                      if (distanceText != null) ...[
                        const Icon(
                          Icons.near_me,
                          size: 14,
                          color: kPrimaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: kPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Hızlı Teslimat Rozeti
                      if (business.isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Hızlı Teslimat",
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

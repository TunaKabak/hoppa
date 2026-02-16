import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoppa/features/home/product_provider.dart';
import 'package:hoppa/features/home/widgets/modern_product_card.dart';
import 'package:hoppa/models/campaign.dart';
import 'package:hoppa/features/product/product_detail_page.dart';

class ProductSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Ürün, kategori veya marka ara...';

  @override
  TextStyle? get searchFieldStyle =>
      const TextStyle(fontSize: 16, color: Colors.grey);

  @override
  List<Widget>? buildActions(BuildContext context) {
    // Arama barının sağındaki butonlar (Temizle butonu)
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // Geri dön butonu
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // "Git" tuşuna basınca çıkan sonuçlar
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Yazarken anlık çıkan öneriler
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    // Eğer henüz ürünler yüklenmediyse provider'dan çek
    final allProducts = productProvider.products;

    // Arama Mantığı: İsim, Marka veya Kategori içinde arama yap
    final results = allProducts.where((businessProduct) {
      final q = query.toLowerCase();
      return businessProduct.product.name.toLowerCase().contains(q) ||
          businessProduct.product.brand.toLowerCase().contains(q) ||
          businessProduct.product.category.toLowerCase().contains(q) ||
          businessProduct.product.subCategory.toLowerCase().contains(q);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              query.isEmpty ? "Aramaya başlayın..." : "Sonuç bulunamadı.",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF8F9FA),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final product = results[index];

          // Find matching campaign
          Campaign? campaign;
          try {
            campaign = productProvider.activeCampaigns.firstWhere(
              (c) => c.targetProducts.contains(product.productBarcode),
            );
          } catch (_) {}

          // (inside _buildSearchResults)
          // Liste görünümünde kartları gösteriyoruz
          return SizedBox(
            height: 120, // Liste elemanı yüksekliği
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailPage(businessProduct: product),
                  ),
                );
              },
              child: ModernProductCard(
                businessProduct: product,
                isListView: true, // Yatay kart görünümü
                campaign: campaign,
              ),
            ),
          );
        },
      ),
    );
  }
}

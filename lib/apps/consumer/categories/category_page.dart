import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:hoppa/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:hoppa/shared/core/services/navigation_provider.dart';

class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kategori verilerini manuel tanımlıyoruz (İkonlar ve Renkler için)
    final List<Map<String, dynamic>> categories = [
      {'name': 'Su & İçecek', 'icon': Icons.water_drop, 'color': Colors.blue},
      {'name': 'Meyve & Sebze', 'icon': Icons.apple, 'color': Colors.green},
      {'name': 'Atıştırmalık', 'icon': Icons.cookie, 'color': Colors.orange},
      {'name': 'Fırın', 'icon': Icons.breakfast_dining, 'color': Colors.brown},
      {'name': 'Temel Gıda', 'icon': Icons.rice_bowl, 'color': Colors.amber},
      {
        'name': 'Süt & Kahvaltılık',
        'icon': Icons.egg_alt,
        'color': Colors.yellow,
      },
      {
        'name': 'Temizlik',
        'icon': Icons.cleaning_services,
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Kategoriler",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Yan yana 2 kategori
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1, // Kareye yakın
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _buildCategoryCard(context, ref, cat);
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> category,
  ) {
    return GestureDetector(
      onTap: () {
        // 1. Ürünleri bu kategoriye göre filtrele
        ref.read(selectedCatalogCategoryProvider.notifier).state = category['name'];
        ref.read(selectedCatalogSubCategoryProvider.notifier).state = 'Tümü';

        // 2. Ana Sayfaya Git (Ürünler orada listeleniyor)
        final navProvider = p.Provider.of<NavigationProvider>(
          context,
          listen: false,
        );
        navProvider.setIndex(0); // Ana Sayfa Tab'i (Index 0)
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon Alanı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (category['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(category['icon'], size: 32, color: category['color']),
            ),
            const SizedBox(height: 12),
            // İsim
            Text(
              category['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

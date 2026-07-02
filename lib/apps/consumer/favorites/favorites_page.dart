import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider, Consumer;
import 'package:hoppa/shared/models/business_product.dart';
import 'package:hoppa/apps/consumer/favorites/favorite_provider.dart';
import 'package:hoppa/apps/consumer/home/widgets/modern_product_card.dart';
import 'package:hoppa/shared/core/services/business_service.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_shop_repository.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final BusinessService _businessService = BusinessService();

  Future<List<Map<String, dynamic>>> _fetchFavoriteProducts(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Migrate from Firestore to Prisma/API 
    // Fetch products from the new backend endpoint via ConsumerShopRepository
    try {
      final repository = ref.read(consumerShopRepositoryProvider);
      return await repository.getFavoriteProducts(ids);
    } catch (e) {
      print("Error fetching favorite products from API: $e");
      
      // Fallback: If the API fails (e.g. backend not deployed yet), try old Firestore way
      List<Map<String, dynamic>> results = [];
      try {
        final futures = ids.map((id) => _db.collection('business_products').doc(id).get());
        final snapshots = await Future.wait(futures);

        for (var doc in snapshots) {
          if (doc.exists) {
            final productDoc = doc.data() as Map<String, dynamic>;
            final businessProduct = BusinessProduct.fromMap(productDoc, doc.id);
            final business = await _businessService.getBusinessById(businessProduct.businessId);
            final bool isAvailable = business != null && business.isOpen;
            
            results.add({
              'product': businessProduct,
              'isAvailable': isAvailable,
            });
          }
        }
      } catch (firestoreError) {
        print("Fallback Firestore error: $firestoreError");
      }
      return results;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final favoriteIds = favoriteProvider.favoriteProductIds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: favoriteIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz favori ürününüz bulunmuyor.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchFavoriteProducts(favoriteIds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text("Hata oluştu: ${snapshot.error}"));
                }
                
                final items = snapshot.data ?? [];
                
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.heart_broken, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Favorilerdeki ürünler silinmiş olabilir.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final BusinessProduct product = item['product'];
                    final bool isAvailable = item['isAvailable'];

                    return Stack(
                      children: [
                        ModernProductCard(
                          businessProduct: product,
                          isCompact: true,
                        ),
                        // Fallback UI for unavailable stores
                        if (!isAvailable)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "Şu An Satışı Yok",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

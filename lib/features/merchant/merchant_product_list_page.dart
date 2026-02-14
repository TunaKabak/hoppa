import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/core/services/product_service.dart';
import 'package:hoppa/models/business_product.dart';

class MerchantProductListPage extends StatefulWidget {
  final String businessId;

  const MerchantProductListPage({super.key, required this.businessId});

  @override
  State<MerchantProductListPage> createState() =>
      _MerchantProductListPageState();
}

class _MerchantProductListPageState extends State<MerchantProductListPage> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün Yönetimi"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Ürün ara...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('business_products')
            .where('businessId', isEqualTo: widget.businessId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Bir hata oluştu."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // Client-side filtering because Firestore doesn't support
          // text search easily without external services like Algolia.
          final products = docs
              .map((doc) {
                return BusinessProduct.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              })
              .where((bp) {
                final name = bp.product.name.toLowerCase();
                return name.contains(_searchQuery);
              })
              .toList();

          if (products.isEmpty) {
            return const Center(
              child: Text(
                "Ürün bulunamadı.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BusinessProduct businessProduct) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                businessProduct.product.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Detaylar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessProduct.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${businessProduct.price} ₺",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Kontroller
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Stok Düzenleme
                InkWell(
                  onTap: () => _showStockEditor(context, businessProduct),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Stok: ${businessProduct.stock.toInt()}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 14, color: Colors.blue[700]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Aç/Kapa Switch
                Row(
                  children: [
                    Text(
                      businessProduct.isAvailable ? "Satışta" : "Kapalı",
                      style: TextStyle(
                        fontSize: 12,
                        color: businessProduct.isAvailable
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: businessProduct.isAvailable,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          _productService.updateBusinessProduct(
                            businessProduct.id,
                            isAvailable: val,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStockEditor(BuildContext context, BusinessProduct product) {
    final TextEditingController controller = TextEditingController(
      text: product.stock.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Stok Güncelle"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Yeni Stok Adedi",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = double.tryParse(controller.text);
              if (newStock != null) {
                _productService.updateBusinessProduct(
                  product.id,
                  stock: newStock,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }
}

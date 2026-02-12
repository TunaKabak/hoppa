import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoppa/features/cart/cart_provider.dart';
import 'package:hoppa/models/business_product.dart';
import 'package:hoppa/features/cart/widgets/cart_price_badge.dart'; // YENİ
import 'package:provider/provider.dart';

class ProductDetailPage extends StatelessWidget {
  final BusinessProduct businessProduct;

  const ProductDetailPage({super.key, required this.businessProduct});

  @override
  Widget build(BuildContext context) {
    final product = businessProduct.product;
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              product.name,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: CartPriceBadge(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_${businessProduct.id}',
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marka (Varsa)
                  if (product.brand.isNotEmpty)
                    Text(
                      product.brand.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Ürün Adı
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fiyat ve Birim
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${businessProduct.price.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00A651), // Emerald Green
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          product.isWeighted ? '/ kg' : '/ adet',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  // Açıklama Başlığı
                  Text(
                    "Ürün Açıklaması",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Açıklama Metni
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : "Bu ürün için henüz bir açıklama eklenmemiştir.",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 100), // Alt boşluk
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        width: double.infinity,
        child: SafeArea(child: _buildCartAction(context, cartProvider)),
      ),
    );
  }

  Widget _buildCartAction(BuildContext context, CartProvider cartProvider) {
    // Sepette var mı kontrol et
    final cartItemIndex = cartProvider.items.indexWhere(
      (item) => item.businessProduct.id == businessProduct.id,
    );
    final inCart = cartItemIndex != -1;
    final quantity = inCart ? cartProvider.items[cartItemIndex].quantity : 0.0;

    if (inCart) {
      // SAYAÇ MODU
      return Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00A651)),
        ),
        child: Row(
          children: [
            // AZALT BUTONU (SOL)
            Expanded(
              child: InkWell(
                onTap: () => cartProvider.removeFromCart(businessProduct.id),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A651),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomLeft: Radius.circular(11),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ),
            ),

            // ORTA MİKTAR ALANI (BEYAZ)
            Container(
              width: 80,
              alignment: Alignment.center,
              color: Colors.white,
              child: Text(
                quantity % 1 == 0
                    ? quantity.toInt().toString()
                    : quantity.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00A651), // Green text
                ),
              ),
            ),

            // ARTIR BUTONU (SAĞ)
            Expanded(
              child: InkWell(
                onTap: () => cartProvider.addToCart(businessProduct),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A651),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(11),
                      bottomRight: Radius.circular(11),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // EKLE MODU
      return ElevatedButton(
        onPressed: () async {
          final result = await cartProvider.addToCart(businessProduct);
          if (context.mounted) {
            _handleAddToCartResult(context, result);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A651),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined),
            const SizedBox(width: 10),
            Text(
              "Sepete Ekle",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _handleAddToCartResult(BuildContext context, AddToCartResult result) {
    if (result == AddToCartResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text("${businessProduct.product.name} sepete eklendi"),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00A651),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (result == AddToCartResult.marketConflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Farklı bir marketten ürün ekleyemezsiniz. Önce sepeti temizleyin.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } else if (result == AddToCartResult.outOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Üzgünüz, stok yetersiz."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

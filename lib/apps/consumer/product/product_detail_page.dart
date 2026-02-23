import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoppa/apps/consumer/cart/cart_provider.dart';
import 'package:hoppa/shared/models/business_product.dart';
import 'package:hoppa/shared/models/campaign.dart'; // Campaigns
import 'package:hoppa/shared/core/services/campaign_service.dart'; // Campaign Service
import 'package:hoppa/shared/core/services/navigation_provider.dart'; // Navigation Provider
import 'package:hoppa/apps/consumer/cart/widgets/cart_price_badge.dart'; // YENİ
import 'package:provider/provider.dart';

class ProductDetailPage extends StatefulWidget {
  final BusinessProduct businessProduct;

  const ProductDetailPage({super.key, required this.businessProduct});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isActionLoading = false;

  Future<void> _handleCartAction(Future<void> Function() action) async {
    if (_isActionLoading) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.businessProduct.product;
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Campaign>>(
        stream: CampaignService().getActiveCampaigns(
          widget.businessProduct.businessId,
        ),
        builder: (context, snapshot) {
          final campaigns = snapshot.data ?? [];
          Campaign? activeCampaign;
          double price = widget.businessProduct.price;

          if (campaigns.isNotEmpty) {
            try {
              activeCampaign = campaigns.firstWhere(
                (c) => c.targetProducts.contains(
                  widget.businessProduct.productBarcode,
                ),
              );
              price = activeCampaign.calculateDiscountedPrice(price);
            } catch (_) {}
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.black12,
                surfaceTintColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: CartPriceBadge(
                      onTap: () {
                        // Detail'dan çık
                        Navigator.pop(context);
                        // Sepet tab'ine geç
                        Provider.of<NavigationProvider>(
                          context,
                          listen: false,
                        ).setIndex(2);
                      },
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ürün Resmi
                      Center(
                        child: Hero(
                          tag: 'product_${widget.businessProduct.id}',
                          child: Stack(
                            children: [
                              Container(
                                height: 250,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.contain,
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
                              if (activeCampaign != null)
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      activeCampaign.type ==
                                              CampaignType.percentage
                                          ? "%${activeCampaign.discountValue.toStringAsFixed(0)} İndirim"
                                          : "İndirimli Ürün",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                          if (activeCampaign != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 12,
                                bottom: 4,
                              ),
                              child: Text(
                                '₺${widget.businessProduct.price.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          Text(
                            '₺${price.toStringAsFixed(2)}',
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
          );
        },
      ),
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        width: double.infinity,
        child: SafeArea(child: _buildCartAction(context, cartProvider)),
      ),
    );
  }

  Widget _buildCartAction(BuildContext context, CartProvider cartProvider) {
    // Sepette var mı kontrol et
    final cartItemIndex = cartProvider.items.indexWhere(
      (item) => item.businessProduct.id == widget.businessProduct.id,
    );
    final inCart = cartItemIndex != -1;
    final quantity = inCart ? cartProvider.items[cartItemIndex].quantity : 0.0;
    final isWeighted = widget.businessProduct.product.isWeighted;

    if (inCart) {
      // SAYAÇ MODU (Separate Buttons like Home Page)
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // AZALT / SİL BUTONU
          _buildCounterButton(
            icon:
                (isWeighted && quantity <= 0.51) ||
                    (!isWeighted && quantity <= 1.01)
                ? Icons.delete_outline
                : Icons.remove,
            onTap: () {
              _handleCartAction(() async {
                await Future.delayed(const Duration(milliseconds: 200));
                await cartProvider.removeFromCart(widget.businessProduct.id);
              });
            },
          ),

          // ORTA MİKTAR ALANI
          _isActionLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF00A651),
                    ),
                  ),
                )
              : Text(
                  quantity % 1 == 0
                      ? quantity.toInt().toString()
                      : quantity.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00A651), // Green text
                  ),
                ),

          // ARTIR BUTONU
          _buildCounterButton(
            icon: Icons.add,
            onTap: () {
              _handleCartAction(() async {
                await Future.delayed(const Duration(milliseconds: 200));
                await cartProvider.addToCart(widget.businessProduct);
              });
            },
            isAdd: true,
          ),
        ],
      );
    } else {
      // EKLE MODU
      return SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _isActionLoading
              ? null
              : () {
                  _handleCartAction(() async {
                    final result = await cartProvider.addToCart(
                      widget.businessProduct,
                    );
                    if (mounted) {
                      _handleAddToCartResult(context, result);
                    }
                  });
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A651), // Standard Green
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: const Color(0xFF00A651).withAlpha(102),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isActionLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
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
        ),
      );
    }
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isAdd = false,
  }) {
    return InkWell(
      onTap: _isActionLoading ? null : onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle, // Circle like Home Page
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF00A651).withAlpha(77),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: _isActionLoading ? Colors.grey : const Color(0xFF00A651),
          size: 28,
        ),
      ),
    );
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
                child: Text(
                  "${widget.businessProduct.product.name} sepete eklendi",
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF81C784), // Match soft green
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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

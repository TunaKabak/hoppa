import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoppa/models/business_product.dart';
import 'package:hoppa/features/cart/cart_provider.dart';

class ModernProductCard extends StatelessWidget {
  final BusinessProduct businessProduct;
  final bool isListView;
  final bool isCompact;

  const ModernProductCard({
    super.key,
    required this.businessProduct,
    this.isListView = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = businessProduct.product;
    final cartProvider = Provider.of<CartProvider>(context);

    // Sepetteki miktar kontrolü
    double quantity = 0;
    final cartItemIndex = cartProvider.items.indexWhere(
      (item) => item.businessProduct.id == businessProduct.id,
    );
    if (cartItemIndex >= 0) {
      quantity = cartProvider.items[cartItemIndex].quantity;
    }

    // --- LIST VIEW LAYOUT ---
    if (isListView) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: quantity > 0
                ? const Color(0xFF00A651) // Hoppa green for items in cart
                : Colors.grey.shade200,
            width: quantity > 0 ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: isCompact ? 70 : 100,
              height: isCompact ? 70 : 100,
              decoration: BoxDecoration(
                color: Colors.grey[50], // Fallback color
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover, // Grid ile tutarlı olsun
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey[300],
                                  );
                                },
                              )
                            : Icon(Icons.image, color: Colors.grey[300]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.brand,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${businessProduct.price.toStringAsFixed(2)} ₺",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      _buildQuantityControl(
                        context,
                        quantity,
                        theme,
                        isSmall: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // --- GRID VIEW LAYOUT (Standard) ---
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: quantity > 0
              ? const Color(0xFF00A651) // Hoppa green for items in cart
              : Colors.grey.shade100,
          width: quantity > 0 ? 2.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.zero, // Padding tamamen kaldırıldı
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    // ClipRRect eklendi
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover, // BoxFit.cover yapıldı
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[300],
                                  size: 40,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.grey[300],
                              size: 40,
                            ),
                          ),
                  ),
                ),

                // --- MİKTAR KONTROLÜ (Sağa Hizalı) ---
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _buildQuantityControl(context, quantity, theme),
                ),
              ],
            ),
          ),

          // Details Area
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 9, // Smaller font
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12, // Smaller font
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.isWeighted ? "Kg Fiyatı" : "Adet Fiyatı",
                        style: TextStyle(color: Colors.grey[400], fontSize: 9),
                      ),
                    ],
                  ),
                  // Fiyat
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${businessProduct.price.toStringAsFixed(2)} ₺",
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 15, // Slightly smaller
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(
    BuildContext context,
    double quantity,
    ThemeData theme, {
    bool isSmall = false,
  }) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isWeighted = businessProduct.product.isWeighted;

    // 1. Durum: Sepette yok veya miktar 0 -> "Ekle" butonu (+)
    if (quantity <= 0) {
      return GestureDetector(
        onTap: () {
          _handleAdd(context, cartProvider);
        },
        child: Container(
          width: isSmall ? 28 : 32, // More compact
          height: isSmall ? 28 : 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
          ),
          child: Icon(
            Icons.add,
            color: theme.primaryColor,
            size: isSmall ? 18 : 20,
          ),
        ),
      );
    }

    // 2. Durum: Sepette var -> [- Miktar +] kontrolü
    return Container(
      height: isSmall ? 28 : 32, // Compact height
      constraints: const BoxConstraints(minWidth: 80), // Ensure minimum width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AZALT BUTONU veya SİLME İKONU
          GestureDetector(
            onTap: () {
              cartProvider.removeFromCart(businessProduct.id);
            },
            child: Container(
              width: isSmall ? 28 : 30,
              alignment: Alignment.center,
              child: Icon(
                (isWeighted && quantity <= 0.51) ||
                        (!isWeighted && quantity <= 1.01)
                    ? Icons.delete_outline
                    : Icons.remove,
                color: theme.primaryColor,
                size: isSmall ? 16 : 18,
              ),
            ),
          ),

          // MİKTAR TEXT
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
            ), // Tighter padding
            alignment: Alignment.center,
            constraints: const BoxConstraints(minWidth: 20),
            child: Text(
              isWeighted
                  ? quantity.toStringAsFixed(1)
                  : quantity.toInt().toString(),
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13, // Smaller font
              ),
            ),
          ),

          // ARTIR BUTONU
          GestureDetector(
            onTap: () {
              _handleAdd(context, cartProvider);
            },
            child: Container(
              width: isSmall ? 28 : 30,
              alignment: Alignment.center,
              child: Icon(
                Icons.add,
                color: theme.primaryColor,
                size: isSmall ? 16 : 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAdd(BuildContext context, CartProvider cartProvider) async {
    final result = await cartProvider.addToCart(businessProduct);
    if (!context.mounted) return;
    if (result == AddToCartResult.marketConflict) {
      _showErrorDialog(context, cartProvider);
    } else if (result == AddToCartResult.outOfStock) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Stok yetersiz!")));
    }
  }

  void _showErrorDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Farklı İşletme"),
        content: const Text(
          "Sepetinizde başka bir işletmeye ait ürünler var. Sepeti temizleyip bu ürünü eklemek ister misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cartProvider.clearCart(deleteFromDb: true);
              cartProvider.addToCart(businessProduct);
            },
            child: const Text(
              "Sepeti Temizle ve Ekle",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

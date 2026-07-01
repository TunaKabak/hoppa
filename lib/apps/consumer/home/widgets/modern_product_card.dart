import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:hoppa/shared/models/business_product.dart';
import 'package:hoppa/apps/consumer/cart/cart_provider.dart';
import 'package:hoppa/shared/models/campaign.dart';
import 'package:hoppa/apps/consumer/favorites/favorite_provider.dart';
import 'package:hoppa/apps/consumer/auth/consumer_login_page.dart';
import 'package:core_auth/core_auth.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:hoppa/shared/core/utils/quantity_formatter.dart';

class ModernProductCard extends ConsumerWidget {
  final BusinessProduct businessProduct;
  final bool isListView;
  final bool isCompact;
  final Campaign? campaign;

  const ModernProductCard({
    super.key,
    required this.businessProduct,
    this.isListView = false,
    this.isCompact = false,
    this.campaign,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final product = businessProduct.product;
    final cart = ref.watch(cartProvider);
    
    // Doğru dükkan aktiflik kontrolü (Seçili dükkana göre değil, ürünün kendi dükkanına göre)
    final shopsAsync = ref.watch(consumerShopsProvider);
    final shops = shopsAsync.value ?? [];
    bool isClosed = false;
    if (shops.isNotEmpty) {
      try {
        final shop = shops.firstWhere((s) => s.id == businessProduct.businessId);
        isClosed = !shop.isOpen;
      } catch (_) {}
    }

    // Sepetteki miktar kontrolü
    double quantity = 0;
    final cartItemIndex = cart.items.indexWhere(
      (item) => item.businessProduct.id == businessProduct.id,
    );
    if (cartItemIndex >= 0) {
      quantity = cart.items[cartItemIndex].quantity;
    }

    final double regularPrice = businessProduct.regularPrice;
    final double price = businessProduct.price;
    final int discountRate = businessProduct.discountRate;

    double activePrice = price;
    double? oldPrice;
    int activeDiscountRate = discountRate;

    if (discountRate > 0) {
      oldPrice = regularPrice;
      activePrice = price;
    }

    if (campaign != null) {
      final campaignPrice = campaign!.calculateDiscountedPrice(price);
      if (campaignPrice < activePrice) {
        oldPrice = price;
        activePrice = campaignPrice;
        activeDiscountRate = (((price - campaignPrice) / price) * 100).round();
      }
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200, width: 1),
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
                                fit: BoxFit.cover,
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
                  if (activeDiscountRate > 0)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          '%$activeDiscountRate İNDİRİM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _buildFavoriteButton(context, ref),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (oldPrice != null)
                            Text(
                              "${oldPrice.toStringAsFixed(2)} TL",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            "${activePrice.toStringAsFixed(2)} TL / ${product.unit}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: oldPrice != null ? Colors.red : theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      _buildQuantityControl(
                        context,
                        ref,
                        quantity,
                        theme,
                        isClosed,
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
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
                if (activeDiscountRate > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        '%$activeDiscountRate İNDİRİM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // FAVORITE BUTTON
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildFavoriteButton(context, ref),
                ),

                // --- MİKTAR KONTROLÜ (Sağa Hizalı) ---
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _buildQuantityControl(context, ref, quantity, theme, isClosed),
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
                        "${product.unit.toUpperCase()} Fiyatı",
                        style: TextStyle(color: Colors.grey[400], fontSize: 9),
                      ),
                    ],
                  ),
                  // Fiyat
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (oldPrice != null)
                          Text(
                            "${oldPrice.toStringAsFixed(2)} TL",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          "${activePrice.toStringAsFixed(2)} TL / ${product.unit}",
                          style: TextStyle(
                            color: oldPrice != null ? Colors.red : theme.primaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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
    WidgetRef ref,
    double quantity,
    ThemeData theme,
    bool isClosed, {
    bool isSmall = false,
  }) {
    final minQty = businessProduct.product.minQuantity;

    // 1. Durum: Sepette yok veya miktar 0 -> "Ekle" butonu (+)
    if (quantity <= 0) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isClosed ? null : () {
            _handleAdd(context, ref);
          },
          child: Container(
            width: isSmall ? 28 : 32, // More compact
            height: isSmall ? 28 : 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Icon(
              Icons.add,
              color: isClosed ? Colors.grey : theme.primaryColor,
              size: isSmall ? 18 : 20,
            ),
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AZALT BUTONU veya SİLME İKONU
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                ref.read(cartProvider.notifier).removeFromCart(businessProduct.id);
              },
              child: Container(
                width: isSmall ? 28 : 30,
                alignment: Alignment.center,
                child: Icon(
                  quantity <= minQty + 0.001
                      ? Icons.delete_outline
                      : Icons.remove,
                  color: theme.primaryColor,
                  size: isSmall ? 16 : 18,
                ),
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
              QuantityFormatter.formatValue(quantity),
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13, // Smaller font
              ),
            ),
          ),

          // ARTIR BUTONU
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: isClosed ? null : () {
                _handleAdd(context, ref);
              },
              child: Container(
                width: isSmall ? 28 : 30,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  color: isClosed ? Colors.grey : theme.primaryColor,
                  size: isSmall ? 16 : 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAdd(BuildContext context, WidgetRef ref) {
    try {
      ref.read(cartProvider.notifier).addToCart(businessProduct);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains("Farklı bir dükkandan") || msg.contains("sepeti temizlemelisiniz")) {
        _showErrorDialog(context, ref);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.replaceAll("Exception: ", ""))),
        );
      }
    }
  }

  void _showErrorDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Farklı Dükkan"),
        content: const Text(
          "Sepetinizde başka bir dükkana ait ürünler var. Sepeti temizleyip bu dükkandan devam etmek ister misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(cartProvider.notifier).clearCart();
              ref.read(cartProvider.notifier).addToCart(businessProduct);
            },
            child: const Text(
              "Sepeti Temizle ve Ekle",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context, WidgetRef ref) {
    return p.Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        final isFavorite = favoriteProvider.isFavorite(businessProduct.id);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              final authState = ref.read(authControllerProvider);

              if (authState is! AuthAuthenticated) {
                // Yönlendirme
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              } else {
                favoriteProvider.toggleFavorite(businessProduct.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey[400],
                size: 18,
               ),
            ),
          ),
        );
      },
    );
  }
}

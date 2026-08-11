import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:consumer_app/apps/consumer/cart/cart_provider.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:consumer_app/apps/consumer/cart/cart_page.dart';
import 'package:core_shared/shared/models/business.dart';

class FloatingCartCard extends ConsumerWidget {
  const FloatingCartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    if (cartState.carts.isEmpty) {
      return const SizedBox.shrink();
    }

    final shopsAsync = ref.watch(consumerShopsProvider);
    final shops = shopsAsync.value ?? [];

    if (cartState.hasMultipleCarts) {
      // MULTI-MERCHANT FLOATING BAR DESIGN
      final activeCartsList = cartState.carts.values.toList();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE95D22), // Hoppa Orange
              Color(0xFFFF8C00), // Orange-Yellow
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE95D22).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => const CartPage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // OVERLAPPING SHOP AVATARS
                  SizedBox(
                    width: 54,
                    height: 40,
                    child: Stack(
                      children: List.generate(
                        activeCartsList.length.clamp(0, 3),
                        (index) {
                          final cart = activeCartsList[index];
                          return Positioned(
                            left: index * 16.0,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE95D22), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: cart.businessLogoUrl != null && cart.businessLogoUrl!.isNotEmpty
                                    ? Image.network(
                                        cart.businessLogoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.storefront_rounded,
                                          color: Color(0xFFE95D22),
                                          size: 18,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.storefront_rounded,
                                        color: Color(0xFFE95D22),
                                        size: 18,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // TEXT DETAILS
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${cartState.carts.length} İşletmede Sepet',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${cartState.totalItemCountAllCarts} Ürün',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Toplam: ₺${cartState.grandTotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // RIGHT ACTION & ARROW
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "İncele",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // SINGLE MERCHANT FLOATING BAR DESIGN
    Business? shop;
    if (cartState.currentBusinessId != null && shops.isNotEmpty) {
      for (final s in shops) {
        if (s.id == cartState.currentBusinessId) {
          shop = s;
          break;
        }
      }
    }

    final shopName = shop?.name ?? (cartState.activeCart?.businessName ?? "Sepetiniz");
    final shopLogoUrl = shop?.logoUrl ?? (cartState.activeCart?.businessLogoUrl ?? "");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 62,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE95D22), // Hoppa Orange
            Color(0xFFFF8C00), // Orange-Yellow
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE95D22).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => const CartPage(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // DÜKKAN LOGOSU / İKONU
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: shopLogoUrl.isNotEmpty
                        ? Image.network(
                            shopLogoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFFE95D22),
                              size: 22,
                            ),
                          )
                        : const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFFE95D22),
                            size: 22,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // DÜKKAN ADI VE ÜRÜN SAYISI
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cartState.items.length} Ürün',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Sepeti İncele",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // TOPLAM FİYAT & OK İKONU
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₺${cartState.totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


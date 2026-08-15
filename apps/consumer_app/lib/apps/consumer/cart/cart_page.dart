import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:consumer_app/apps/consumer/cart/cart_provider.dart';
import 'package:consumer_app/apps/consumer/checkout/checkout_page.dart';
import 'package:core_shared/shared/core/services/navigation_provider.dart';
import 'package:core_shared/shared/models/cart_item.dart';
import 'package:consumer_app/apps/consumer/home/widgets/modern_product_card.dart';
import 'package:core_shared/shared/models/campaign.dart';
import 'package:consumer_app/apps/consumer/address/delivery_provider.dart';
import 'package:consumer_app/apps/consumer/business/business_provider.dart';
import 'package:consumer_app/apps/consumer/cart/widgets/compact_delivery_status.dart';
import 'package:consumer_app/apps/consumer/cart/widgets/compact_checkout_bar.dart';
import 'package:consumer_app/apps/consumer/auth/consumer_login_page.dart';
import 'package:core_auth/core_auth.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_dialog.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:consumer_app/apps/consumer/main_layout/controllers/floating_nav_controller.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  String _groupBy = 'none';
  final ScrollController _tabsScrollController = ScrollController();

  @override
  void dispose() {
    _tabsScrollController.dispose();
    super.dispose();
  }

  void _handleClose(BuildContext context) {
    ref.read(floatingNavControllerProvider.notifier).showBars();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      p.Provider.of<NavigationProvider>(context, listen: false).setIndex(0);
    }
  }

  void _scrollToTab(int index) {
    if (!_tabsScrollController.hasClients) return;
    const double estimatedTabWidth = 175.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = (index * estimatedTabWidth) - (screenWidth / 2) + (estimatedTabWidth / 2);
    final maxScroll = _tabsScrollController.position.maxScrollExtent;
    final minScroll = _tabsScrollController.position.minScrollExtent;

    _tabsScrollController.animateTo(
      targetOffset.clamp(minScroll, maxScroll),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final businessProvider = p.Provider.of<BusinessProvider>(context);
    final deliveryProvider = p.Provider.of<DeliveryProvider>(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedBusiness = businessProvider.selectedBusiness;
    
    // Check if campaign gives free delivery
    bool hasFreeDeliveryCampaign = false;
    final campaignsAsync = ref.watch(cartCampaignsProvider);
    final activeCampaigns = campaignsAsync.value ?? [];
    if (activeCampaigns.any((c) => c.type.name.toUpperCase() == "FREE_DELIVERY_FIRST_ORDERS")) {
      hasFreeDeliveryCampaign = true; // Temporary optimistic UI logic
    }

    double deliveryFee = selectedBusiness?.baseDeliveryFee ?? 30.0;
    
    // Apply free delivery threshold logic
    if (selectedBusiness?.freeDeliveryThreshold != null && 
        cartState.totalAmount >= selectedBusiness!.freeDeliveryThreshold!) {
      deliveryFee = 0.0;
    }
    
    // Apply campaign logic
    if (hasFreeDeliveryCampaign) {
      deliveryFee = 0.0;
    }

    final double finalTotal = cartState.totalAmount > 0
        ? cartState.totalAmount + deliveryFee
        : 0;

    final requiredMinAmount = getRequiredMinAmount(
      selectedBusiness,
      deliveryProvider.selectedAddress,
    );

    final bool canCheckout = cartState.totalAmount >= requiredMinAmount;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE95D22), // Hoppa Orange
              Color(0xFFFF8C00), // Orange-Yellow
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          children: [
            HoppaHeader(
              height: 70,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => _handleClose(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Sepetim",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (cartState.carts.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              cartState.hasMultipleCarts
                                  ? "${cartState.carts.length} İşletmede Aktif Sepet"
                                  : (selectedBusiness?.name ?? "Sepet"),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (cartState.carts.isNotEmpty)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (cartState.hasMultipleCarts) {
                              _showClearCartOptionsSheet(context, ref.read(cartProvider.notifier), cartState);
                            } else {
                              final activeId = cartState.currentBusinessId;
                              if (activeId != null) {
                                _showClearSingleCartDialog(
                                  context,
                                  ref.read(cartProvider.notifier),
                                  cartState.carts[activeId],
                                );
                              } else {
                                _showClearCartDialog(context, ref.read(cartProvider.notifier));
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 40), // Denge için
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: cartState.carts.isEmpty
                      ? _buildEmptyCart(context, colorScheme)
                      : Column(
                          children: [
                            // ÇOKLU İŞLETME SEKMELERİ (MULTIPLE CARTS SELECTOR)
                            if (cartState.hasMultipleCarts)
                              _buildBusinessCartTabs(context, cartState, businessProvider),

                            CompactDeliveryStatus(
                              currentCartTotal: cartState.totalAmount,
                              minOrderLimit: requiredMinAmount,
                              freeDeliveryLimit: hasFreeDeliveryCampaign ? 0.0 : (selectedBusiness?.freeDeliveryThreshold ?? 0.0),
                            ),
                            if (cartState.items.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: Colors.white,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.filter_list,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Grupla: ",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    DropdownButton<String>(
                                      value: _groupBy,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'none',
                                          child: Text("Listele (Varsayılan)"),
                                        ),
                                        DropdownMenuItem(
                                          value: 'category',
                                          child: Text("Kategoriye Göre"),
                                        ),
                                        DropdownMenuItem(
                                          value: 'brand',
                                          child: Text("Markaya Göre"),
                                        ),
                                      ],
                                      onChanged: (val) => setState(() => _groupBy = val!),
                                      underline: Container(),
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: colorScheme.primary,
                                      ),
                                      isDense: true,
                                    ),
                                  ],
                                ),
                              ),

                            Expanded(
                              child: _groupBy == 'none'
                                  ? ListView.separated(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: cartState.items.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 16),
                                      itemBuilder: (context, index) {
                                        final item = cartState.items[index];
                                        Campaign? campaign;
                                        try {
                                          campaign = activeCampaigns.firstWhere(
                                            (c) => c.targetProducts.contains(
                                              item.businessProduct.productBarcode,
                                            ),
                                          );
                                        } catch (_) {}

                                        return ModernProductCard(
                                          businessProduct: item.businessProduct,
                                          cartItem: item,
                                          isListView: true,
                                          isCompact: true,
                                          campaign: campaign,
                                        );
                                      },
                                    )
                                  : _buildGroupedList(cartState, activeCampaigns, colorScheme),
                            ),

                            TextButton.icon(
                              onPressed: () {
                                ref.read(floatingNavControllerProvider.notifier).showBars();
                                if (cartState.items.isNotEmpty) {
                                  try {
                                    final shopId = cartState.items.first.businessProduct.businessId;
                                    final shopsAsync = ref.read(consumerShopsProvider);
                                    final shops = shopsAsync.value ?? [];
                                    final shop = shops.firstWhere((s) => s.id == shopId);
                                    
                                    businessProvider.setCategory(shop.type.label);
                                    businessProvider.selectBusiness(shop);
                                    
                                    p.Provider.of<NavigationProvider>(context, listen: false).setIndex(0);
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    _handleClose(context);
                                  }
                                } else {
                                  _handleClose(context);
                                }
                              },
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text(
                                "Alışverişe Devam Et",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(double.infinity, 36),
                                foregroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                            CompactCheckoutBar(
                              subTotal: cartState.totalAmount,
                              deliveryFee: deliveryFee,
                              total: finalTotal,
                              canCheckout: canCheckout,
                              onCheckout: () {
                                final authState = ref.read(authControllerProvider);
                                if (authState is! AuthAuthenticated) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).push(
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(fromCheckout: true),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CheckoutPage(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCartTabs(
    BuildContext context,
    CartState cartState,
    BusinessProvider businessProvider,
  ) {
    return Container(
      height: 64,
      width: double.infinity,
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cartState.carts.length,
        itemBuilder: (context, index) {
          final cart = cartState.carts.values.elementAt(index);
          final isSelected = cart.businessId == cartState.currentBusinessId;

          return Builder(
            builder: (itemContext) {
              if (isSelected) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (itemContext.mounted) {
                    Scrollable.ensureVisible(
                      itemContext,
                      alignment: 0.5,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                });
              }

              return GestureDetector(
                onTap: () {
                  ref.read(cartProvider.notifier).selectActiveCart(cart.businessId);
                  Scrollable.ensureVisible(
                    itemContext,
                    alignment: 0.5,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  );
                  final shopsAsync = ref.read(consumerShopsProvider);
                  final shops = shopsAsync.value ?? [];
                  try {
                    final shop = shops.firstWhere((s) => s.id == cart.businessId);
                    businessProvider.selectBusiness(shop);
                  } catch (_) {}
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF0EB) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE95D22) : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFE95D22).withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
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
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                cart.businessName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFFE95D22) : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.check_circle,
                                  size: 13,
                                  color: Color(0xFFE95D22),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            "${cart.totalItemCount} Ürün • ₺${cart.subtotal.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? const Color(0xFFE95D22).withValues(alpha: 0.8) : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showClearSingleCartDialog(
                          context,
                          ref.read(cartProvider.notifier),
                          cart,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }


  Widget _buildGroupedList(CartState cartState, List<Campaign> activeCampaigns, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    Map<String, List<CartItem>> groups = {};
    for (var item in cartState.items) {
      String key = _groupBy == 'brand'
          ? item.businessProduct.product.brand
          : item.businessProduct.product.category;
      if (key.isEmpty) key = 'Diğer';
      if (!groups.containsKey(key)) groups[key] = [];
      groups[key]!.add(item);
    }

    var sortedKeys = groups.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        String key = sortedKeys[index];
        List<CartItem> items = groups[key]!;
        double groupTotal = items.fold(
          0,
          (sum, item) => sum + (item.businessProduct.price * item.quantity),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 4.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      key.toUpperCase(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Text(
                    "${groupTotal.toStringAsFixed(2)} ₺",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.highlight_remove,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                    tooltip: "$key grubunu sil",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showRemoveGroupDialog(context, ref.read(cartProvider.notifier), key),
                  ),
                ],
              ),
            ),
            ...items.map((item) {
              Campaign? campaign;
              try {
                campaign = activeCampaigns.firstWhere(
                  (c) => c.targetProducts.contains(
                    item.businessProduct.productBarcode,
                  ),
                );
              } catch (_) {}

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ModernProductCard(
                  businessProduct: item.businessProduct,
                  cartItem: item,
                  isListView: true,
                  isCompact: true,
                  campaign: campaign,
                ),
              );
            }),
            Divider(height: 30, color: Colors.grey.shade300),
          ],
        );
      },
    );
  }

  void _showRemoveGroupDialog(
    BuildContext context,
    CartNotifier cartNotifier,
    String groupName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("$groupName Silinsin mi?"),
        content: const Text("Bu gruptaki tüm ürünler sepetinden kaldırılacak."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              cartNotifier.removeGroup(_groupBy, groupName);
              Navigator.pop(context);
            },
            child: const Text(
              "Evet, Sil",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyCart(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: colorScheme.secondary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          const Text(
            "Sepetin Boş",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Hadi, lezzetli bir şeyler ekleyelim!",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _handleClose(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Alışverişe Başla"),
          ),
        ],
      ),
    );
  }

  void _showClearCartOptionsSheet(
    BuildContext context,
    CartNotifier cartNotifier,
    CartState cartState,
  ) {
    final activeId = cartState.currentBusinessId;
    final activeCart = activeId != null ? cartState.carts[activeId] : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.delete_sweep_outlined, color: Color(0xFFE53935), size: 22),
                SizedBox(width: 8),
                Text(
                  "Sepeti Boşalt",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activeCart != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_outlined, color: Color(0xFFE95D22), size: 22),
                  ),
                  title: const Text(
                    "Bu İşletmenin Sepetini Boşalt",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    "${activeCart.businessName} (${activeCart.totalItemCount} ürün)",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showClearSingleCartDialog(context, cartNotifier, activeCart);
                  },
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_forever_outlined, color: Color(0xFFE53935), size: 22),
                ),
                title: const Text(
                  "Tüm Sepetleri Boşalt",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE53935)),
                ),
                subtitle: Text(
                  "${cartState.carts.length} farklı işletmedeki tüm ürünler temizlenir",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFE53935)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showClearCartDialog(context, cartNotifier);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartNotifier cartNotifier) {
    showDialog(
      context: context,
      builder: (context) => HoppaDialog(
        icon: Icons.delete_sweep_outlined,
        iconColor: const Color(0xFFFF5200),
        title: "Tüm Sepetleri Boşalt",
        content: "Tüm işletmelerdeki sepetlerinizi temizlemek istediğinize emin misiniz?",
        cancelText: "Vazgeç",
        confirmText: "Evet, Hepsini Boşalt",
        isDestructive: true,
        onCancel: () => Navigator.pop(context),
        onConfirm: () {
          cartNotifier.clearCart();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showClearSingleCartDialog(
    BuildContext context,
    CartNotifier cartNotifier,
    BusinessCart? businessCart,
  ) {
    if (businessCart == null) return;
    showDialog(
      context: context,
      builder: (context) => HoppaDialog(
        icon: Icons.delete_outline,
        iconColor: const Color(0xFFFF5200),
        title: "${businessCart.businessName} Sepeti Boşaltılsın mı?",
        content: "Bu işletmedeki tüm ürünler sepetinizden kaldırılacaktır.",
        cancelText: "Vazgeç",
        confirmText: "Evet, Boşalt",
        isDestructive: true,
        onCancel: () => Navigator.pop(context),
        onConfirm: () {
          cartNotifier.clearCart(businessCart.businessId);
          Navigator.pop(context);
        },
      ),
    );
  }
}


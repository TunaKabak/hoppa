import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/apps/consumer/cart/cart_provider.dart';
import 'package:hoppa/apps/consumer/checkout/checkout_page.dart';
import 'package:hoppa/shared/core/services/navigation_provider.dart';
import 'package:hoppa/apps/consumer/home/widgets/modern_product_card.dart';
import 'package:hoppa/shared/models/campaign.dart';
import 'package:hoppa/apps/consumer/address/delivery_provider.dart';
import 'package:hoppa/apps/consumer/business/business_provider.dart';
import 'package:hoppa/apps/consumer/cart/widgets/compact_delivery_status.dart';
import 'package:hoppa/apps/consumer/cart/widgets/compact_checkout_bar.dart';
import 'package:hoppa/apps/consumer/auth/consumer_login_page.dart';
import 'package:core_auth/core_auth.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  String _groupBy = 'none';

  void _handleClose(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      p.Provider.of<NavigationProvider>(context, listen: false).setIndex(0);
    }
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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Sepetim",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context),
        ),
        actions: [
          if (cartState.items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: colorScheme.error),
              tooltip: "Tüm Sepeti Boşalt",
              onPressed: () => _showClearCartDialog(context, ref.read(cartProvider.notifier)),
            ),
        ],
      ),
      body: cartState.items.isEmpty
          ? _buildEmptyCart(context, colorScheme)
          : Column(
              children: [
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
                              isListView: true,
                              isCompact: true,
                              campaign: campaign,
                            );
                          },
                        )
                      : _buildGroupedList(cartState, activeCampaigns, colorScheme),
                ),

                TextButton.icon(
                  onPressed: () => _handleClose(context),
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
                          builder: (context) => const LoginPage(),
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

  void _showClearCartDialog(BuildContext context, CartNotifier cartNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sepeti Boşalt"),
        content: const Text(
          "Sepetindeki tüm ürünleri silmek istediğine emin misin?",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              cartNotifier.clearCart();
              Navigator.pop(context);
            },
            child: const Text(
              "Evet, Boşalt",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

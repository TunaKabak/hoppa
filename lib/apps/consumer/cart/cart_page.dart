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
import 'package:hoppa/apps/consumer/cart/widgets/min_cart_amount_progress.dart';
import 'package:hoppa/apps/consumer/services/customer_auth_service.dart';
import 'package:hoppa/apps/consumer/auth/consumer_login_page.dart';
import 'package:core_auth/core_auth.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _isExpanded = false;
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

    const double deliveryFee = 20.0;
    final double finalTotal = cartState.totalAmount > 0
        ? cartState.totalAmount + deliveryFee
        : 0;

    final requiredMinAmount = getRequiredMinAmount(
      businessProvider.selectedBusiness,
      deliveryProvider.selectedAddress,
    );

    final bool canCheckout = cartState.totalAmount >= requiredMinAmount;

    final campaignsAsync = ref.watch(cartCampaignsProvider);
    final activeCampaigns = campaignsAsync.value ?? [];

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
                if (requiredMinAmount > 0)
                  MinCartAmountProgress(
                    currentAmount: cartState.totalAmount,
                    minAmount: requiredMinAmount,
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

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isExpanded
                              ? Column(
                                  children: [
                                    _summaryRow(
                                      "Ara Toplam",
                                      "${cartState.totalAmount.toStringAsFixed(2)} ₺",
                                    ),
                                    const SizedBox(height: 12),
                                    _summaryRow(
                                      "Teslimat Ücreti",
                                      "${deliveryFee.toStringAsFixed(2)} ₺",
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Divider(),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        GestureDetector(
                          onTap: () =>
                              setState(() => _isExpanded = !_isExpanded),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "Genel Toplam",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _isExpanded
                                        ? Icons.keyboard_arrow_down
                                        : Icons.keyboard_arrow_up,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                  if (!_isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: Text(
                                        "(Detay)",
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                "${finalTotal.toStringAsFixed(2)} ₺",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canCheckout
                                  ? colorScheme.primary
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: canCheckout
                                ? () {
                                    final authState = ref.read(authControllerProvider);
                                    if (authState is! AuthAuthenticated) {
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage(),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CheckoutPage(),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            child: Text(
                              canCheckout
                                  ? "Sepeti Onayla"
                                  : "Minimum Tutar Sağlanamadı",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        if (!_isExpanded) ...[
                          const SizedBox(
                            height: 8,
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                              ),
                              onPressed: () => _handleClose(context),
                              child: const Text(
                                "Alışverişe Devam Et",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
                      color: Colors.red.withOpacity(0.7),
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

  Widget _summaryRow(
    String title,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isBold ? Colors.black : Colors.grey,
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.black,
            fontSize: isBold ? 20 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
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
            color: colorScheme.secondary.withOpacity(0.2),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoppa/apps/merchant/services/merchant_auth_service.dart';
import 'package:hoppa/shared/core/services/business_service.dart';
import 'package:hoppa/apps/merchant/auth/merchant_login_page.dart';
import 'package:hoppa/apps/merchant/merchant_dashboard_page.dart';
import 'package:hoppa/apps/merchant/merchant_order_list_page.dart';
import 'package:hoppa/apps/merchant/merchant_product_list_page.dart';
import 'package:hoppa/apps/merchant/merchant_settings_page.dart';
import 'package:hoppa/apps/merchant/merchant_analytics_page.dart';

final GlobalKey<ScaffoldState> merchantDrawerKey = GlobalKey<ScaffoldState>();

class MerchantMainLayout extends StatefulWidget {
  final String businessId;
  const MerchantMainLayout({super.key, required this.businessId});

  @override
  State<MerchantMainLayout> createState() => _MerchantMainLayoutState();
}

class _MerchantMainLayoutState extends State<MerchantMainLayout> {
  int _selectedIndex = 0;
  String _businessName = 'İşletme Paneli';

  @override
  void initState() {
    super.initState();
    _loadBusinessName();
  }

  Future<void> _loadBusinessName() async {
    try {
      final business = await BusinessService().getBusinessById(
        widget.businessId,
      );
      if (business != null && mounted) {
        setState(() => _businessName = business.name);
      }
    } catch (_) {}
  }

  List<Widget> get _pages => [
    MerchantDashboardPage(businessId: widget.businessId),
    MerchantOrderListPage(businessId: widget.businessId),
    MerchantProductListPage(businessId: widget.businessId),
    MerchantAnalyticsPage(businessId: widget.businessId),
    MerchantSettingsPage(businessId: widget.businessId),
  ];

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.receipt_long_rounded, 'Siparişler'),
    _NavItem(Icons.inventory_2_rounded, 'Ürünler'),
    _NavItem(Icons.analytics_rounded, 'Raporlar'),
    _NavItem(Icons.settings_rounded, 'Ayarlar'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: merchantDrawerKey,
      drawer: _buildDrawer(theme, colorScheme),
      body: IndexedStack(index: _selectedIndex, children: _pages),
    );
  }

  Widget _buildDrawer(ThemeData theme, ColorScheme colorScheme) {
    return Drawer(
      child: Column(
        children: [
          // ─── DRAWER HEADER ───
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo / Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _businessName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'İşletme Paneli',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── NAV ITEMS ───
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: Icon(
                      item.icon,
                      color: isSelected
                          ? colorScheme.secondary
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected
                            ? colorScheme.secondary
                            : colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    selected: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selectedTileColor: colorScheme.secondary.withValues(
                      alpha: 0.08,
                    ),
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      Navigator.pop(context); // Drawer'ı kapat
                    },
                  ),
                );
              },
            ),
          ),

          // ─── LOGOUT ───
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade400,
                size: 22,
              ),
              title: Text(
                'Çıkış Yap',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () async {
                final authService = Provider.of<MerchantAuthService>(
                  context,
                  listen: false,
                );
                await authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

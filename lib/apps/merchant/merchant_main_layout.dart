import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoppa/apps/merchant/services/merchant_auth_service.dart';
import 'package:hoppa/shared/core/services/business_service.dart';
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/apps/merchant/auth/merchant_login_page.dart';
import 'package:hoppa/apps/merchant/merchant_dashboard_page.dart';
import 'package:hoppa/apps/merchant/merchant_order_list_page.dart';
import 'package:hoppa/apps/merchant/merchant_product_list_page.dart';
import 'package:hoppa/apps/merchant/merchant_settings_page.dart';
import 'package:hoppa/apps/merchant/merchant_analytics_page.dart';
import 'package:hoppa/apps/merchant/campaign/merchant_campaigns_page.dart';
import 'package:hoppa/apps/merchant/admin/admin_approvals_page.dart';
import 'package:hoppa/apps/merchant/auth/merchant_auth_wrapper.dart' as hoppa_wrapper;

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
  String _storeRole = 'employee'; // default

  String _activeBusinessId = '';
  List<Business> _allBusinesses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeBusinessId = widget.businessId;
    _initData();
  }

  @override
  void dispose() {
    _businessesSub?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    await _loadStoreRole();
    if (_storeRole == 'super_admin') {
      await _loadAllBusinesses();
      if (_activeBusinessId.isEmpty && _allBusinesses.isNotEmpty) {
        _activeBusinessId = _allBusinesses.first.id;
      }
    }
    if (_activeBusinessId.isNotEmpty) {
      await _loadBusinessName();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  StreamSubscription<List<Business>>? _businessesSub;

  Future<void> _loadAllBusinesses() async {
    try {
      // First, await the future to quickly get the initial state and unblock init
      final list = await BusinessService().getBusinessesFuture();
      if (mounted) {
        setState(() {
          _allBusinesses = list;
        });
      }

      // Then setup real-time listener for future updates (e.g. after approval)
      _businessesSub?.cancel();
      _businessesSub = BusinessService().getBusinesses().listen((updatedList) {
        if (mounted) {
          setState(() {
            _allBusinesses = updatedList;
            if (_activeBusinessId.isEmpty && _allBusinesses.isNotEmpty) {
              _activeBusinessId = _allBusinesses.first.id;
              _loadBusinessName();
            }
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _loadBusinessName() async {
    if (_activeBusinessId.isEmpty) return;
    try {
      final business = await BusinessService().getBusinessById(
        _activeBusinessId,
      );
      if (business != null && mounted) {
        setState(() => _businessName = business.name);
      }
    } catch (_) {}
  }

  Future<void> _loadStoreRole() async {
    final authService = Provider.of<MerchantAuthService>(
      context,
      listen: false,
    );
    final userData = await authService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _storeRole = userData['role'] == 'super_admin'
            ? 'super_admin'
            : (userData['storeRole'] ??
                  'employee'); // admin, manager, employee vs
      });
    }
  }

  bool get _canSeeCampaigns =>
      _storeRole == 'admin' ||
      _storeRole == 'manager' ||
      _storeRole == 'store_manager' ||
      _storeRole == 'super_admin';

  List<Widget> get _pages {
    if (_isLoading) {
      return [const Center(child: CircularProgressIndicator())];
    }
    final pages = [
      MerchantDashboardPage(
        key: ValueKey('dash_$_activeBusinessId'),
        businessId: _activeBusinessId,
      ),
      MerchantOrderListPage(
        key: ValueKey('orders_$_activeBusinessId'),
        businessId: _activeBusinessId,
      ),
      MerchantProductListPage(
        key: ValueKey('prods_$_activeBusinessId'),
        businessId: _activeBusinessId,
      ),
      MerchantAnalyticsPage(
        key: ValueKey('analy_$_activeBusinessId'),
        businessId: _activeBusinessId,
      ),
    ];
    if (_canSeeCampaigns) {
      pages.add(
        MerchantCampaignsPage(
          key: ValueKey('camp_$_activeBusinessId'),
          businessId: _activeBusinessId,
        ),
      );
    }
    if (_storeRole == 'super_admin') {
      pages.add(
        const AdminApprovalsPage(key: ValueKey('admin_approvals')),
      );
    }
    pages.add(
      MerchantSettingsPage(
        key: ValueKey('set_$_activeBusinessId'),
        businessId: _activeBusinessId,
      ),
    );
    return pages;
  }

  List<_NavItem> get _navItems {
    final items = [
      const _NavItem(Icons.dashboard_rounded, 'Dashboard'),
      const _NavItem(Icons.receipt_long_rounded, 'Siparişler'),
      const _NavItem(Icons.inventory_2_rounded, 'Ürünler'),
      const _NavItem(Icons.analytics_rounded, 'Raporlar'),
    ];
    if (_canSeeCampaigns) {
      items.add(const _NavItem(Icons.campaign_rounded, 'Kampanyalar'));
    }
    if (_storeRole == 'super_admin') {
      items.add(const _NavItem(Icons.admin_panel_settings_rounded, 'Başvurular'));
    }
    items.add(const _NavItem(Icons.settings_rounded, 'Ayarlar'));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        // Eğer dashboard'da değilsek, önce dashboard'a dön.
        setState(() {
          _selectedIndex = 0;
        });
      },
      child: Scaffold(
        key: merchantDrawerKey,
        drawer: _buildDrawer(theme, colorScheme),
        body: IndexedStack(index: _selectedIndex, children: _pages),
      ),
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

                // Market Selector Dropdown for Super Admin
                if (_storeRole == 'super_admin')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _activeBusinessId.isEmpty ? null : _activeBusinessId,
                        hint: const Text("Aktif Market Yok"),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme.primary,
                        ),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        items: _allBusinesses.map((Business b) {
                          return DropdownMenuItem<String>(
                            value: b.id,
                            child: Text(
                              b.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (newVal) async {
                          if (newVal != null && newVal != _activeBusinessId) {
                            setState(() {
                              _activeBusinessId = newVal;
                              _isLoading = true;
                            });
                            await _loadBusinessName();
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                      ),
                    ),
                  )
                else
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
                  child: Text(
                    _storeRole == 'super_admin'
                        ? 'Super Admin Bypassed'
                        : 'İşletme Paneli',
                    style: const TextStyle(
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
                    MaterialPageRoute(builder: (_) => const hoppa_wrapper.MerchantAuthWrapper()),
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

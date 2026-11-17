import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_shared/shared/models/business.dart';
import 'package:core_shared/shared/models/order_status.dart';
import 'package:merchant_app/apps/merchant/providers/merchant_api_providers.dart';
import 'package:merchant_app/apps/merchant/repositories/merchant_order_repository.dart';
import 'package:merchant_app/apps/merchant/auth/merchant_login_page.dart';
import 'package:merchant_app/apps/merchant/merchant_dashboard_page.dart';
import 'package:merchant_app/apps/merchant/merchant_order_list_page.dart';
import 'package:merchant_app/apps/merchant/merchant_product_list_page.dart';
import 'package:merchant_app/apps/merchant/merchant_settings_page.dart';
import 'package:merchant_app/apps/merchant/merchant_analytics_page.dart';
import 'package:merchant_app/apps/merchant/campaign/merchant_shop_campaigns_page.dart';
import 'package:merchant_app/apps/merchant/merchant_sponsorship_page.dart';
import 'package:merchant_app/apps/merchant/admin/admin_approvals_page.dart';
import 'package:merchant_app/apps/merchant/admin/admin_business_categories_page.dart';
import 'package:merchant_app/apps/merchant/auth/merchant_auth_wrapper.dart' as hoppa_wrapper;
import 'package:core_shared/shared/core/services/notification_service.dart';

final GlobalKey<ScaffoldState> merchantDrawerKey = GlobalKey<ScaffoldState>();

class MerchantNavigationIndex extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int value) {
    state = value;
  }
}
final merchantNavigationIndexProvider = NotifierProvider<MerchantNavigationIndex, int>(MerchantNavigationIndex.new);

class MerchantMainLayout extends ConsumerStatefulWidget {
  final String businessId;
  const MerchantMainLayout({super.key, required this.businessId});

  @override
  ConsumerState<MerchantMainLayout> createState() => _MerchantMainLayoutState();
}

class _MerchantMainLayoutState extends ConsumerState<MerchantMainLayout> {
  String _businessName = 'İşletme Paneli';
  
  String _activeBusinessId = '';
  List<Business> _allBusinesses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeBusinessId = widget.businessId;
    _initData();

    // Firebase Cloud Messaging ve Notification kurulumu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final apiClient = ref.read(apiClientProvider);
        final notificationService = NotificationService(apiClient);
        notificationService.initialize();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initData() async {
    final authState = ref.read(authControllerProvider);
    if (authState is AuthAuthenticated) {
      if (authState.user.isSuperAdmin) {
        await _loadAllBusinesses();
        if (!mounted) return;
        if (_activeBusinessId.isEmpty ||
            !_allBusinesses.any((b) => b.id == _activeBusinessId)) {
          _activeBusinessId =
              _allBusinesses.isNotEmpty ? _allBusinesses.first.id : '';
        }
        ref.read(apiClientProvider).activeBusinessId =
            _activeBusinessId.isNotEmpty ? _activeBusinessId : null;
        ref
            .read(selectedMerchantBusinessIdProvider.notifier)
            .setSelectedId(_activeBusinessId);
      } else {
        ref.read(apiClientProvider).activeBusinessId = null;
        ref.read(selectedMerchantBusinessIdProvider.notifier).setSelectedId('');
      }
      if (_activeBusinessId.isNotEmpty) {
        await _loadBusinessName();
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllBusinesses() async {
    final byId = <String, Business>{};
    try {
      final res = await ref
          .read(apiClientProvider)
          .get('/api/consumer/shops', requiresAuth: false);
      final rawShops = res['data'];
      if (rawShops is List) {
        for (final raw in rawShops) {
          if (raw is! Map) continue;
          final map = Map<String, dynamic>.from(raw);
          final id = map['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          final normalized = <String, dynamic>{
            ...map,
            if ((map['address'] == null || map['address'].toString().isEmpty) &&
                map['fullAddress'] != null)
              'address': map['fullAddress'],
            if ((map['logoUrl'] == null || map['logoUrl'].toString().isEmpty) &&
                map['imageUrl'] != null)
              'logoUrl': map['imageUrl'],
            if (map['isOpen'] == null && map['isActive'] != null)
              'isOpen': map['isActive'],
          };
          byId[id] = Business.fromMap(normalized, id);
        }
      }
    } catch (e) {
      debugPrint('🚨 Aktif dükkan listesi alınamadı: $e');
    }

    try {
      final res = await ref
          .read(apiClientProvider)
          .get('/api/admin/merchants/pending?status=ALL');
      final rawList = res['data'];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is! Map) continue;
          final shopMap = item['shop'];
          if (shopMap is! Map) continue;
          final shopId = shopMap['id']?.toString() ?? '';
          if (shopId.isEmpty || byId.containsKey(shopId)) continue;
          final shopName = shopMap['name']?.toString() ??
              item['businessName']?.toString() ??
              'İsimsiz İşletme';
          byId[shopId] = Business(
            id: shopId,
            name: shopName,
            address: item['fullAddress']?.toString() ?? '',
            phone: (item['businessPhone'] ?? item['ownerPhone'] ?? '').toString(),
            logoUrl: '',
            headerImageUrl: '',
            isOpen: shopMap['isActive'] == true,
            type: BusinessType.fromString(
              (shopMap['type'] ?? item['merchantType'] ?? 'market').toString(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🚨 Tüm admin işletme listesi alınamadı: $e');
    }

    if (mounted && byId.isNotEmpty) {
      final merged = byId.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _allBusinesses = merged;
      });
    }
  }

  Future<void> _switchBusiness(String newVal) async {
    if (merchantDrawerKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    ref.read(apiClientProvider).activeBusinessId = newVal;
    final selected = _allBusinesses.where((b) => b.id == newVal);
    setState(() {
      _activeBusinessId = newVal;
      if (selected.isNotEmpty) {
        _businessName = selected.first.name;
      }
    });
    ref.read(selectedMerchantBusinessIdProvider.notifier).setSelectedId(newVal);
  }

  Future<void> _loadBusinessName() async {
    if (_activeBusinessId.isEmpty) return;
    
    final authState = ref.read(authControllerProvider);
    if (authState is AuthAuthenticated && !authState.user.isSuperAdmin) {
      return;
    }

    if (_allBusinesses.isNotEmpty) {
      try {
        final business = _allBusinesses.firstWhere((b) => b.id == _activeBusinessId);
        setState(() => _businessName = business.name);
      } catch (_) {}
    }
  }

  bool _canSeeCampaigns(AuthUser user) =>
      user.role == 'admin' ||
      user.role == 'manager' ||
      user.role == 'store_manager' ||
      user.role == 'merchant' ||
      user.isSuperAdmin;

  List<Widget> _getPages(AuthUser user) {
    final List<Widget> pages = [
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
        isActiveTab: ref.watch(merchantNavigationIndexProvider) == 2,
      ),
      MerchantAnalyticsPage(
        key: ValueKey('analy_$_activeBusinessId'),
        businessId: _activeBusinessId,
      ),
    ];
    if (_canSeeCampaigns(user)) {
      pages.add(
        MerchantShopCampaignsPage(
          key: ValueKey('shop_camp_$_activeBusinessId'),
        ),
      );
    }
    pages.add(
      MerchantSponsorshipPage(
        key: ValueKey('spons_$_activeBusinessId'),
        businessId: _activeBusinessId,
      ),
    );
    if (user.isSuperAdmin) {
      pages.add(
        const AdminApprovalsPage(key: ValueKey('admin_approvals')),
      );
      pages.add(
        const AdminBusinessCategoriesPage(key: ValueKey('admin_categories')),
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

  List<_NavItem> _getNavItems(AuthUser user) {
    final items = [
      const _NavItem(Icons.dashboard_rounded, 'Dashboard'),
      const _NavItem(Icons.receipt_long_rounded, 'Siparişler'),
      const _NavItem(Icons.inventory_2_rounded, 'Ürünler'),
      const _NavItem(Icons.analytics_rounded, 'Raporlar'),
    ];
    if (_canSeeCampaigns(user)) {
      items.add(const _NavItem(Icons.campaign_rounded, 'Kampanya & Reklam'));
    }
    items.add(const _NavItem(Icons.bolt_rounded, 'Öne Çıkarma'));
    if (user.isSuperAdmin) {
      items.add(const _NavItem(Icons.admin_panel_settings_rounded, 'Başvurular'));
      items.add(const _NavItem(Icons.category_rounded, 'İşletme Kategorileri'));
    }
    items.add(const _NavItem(Icons.settings_rounded, 'Ayarlar'));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authControllerProvider);

    if (authState is! AuthAuthenticated) {
      return const LoginPage();
    }

    final user = authState.user;
    final pages = _getPages(user);
    final selectedIndex = ref.watch(merchantNavigationIndexProvider);
    final safeIndex = selectedIndex.clamp(0, pages.length - 1);
    final settingsIndex = pages.length - 1;
    final pendingOrdersCount = _isLoading
        ? 0
        : (ref.watch(merchantOrdersProvider).asData?.value ?? const [])
            .where((o) => o.status == OrderStatus.pending.value)
            .length;
    final int? activeBottomIndex = safeIndex == 0
        ? 0
        : safeIndex == 1
            ? 1
            : safeIndex == 2
                ? 2
                : safeIndex == settingsIndex
                    ? 3
                    : null;

    return PopScope(
      canPop: safeIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(merchantNavigationIndexProvider.notifier).setIndex(0);
      },
      child: Scaffold(
        key: merchantDrawerKey,
        drawer: _buildDrawer(theme, colorScheme, user),
        body: _isLoading
            ? const HoppaListCardSkeleton(itemCount: 4)
            : IndexedStack(index: safeIndex, children: pages),
        bottomNavigationBar: _isLoading
            ? null
            : NavigationBar(
                selectedIndex: activeBottomIndex ?? 0,
                indicatorColor: activeBottomIndex == null
                    ? Colors.transparent
                    : colorScheme.primary.withValues(alpha: 0.14),
                onDestinationSelected: (idx) {
                  final mappedIndex = switch (idx) {
                    0 => 0,
                    1 => 1,
                    2 => 2,
                    _ => settingsIndex,
                  };
                  ref
                      .read(merchantNavigationIndexProvider.notifier)
                      .setIndex(mappedIndex);
                },
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Özet',
                  ),
                  NavigationDestination(
                    icon: Badge.count(
                      count: pendingOrdersCount,
                      isLabelVisible: pendingOrdersCount > 0,
                      backgroundColor: HoppaDesignTokens.statusDanger,
                      child: const Icon(Icons.receipt_long_outlined),
                    ),
                    selectedIcon: Badge.count(
                      count: pendingOrdersCount,
                      isLabelVisible: pendingOrdersCount > 0,
                      backgroundColor: HoppaDesignTokens.statusDanger,
                      child: const Icon(Icons.receipt_long_rounded),
                    ),
                    label: 'Siparişler',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2_rounded),
                    label: 'Ürünler',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Ayarlar',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme, ColorScheme colorScheme, AuthUser user) {
    final navItems = _getNavItems(user);
    final shopState = ref.watch(shopControllerProvider);
    final String currentBusinessName = user.isSuperAdmin
        ? _businessName
        : (shopState.value?.name ?? user.businessName ?? 'İşletme Paneli');
    
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
                if (user.isSuperAdmin)
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
                        value: _allBusinesses.any((b) => b.id == _activeBusinessId)
                            ? _activeBusinessId
                            : null,
                        hint: const Text("İşletme Seçin"),
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
                        onChanged: (newVal) {
                          if (newVal != null && newVal != _activeBusinessId) {
                            unawaited(_switchBusiness(newVal));
                          }
                        },
                      ),
                    ),
                  )
                else
                  Text(
                    currentBusinessName,
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
                    user.isSuperAdmin
                        ? 'Super Admin Mode'
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
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = ref.watch(merchantNavigationIndexProvider) == index;
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
                      ref.read(merchantNavigationIndexProvider.notifier).setIndex(index);
                      Navigator.pop(context); // Drawer'ı kapat
                    },
                  ),
                );
              },
            ),
          ),

          // ─── THEME TOGGLE & LOGOUT ───
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              secondary: Icon(
                ref.watch(merchantThemeModeProvider) == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: colorScheme.primary,
              ),
              title: const Text(
                'Karanlık Mod',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              value: ref.watch(merchantThemeModeProvider) == ThemeMode.dark,
              onChanged: (isDark) {
                ref
                    .read(merchantThemeModeProvider.notifier)
                    .setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
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
                final confirmed = await showHoppaConfirmDialog(
                  context,
                  title: 'Çıkış Yap',
                  message:
                      'İşletme panelinden çıkış yapmak istediğinize emin misiniz? Aktif sipariş bildirimleri duraklatılacaktır.',
                  confirmText: 'Çıkış Yap',
                  cancelText: 'Vazgeç',
                  isDestructive: true,
                  icon: Icons.logout_rounded,
                );
                if (!confirmed || !mounted) return;
                ref.read(merchantNavigationIndexProvider.notifier).setIndex(0);
                await ref.read(authControllerProvider.notifier).logout();
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

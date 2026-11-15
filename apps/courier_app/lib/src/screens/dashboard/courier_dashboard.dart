import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_network/core_network.dart';
import '../../models/courier_models.dart';
import '../../services/location_service.dart';
import '../../utils/distance_formatter.dart';
import '../../widgets/courier_order_card.dart';
import '../auth/courier_login_screen.dart';
import '../history/courier_history_tab.dart';
import '../onboarding/courier_status_gate_screen.dart';

class CourierDashboardPage extends ConsumerStatefulWidget {
  const CourierDashboardPage({super.key});

  @override
  ConsumerState<CourierDashboardPage> createState() =>
      _CourierDashboardPageState();
}

class _CourierDashboardPageState extends ConsumerState<CourierDashboardPage> {
  static const Color _hoppaOrange = Color(0xFFFF6B00);
  static const Color _hoppaGreen = Color(0xFF00A651);

  late final CourierLocationEngine _locationEngine;
  Timer? _autoRefreshTimer;

  CourierProfile? _profile;
  List<CourierOrder> _activeOrders = const [];
  final Set<String> _processingOrderIds = <String>{};

  bool _isOnDuty = false;
  bool _isLoadingProfile = false;
  bool _isLoadingOrders = false;
  bool _isTogglingDuty = false;
  String? _profileError;
  String? _ordersError;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _locationEngine = CourierLocationEngine(ref.read(apiClientProvider));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(authControllerProvider) is AuthAuthenticated) {
        _initializeCourierSession();
      }
    });
  }

  @override
  void dispose() {
    _stopAutoRefreshTimer();
    _locationEngine.dispose();
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    _stopAutoRefreshTimer();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      if (ref.read(authControllerProvider) is! AuthAuthenticated) return;
      if (_profile?.isApproved != true) return;
      if (_selectedTabIndex == 0 && !_isLoadingOrders && !_isLoadingProfile) {
        _fetchActiveOrders(silent: true);
      }
    });
  }

  void _stopAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> _initializeCourierSession() async {
    await _fetchProfileAndSync();
    if (mounted && _profile?.isApproved == true) {
      _startAutoRefreshTimer();
    }
  }

  void _resetSessionState() {
    _stopAutoRefreshTimer();
    unawaited(_locationEngine.stopTracking());
    if (!mounted) return;
    setState(() {
      _profile = null;
      _activeOrders = const [];
      _processingOrderIds.clear();
      _isOnDuty = false;
      _isLoadingProfile = false;
      _isLoadingOrders = false;
      _isTogglingDuty = false;
      _profileError = null;
      _ordersError = null;
      _selectedTabIndex = 0;
    });
  }

  Future<void> _handleLogout() async {
    _resetSessionState();
    await ref.read(authControllerProvider.notifier).logout();
  }

  Future<void> _fetchProfileAndSync({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _isLoadingProfile = true;
        _profileError = null;
      });
    }

    try {
      final response = await ref.read(apiClientProvider).get('/api/couriers/me');
      final rawData = response['data'];
      if (rawData is! Map) {
        throw Exception('Beklenmeyen profil yanıt formatı.');
      }
      final profile = CourierProfile.fromJson(
        Map<String, dynamic>.from(rawData),
      );
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _isOnDuty = profile.isApproved ? profile.isActive : false;
        _profileError = null;
        _isLoadingProfile = false;
      });

      if (profile.isApproved) {
        await _syncLocationTracking(_isOnDuty);
        await _fetchActiveOrders(silent: silent);
        if (_autoRefreshTimer == null) {
          _startAutoRefreshTimer();
        }
      } else {
        _stopAutoRefreshTimer();
        await _syncLocationTracking(false);
      }
    } on AppException catch (e) {
      debugPrint('🚨 Kurye profili alınamadı: ${e.message}');
      if (!mounted) return;
      setState(() {
        _profileError = e.message;
        _isLoadingProfile = false;
      });
    } catch (e) {
      debugPrint('🚨 Kurye profili alınamadı: $e');
      if (!mounted) return;
      setState(() {
        _profileError = 'Profil yüklenemedi: $e';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _syncLocationTracking(bool shouldTrack) async {
    if (shouldTrack && !_locationEngine.isTracking) {
      try {
        await _locationEngine.startTracking();
      } catch (e) {
        debugPrint('🚨 Konum takibi başlatılamadı: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum takibi başlatılamadı: $e'),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (!shouldTrack && _locationEngine.isTracking) {
      await _locationEngine.stopTracking();
    }
  }

  Future<void> _fetchActiveOrders({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _isLoadingOrders = true;
        _ordersError = null;
      });
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .get('/api/couriers/orders');
      final rawList = response['data'];
      final orders = rawList is List
          ? rawList
                .whereType<Map>()
                .map(
                  (item) =>
                      CourierOrder.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <CourierOrder>[];

      if (!mounted) return;
      setState(() {
        _activeOrders = orders;
        _ordersError = null;
      });
    } on AppException catch (e) {
      debugPrint('🚨 Aktif siparişler alınamadı: ${e.message}');
      if (!mounted) return;
      setState(() => _ordersError = e.message);
    } catch (e) {
      debugPrint('🚨 Aktif siparişler alınamadı: $e');
      if (!mounted) return;
      setState(() => _ordersError = 'Siparişler yüklenemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    }
  }

  Future<void> _refreshDashboard() async {
    await _fetchProfileAndSync(silent: true);
  }

  Future<void> _toggleDuty(bool val) async {
    if (_isTogglingDuty) return;
    setState(() => _isTogglingDuty = true);

    try {
      await ref
          .read(apiClientProvider)
          .put('/api/couriers/toggle-duty', body: {'isActive': val});

      if (!mounted) return;
      setState(() {
        _isOnDuty = val;
      });

      await _syncLocationTracking(val);
      if (val) {
        await _fetchActiveOrders(silent: true);
      }
    } on AppException catch (e) {
      debugPrint('🚨 Nöbet durumu değiştirilemedi: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nöbet durumu güncellenemedi: ${e.message}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('🚨 Nöbet durumu değiştirilemedi: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nöbet durumu güncellenemedi: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTogglingDuty = false);
    }
  }

  Future<void> _pickupOrder(String orderId) async {
    if (_processingOrderIds.contains(orderId)) return;
    setState(() => _processingOrderIds.add(orderId));

    try {
      await ref
          .read(apiClientProvider)
          .put('/api/couriers/orders/$orderId/pickup');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sipariş mağazadan teslim alındı! Müşteriye doğru yola çıkabilirsiniz.',
          ),
          backgroundColor: _hoppaGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchActiveOrders(silent: true);
    } on AppException catch (e) {
      debugPrint('🚨 Sipariş teslim alma hatası: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('🚨 Sipariş teslim alma hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem tamamlanamadı: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingOrderIds.remove(orderId));
      }
    }
  }

  Future<void> _deliverOrder(String orderId) async {
    if (_processingOrderIds.contains(orderId)) return;
    setState(() => _processingOrderIds.add(orderId));

    try {
      await ref
          .read(apiClientProvider)
          .put('/api/couriers/orders/$orderId/deliver');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş teslim edildi olarak işaretlendi!'),
          backgroundColor: _hoppaGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchProfileAndSync(silent: true);
    } on AppException catch (e) {
      debugPrint('🚨 Sipariş teslim tamamlama hatası: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('🚨 Sipariş teslim tamamlama hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem tamamlanamadı: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingOrderIds.remove(orderId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthAuthenticated && previous is! AuthAuthenticated) {
        _initializeCourierSession();
      } else if (next is! AuthAuthenticated && previous is AuthAuthenticated) {
        _resetSessionState();
      }
    });

    if (authState is AuthChecking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.two_wheeler_rounded, size: 52, color: _hoppaOrange),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (authState is! AuthAuthenticated) {
      return const CourierLoginScreen();
    }

    if (_isLoadingProfile && _profile == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text(
                'Kurye profiliniz yükleniyor...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (_profile == null && _profileError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Hoppa Kurye',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Çıkış Yap',
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 60,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 14),
                Text(
                  _profileError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => _fetchProfileAndSync(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!profile.isApproved) {
      return CourierStatusGateScreen(
        profile: profile,
        onRefresh: () => _fetchProfileAndSync(),
        onLogout: _handleLogout,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hoppa Kurye',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              profile.displayName,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.only(left: 10, right: 4),
            decoration: BoxDecoration(
              color: _isOnDuty
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isOnDuty ? 'NÖBETTE' : 'PASİF',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    color: _isOnDuty
                        ? const Color(0xFF166534)
                        : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _isOnDuty,
                  activeThumbColor: _hoppaGreen,
                  activeTrackColor: _hoppaGreen.withValues(alpha: 0.35),
                  onChanged: _isTogglingDuty ? null : _toggleDuty,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış Yap',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildActiveTasksTab(profile),
          const CourierHistoryTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        indicatorColor: _hoppaOrange.withValues(alpha: 0.14),
        onDestinationSelected: (index) {
          setState(() => _selectedTabIndex = index);
          if (index == 0) {
            _fetchActiveOrders(silent: true);
          }
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _activeOrders.isNotEmpty,
              label: Text('${_activeOrders.length}'),
              child: const Icon(Icons.delivery_dining_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _activeOrders.isNotEmpty,
              label: Text('${_activeOrders.length}'),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: _hoppaOrange,
              ),
            ),
            label: 'Aktif Görevler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded, color: _hoppaOrange),
            label: 'Geçmiş & Kazanç',
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTasksTab(CourierProfile profile) {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ValueListenableBuilder<Position?>(
        valueListenable: _locationEngine.latestPosition,
        builder: (context, position, _) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildDutyBanner(profile),
              const SizedBox(height: 12),
              _buildAssignedShopsSection(profile.shops),
              const SizedBox(height: 16),

              if (_ordersError != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _ordersError!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_isLoadingOrders && _activeOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!_isOnDuty && _activeOrders.isEmpty)
                _buildOfflinePlaceholder()
              else if (_activeOrders.isEmpty)
                _buildEmptyOrdersPlaceholder()
              else ...[
                if (_activeOrders.length > 1)
                  _buildMultiOrderRouteCard(position),
                ..._activeOrders.map(
                  (order) => CourierOrderCard(
                    order: order,
                    courierLatitude: position?.latitude,
                    courierLongitude: position?.longitude,
                    isActionLoading: _processingOrderIds.contains(order.id),
                    onPickup: _pickupOrder,
                    onDeliver: _deliverOrder,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDutyBanner(CourierProfile profile) {
    final bool gpsActive = _locationEngine.isTracking;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOnDuty
              ? const [Color(0xFF00A651), Color(0xFF059669)]
              : const [Color(0xFF334155), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isOnDuty
                  ? Icons.gps_fixed_rounded
                  : Icons.power_settings_new_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnDuty ? 'Nöbet Aktif • Siparişe Hazır' : 'Nöbet Kapalı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isOnDuty
                      ? (gpsActive
                            ? 'Canlı GPS konumu paylaşılıyor • Bugün ${profile.todayDeliveriesCount} teslimat'
                            : 'GPS izni bekleniyor • Bugün ${profile.todayDeliveriesCount} teslimat')
                      : 'Yeni sipariş alabilmek için sağ üstten nöbeti açın.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedShopsSection(List<CourierAssignedShop> shops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atanmış Mağazalar',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        if (shops.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 6),
                Text(
                  'Tüm uygun mağazalar / Genel havuz',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: shops
                .map(
                  (assigned) => Chip(
                    avatar: const Icon(
                      Icons.storefront_rounded,
                      size: 16,
                      color: _hoppaOrange,
                    ),
                    label: Text(
                      assigned.displayName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildOfflinePlaceholder() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
        child: Column(
          children: [
            Icon(
              Icons.power_settings_new_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            const Text(
              'Şu Anda Çevrimdışısınız',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sipariş alabilmek ve canlı konum akıtmak için sağ üstten nöbetinizi aktif edin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersPlaceholder() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
        child: Column(
          children: [
            Icon(
              Icons.two_wheeler_rounded,
              size: 64,
              color: _hoppaOrange.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            const Text(
              'Aktif Göreviniz Bulunmuyor',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Yeni siparişler atandığında burada otomatik olarak görünecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiOrderRouteCard(Position? courierPosition) {
    final firstOrder = _activeOrders.first;
    final startLat =
        courierPosition?.latitude ?? firstOrder.shop?.latitude;
    final startLng =
        courierPosition?.longitude ?? firstOrder.shop?.longitude;

    final pendingPoints = <({CourierOrder order, double lat, double lng})>[];
    for (final order in _activeOrders) {
      final lat = order.isAwaitingPickup
          ? order.shop?.latitude
          : order.address?.latitude;
      final lng = order.isAwaitingPickup
          ? order.shop?.longitude
          : order.address?.longitude;
      if (lat != null && lng != null) {
        pendingPoints.add((order: order, lat: lat, lng: lng));
      }
    }

    if (startLat == null || startLng == null || pendingPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final remaining = List.of(pendingPoints);
    final ordered = <({CourierOrder order, double legKm})>[];
    double currentLat = startLat;
    double currentLng = startLng;
    double totalKm = 0.0;

    while (remaining.isNotEmpty) {
      int bestIdx = 0;
      double bestDist = double.infinity;
      for (int i = 0; i < remaining.length; i++) {
        final dist = calculateDistanceKm(
          lat1: currentLat,
          lon1: currentLng,
          lat2: remaining[i].lat,
          lon2: remaining[i].lng,
        );
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }
      final chosen = remaining.removeAt(bestIdx);
      ordered.add((order: chosen.order, legKm: bestDist));
      totalKm += bestDist;
      currentLat = chosen.lat;
      currentLng = chosen.lng;
    }

    final estMinutes = ((totalKm / 35.0) * 60.0).round() + 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route_rounded, color: _hoppaGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Önerilen Teslimat Sırası • ${formatDistance(totalKm)} (~$estMinutes dk)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(ordered.length, (i) {
            final entry = ordered[i];
            final target = entry.order.isAwaitingPickup
                ? (entry.order.shop?.name ?? 'Mağaza')
                : (entry.order.consumer?.fullName ?? 'Müşteri');
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${i + 1}. ${entry.order.displayOrderNumber} • $target (${formatDistance(entry.legKm)})',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF14532D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

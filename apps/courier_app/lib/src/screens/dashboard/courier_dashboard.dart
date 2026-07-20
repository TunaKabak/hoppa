import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:core_auth/core_auth.dart';
import '../../services/location_service.dart';

class CourierDashboardPage extends ConsumerStatefulWidget {
  const CourierDashboardPage({super.key});

  @override
  ConsumerState<CourierDashboardPage> createState() => _CourierDashboardPageState();
}

class _CourierDashboardPageState extends ConsumerState<CourierDashboardPage> {
  bool _isOnDuty = false;
  late CourierLocationEngine _locationEngine;
  List<dynamic> _activeOrders = [];
  bool _isLoadingOrders = false;
  final TextEditingController _phoneController = TextEditingController(text: "+905555555555");
  final TextEditingController _otpController = TextEditingController(text: "123456");
  bool _otpSent = false;
  String _authErrorMessage = "";

  @override
  void initState() {
    super.initState();
    _locationEngine = CourierLocationEngine(ref.read(apiClientProvider));
  }

  @override
  void dispose() {
    _locationEngine.stopTracking();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _fetchActiveOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoadingOrders = true;
    });
    try {
      final response = await ref.read(apiClientProvider).get('/api/couriers/orders');
      if (response['data'] != null) {
        setState(() {
          _activeOrders = response['data'] as List<dynamic>;
          _authErrorMessage = "";
        });
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      setState(() {
        _authErrorMessage = "Siparişler yüklenemedi: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
      }
    }
  }

  Future<void> _deliverOrder(String orderId) async {
    try {
      await ref.read(apiClientProvider).put('/api/couriers/orders/$orderId/deliver');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sipariş teslim edildi olarak işaretlendi! 🎉"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchActiveOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    // If checking auth status, show loader
    if (authState is AuthChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If authenticated, show main dashboard
    if (authState is AuthAuthenticated) {
      // Trigger order fetch once if not loaded
      if (_activeOrders.isEmpty && !_isLoadingOrders && _authErrorMessage.isEmpty) {
        Future.microtask(() => _fetchActiveOrders());
      }

      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kurye Paneli",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                authState.user.name ?? "Süleyman Kurye",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Text(
                  _isOnDuty ? "NÖBETTE 🟢" : "PASİF 🔴",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _isOnDuty,
                  activeThumbColor: Colors.green,
                  onChanged: (val) async {
                    try {
                      await ref.read(apiClientProvider).put(
                        '/api/couriers/toggle-duty',
                        body: {'isActive': val},
                      );
                      
                      setState(() {
                        _isOnDuty = val;
                      });

                      if (_isOnDuty) {
                        await _locationEngine.startTracking();
                        _fetchActiveOrders();
                      } else {
                        await _locationEngine.stopTracking();
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      setState(() {
                        _isOnDuty = !val;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Nöbet durumu güncellenemedi: $e"),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _locationEngine.stopTracking();
                setState(() {
                  _isOnDuty = false;
                  _activeOrders = [];
                });
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchActiveOrders,
          child: _isOnDuty
              ? _buildActiveDeliveryFeed(theme)
              : _buildOfflinePlaceholder(theme),
        ),
      );
    }

    // Otherwise, show Login view
    return _buildLoginView(theme, authState);
  }

  Widget _buildActiveDeliveryFeed(ThemeData theme) {
    if (_isLoadingOrders && _activeOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeOrders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              children: [
                Icon(Icons.directions_bike_outlined, size: 80, color: theme.colorScheme.primary.withAlpha(128)),
                const SizedBox(height: 16),
                const Text(
                  "Aktif siparişiniz bulunmamaktadır.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "Yeni siparişler atandığında burada görünecektir.",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: _activeOrders.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildOptimalRouteTimeline(theme);
        }
        final order = _activeOrders[index - 1];
        final shop = order['shop'] ?? {};
        final items = order['items'] as List<dynamic>? ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "SİPARİŞ #${order['id'].toString().substring(0, 8).toUpperCase()}",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: order['status'] == 'ON_THE_WAY' ? Colors.orange[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order['status'] == 'ON_THE_WAY' ? "YOLDA" : "HAZIRLANIYOR",
                        style: TextStyle(
                          color: order['status'] == 'ON_THE_WAY' ? Colors.orange[800] : Colors.blue[800],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.store, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shop['name'] ?? "Bilinmeyen Restoran",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order['deliveryAddress'] ?? "Lefkoşa / Hamitköy",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      "Ödeme Yöntemi: ${order['paymentMethod'] == 'CASH_ON_DELIVERY' ? 'Kapıda Nakit' : order['paymentMethod'] == 'CARD_ON_DELIVERY' ? 'Kapıda Kart' : 'Online Ödeme'}",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (items.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text("Sipariş İçeriği (${items.length} ürün):", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...items.map((item) {
                    final prod = item['product'] ?? {};
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        "• ${item['quantity']} x ${prod['name'] ?? 'Ürün'}",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    );
                  }),
                ],
                const Divider(height: 24),
                // Swipe Action Button to Deliver
                SwipeButton(
                  activeTrackColor: theme.colorScheme.primary,
                  activeThumbColor: Colors.white,
                  height: 52,
                  child: const Text(
                    "Teslim Ettim (Kaydırın)",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onSwipe: () {
                    _deliverOrder(order['id'].toString());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfflinePlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.power_settings_new_rounded, size: 80, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          const Text(
            "Şu Anda Çevrimdışısınız",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              "Sipariş alabilmek ve canlı konum akıtmak için sağ üstten nöbetinizi aktif edin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginView(ThemeData theme, AuthState authState) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.directions_bike_outlined, size: 80, color: Color(0xFF00A651)),
              const SizedBox(height: 24),
              Text(
                "Hoppa Kurye Girişi",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00A651),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Teslimat yönetim paneline erişmek için telefon numaranızla giriş yapın.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              if (!_otpSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Telefon Numarası",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    hintText: "+905555555555",
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _authErrorMessage = "";
                    });
                    try {
                      await ref.read(authControllerProvider.notifier).sendOtp(_phoneController.text);
                      setState(() {
                        _otpSent = true;
                      });
                    } catch (e) {
                      setState(() {
                        _authErrorMessage = e.toString();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("OTP Kodu Gönder", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "OTP Kodu (SMS)",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    hintText: "123456",
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _authErrorMessage = "";
                    });
                    try {
                      await ref.read(authControllerProvider.notifier).verifyOtp(
                            _phoneController.text,
                            _otpController.text,
                          );
                    } catch (e) {
                      setState(() {
                        _authErrorMessage = e.toString();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Doğrula ve Giriş Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _otpSent = false;
                    });
                  },
                  child: const Text("Numarayı Değiştir"),
                ),
              ],
              if (authState is AuthError || _authErrorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _authErrorMessage.isNotEmpty ? _authErrorMessage : (authState as AuthError).errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
              if (authState is AuthLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth radius in km
    final double dLat = (lat2 - lat1) * math.pi / 180.0;
    final double dLon = (lon2 - lon1) * math.pi / 180.0;
    final double a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180.0) * math.cos(lat2 * math.pi / 180.0) * 
      math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  Widget _buildOptimalRouteTimeline(ThemeData theme) {
    if (_activeOrders.isEmpty) return const SizedBox.shrink();

    final shop = _activeOrders[0]['shop'] ?? {};
    final shopName = shop['name'] ?? "Restoran/Market";
    final shopLat = double.tryParse(shop['latitude']?.toString() ?? '') ?? 35.1856;
    final shopLon = double.tryParse(shop['longitude']?.toString() ?? '') ?? 33.3823;

    // Build list of delivery locations
    List<Map<String, dynamic>> routePoints = [];
    for (final order in _activeOrders) {
      final addr = order['address'] ?? {};
      final lat = double.tryParse(addr['latitude']?.toString() ?? '') ?? double.tryParse(order['deliveryLatitude']?.toString() ?? '') ?? 35.1856;
      final lon = double.tryParse(addr['longitude']?.toString() ?? '') ?? double.tryParse(order['deliveryLongitude']?.toString() ?? '') ?? 33.3823;
      final customerName = order['consumer']?['name'] ?? "Müşteri";
      final addressTitle = order['deliveryAddress'] ?? "Teslimat Adresi";

      routePoints.add({
        'orderId': order['id'],
        'name': customerName,
        'address': addressTitle,
        'latitude': lat,
        'longitude': lon,
      });
    }

    // Sort delivery sequence to find optimal route
    List<Map<String, dynamic>> sortedPoints = [];
    double totalDistance = 0.0;

    if (routePoints.length == 1) {
      sortedPoints = List.from(routePoints);
      totalDistance = _calculateDistance(shopLat, shopLon, sortedPoints[0]['latitude'], sortedPoints[0]['longitude']);
    } else if (routePoints.length == 2) {
      // Compare Shop -> A -> B vs Shop -> B -> A
      final p1 = routePoints[0];
      final p2 = routePoints[1];

      final distA1 = _calculateDistance(shopLat, shopLon, p1['latitude'], p1['longitude']);
      final distA2 = _calculateDistance(p1['latitude'], p1['longitude'], p2['latitude'], p2['longitude']);
      final totalA = distA1 + distA2;

      final distB1 = _calculateDistance(shopLat, shopLon, p2['latitude'], p2['longitude']);
      final distB2 = _calculateDistance(p2['latitude'], p2['longitude'], p1['latitude'], p1['longitude']);
      final totalB = distB1 + distB2;

      if (totalA <= totalB) {
        sortedPoints = [p1, p2];
        totalDistance = totalA;
      } else {
        sortedPoints = [p2, p1];
        totalDistance = totalB;
      }
    } else {
      // Fallback simple greedy approach for 3+ points
      sortedPoints = List.from(routePoints);
      double currentLat = shopLat;
      double currentLon = shopLon;
      
      for (int i = 0; i < sortedPoints.length; i++) {
        int bestIdx = i;
        double minDist = double.infinity;
        for (int j = i; j < sortedPoints.length; j++) {
          final d = _calculateDistance(currentLat, currentLon, sortedPoints[j]['latitude'], sortedPoints[j]['longitude']);
          if (d < minDist) {
            minDist = d;
            bestIdx = j;
          }
        }
        final temp = sortedPoints[i];
        sortedPoints[i] = sortedPoints[bestIdx];
        sortedPoints[bestIdx] = temp;
        
        totalDistance += minDist;
        currentLat = sortedPoints[i]['latitude'];
        currentLon = sortedPoints[i]['longitude'];
      }
    }

    final int estDurationMins = ((totalDistance / 40.0) * 60.0).round() + 5; // 40 km/h average speed + 5 min buffer

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: Colors.green[50],
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.green[200]!, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  "Fleet AI Rota Optimizasyonu",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Yapay zeka teslimat noktalarınızı en verimli sıraya dizdi. Toplam Mesafe: ${totalDistance.toStringAsFixed(2)} km (Tahmini Süre: $estDurationMins dk)",
              style: TextStyle(color: Colors.green[900], fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Timeline view
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimelineStep(
                  isFirst: true,
                  isLast: false,
                  title: "Alış Noktası: $shopName",
                  subtitle: "Siparişi teslim alıp yola çıkın.",
                  icon: Icons.store,
                  color: Colors.green[700]!,
                ),
                ...List.generate(sortedPoints.length, (index) {
                  final pt = sortedPoints[index];
                  final isLast = index == sortedPoints.length - 1;
                  return _buildTimelineStep(
                    isFirst: false,
                    isLast: isLast,
                    title: "Teslimat ${index + 1}: ${pt['name']}",
                    subtitle: pt['address'],
                    icon: Icons.directions_bike,
                    color: Colors.blue[700]!,
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required bool isFirst,
    required bool isLast,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: color.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

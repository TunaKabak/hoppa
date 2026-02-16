import 'dart:async'; // StreamSubscription için
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hoppa/core/services/order_service.dart';
import 'package:hoppa/features/merchant/merchant_order_list_page.dart';
import 'package:hoppa/features/merchant/merchant_product_list_page.dart';
import 'package:hoppa/core/services/product_service.dart';
import 'package:hoppa/features/merchant/merchant_analytics_page.dart';
import 'package:hoppa/features/merchant/merchant_settings_page.dart';
import 'package:hoppa/features/merchant/campaign/merchant_campaigns_page.dart'; // Import
import 'package:hoppa/models/order_status.dart'; // Restored
import 'package:hoppa/core/services/business_service.dart';
import 'package:hoppa/core/services/auth_service.dart'; // Logout için
import 'package:hoppa/features/auth/auth_wrapper.dart'; // Redirect için

class MerchantDashboardPage extends StatefulWidget {
  final String businessId;

  const MerchantDashboardPage({super.key, required this.businessId});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0; // Aktif tab index

  final OrderService _orderService = OrderService();
  late StreamSubscription<QuerySnapshot> _orderSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _flashController;
  late Animation<Color?> _flashAnimation;

  // İlk açılışta mevcut siparişleri bildirim olarak saymamak için bayrak
  bool _isFirstListen = true;
  String? _businessName;
  final BusinessService _businessService = BusinessService();

  // ... (existing variables)
  late Stream<QuerySnapshot> _dailyOrdersStream;

  @override
  void initState() {
    super.initState();
    _fetchBusinessDetails();
    _initMerchantNotificationListener();
    _initFlashAnimation();
    _dailyOrdersStream = _orderService.getDailyOrdersStream(
      businessId: widget.businessId,
    );
  }

  @override
  void dispose() {
    _orderSubscription.cancel();
    _flashController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  bool _isShopOpen = true; // Local state for shop status

  // ... (existing helper methods)

  // ... (existing helper methods)

  Future<void> _fetchBusinessDetails() async {
    final business = await _businessService.getBusinessById(widget.businessId);
    if (mounted && business != null) {
      setState(() {
        _businessName = business.name;
        _isShopOpen = business.isOpen;
      });
    }
  }

  void _initFlashAnimation() {
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _flashAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.red.withOpacity(0.3),
    ).animate(_flashController);

    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flashController.reverse();
      }
    });
  }

  // MARKET BİLDİRİM DİNLEYİCİSİ
  void _initMerchantNotificationListener() {
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('business_id', isEqualTo: widget.businessId)
        .where('status', isEqualTo: OrderStatus.pending.value)
        .snapshots()
        .listen((snapshot) {
          if (_isFirstListen) {
            _isFirstListen = false;
            return;
          }

          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              _playSound();
              _flashController.forward(from: 0);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      "YENİ SİPARİŞ GELDİ!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: "GİT",
                      textColor: Colors.white,
                      onPressed: () => _navigateToList(
                        context,
                        filter: OrderStatus.pending.value,
                      ),
                    ),
                  ),
                );
              }
            }
          }
        });
  }

  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.wav'));
    } catch (e) {
      debugPrint("Ses hatası: $e");
    }
  }

  Future<void> _toggleShopStatus(bool value) async {
    setState(() => _isShopOpen = value); // Optimistic update
    try {
      await _businessService.updateBusinessStatus(widget.businessId, value);
    } catch (e) {
      if (mounted) {
        setState(() => _isShopOpen = !value); // Revert on error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Durum güncellenemedi: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tab Listesi
    final List<Widget> pages = [
      _buildDashboardContent(theme), // Ana Sayfa (Dashboard)
      MerchantProductListPage(businessId: widget.businessId), // Ürünler
      MerchantCampaignsPage(
        businessId: widget.businessId,
      ), // Kampanyalar (YENİ)
      MerchantAnalyticsPage(businessId: widget.businessId), // Analiz
      MerchantSettingsPage(businessId: widget.businessId), // Ayarlar
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              _businessName ?? "Market Paneli",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _isShopOpen ? "Dükkan AÇIK" : "Dükkan KAPALI",
              style: TextStyle(
                fontSize: 12,
                color: _isShopOpen ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Shop Status Switch
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _isShopOpen,
              activeColor: Colors.green,
              activeTrackColor: Colors.green.withOpacity(0.2),
              inactiveThumbColor: Colors.red,
              inactiveTrackColor: Colors.red.withOpacity(0.2),
              onChanged: _toggleShopStatus,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          pages[_currentIndex],
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) =>
                  Container(color: _flashAnimation.value),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Özet'),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Ürünler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Kampanya',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analiz'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dailyOrdersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];

        // Calculations
        final pendingCount = orders
            .where((d) => d['status'] == OrderStatus.pending.value)
            .length;
        final activeCount = orders
            .where(
              (d) =>
                  d['status'] == OrderStatus.pending.value ||
                  d['status'] == OrderStatus.preparing.value ||
                  d['status'] == OrderStatus.onWay.value,
            )
            .length;

        final cancelledCount = orders
            .where((d) => d['status'] == OrderStatus.cancelled.value)
            .length;
        final totalCount = orders.length;
        final cancelRate = totalCount > 0
            ? (cancelledCount / totalCount * 100)
            : 0.0;

        final totalRevenue = orders.fold<double>(0.0, (sum, doc) {
          final s = doc['status'];
          if (s != OrderStatus.cancelled.value) {
            return sum + (doc['total_amount'] ?? 0.0);
          }
          return sum;
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. KPI CARDS
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      "Ciro",
                      "${totalRevenue.toStringAsFixed(0)}₺",
                      Colors.green,
                      Icons.wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKPICard(
                      "Aktif",
                      "$activeCount",
                      Colors.orange,
                      Icons.motorcycle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKPICard(
                      "İptal",
                      "%${cancelRate.toStringAsFixed(0)}",
                      Colors.red,
                      Icons.cancel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. ACTION CENTER: PENDING ORDERS
              if (pendingCount > 0) _buildActionRequiredCard(pendingCount),

              if (pendingCount > 0) const SizedBox(height: 24),

              // 3. ACTION CENTER: LOW STOCK
              _buildLowStockSection(),
              const SizedBox(height: 24),

              // 4. SUMMARY GRID (Original)
              Text(
                "Sipariş Durumları",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildSummaryCard(
                    context,
                    title: "Yeni",
                    count: "$pendingCount",
                    icon: Icons.fiber_new,
                    color: Colors.blue,
                    onTap: () => _navigateToList(
                      context,
                      filter: OrderStatus.pending.value,
                    ),
                  ),
                  _buildSummaryCard(
                    context,
                    title: "Hazırlanıyor",
                    count:
                        "${orders.where((d) => d['status'] == 'preparing').length}",
                    icon: Icons.soup_kitchen,
                    color: Colors.orange,
                    onTap: () => _navigateToList(
                      context,
                      filter: OrderStatus.preparing.value,
                    ),
                  ),
                  _buildSummaryCard(
                    context,
                    title: "Yolda",
                    count:
                        "${orders.where((d) => d['status'] == 'onWay').length}",
                    icon: Icons.delivery_dining,
                    color: Colors.purple,
                    onTap: () => _navigateToList(
                      context,
                      filter: OrderStatus.onWay.value,
                    ),
                  ),
                  _buildSummaryCard(
                    context,
                    title: "Teslim",
                    count:
                        "${orders.where((d) => d['status'] == 'delivered').length}",
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onTap: () => _navigateToList(
                      context,
                      filter: OrderStatus.delivered.value,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPICard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRequiredCard(int count) {
    return GestureDetector(
      onTap: () => _navigateToList(context, filter: OrderStatus.pending.value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "BEKLEYEN SİPARİŞ VAR!",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    "$count Adet",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockSection() {
    final ProductService service = ProductService();

    return StreamBuilder<List<dynamic>>(
      stream: service.getLowStockProducts(widget.businessId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();

        final products = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Kritik Stok",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _currentIndex = 1), // Go to Products
                  child: const Text("Tümünü Gör"),
                ),
              ],
            ),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final p = products[index]; // BusinessProduct
                  return Container(
                    width: 120,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Image.network(
                              p.product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "${p.stock.toInt()} Adet",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToList(BuildContext context, {String? filter}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MerchantOrderListPage(filterStatus: filter),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isAlert = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                if (isAlert) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.circle, color: color, size: 8),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

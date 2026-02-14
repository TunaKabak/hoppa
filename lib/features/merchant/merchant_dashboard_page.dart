import 'dart:async'; // StreamSubscription için
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hoppa/core/services/order_service.dart';
import 'package:hoppa/features/merchant/merchant_order_list_page.dart';
import 'package:hoppa/features/merchant/merchant_product_list_page.dart';
import 'package:hoppa/features/merchant/merchant_analytics_page.dart';
import 'package:hoppa/features/merchant/merchant_settings_page.dart';
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

  // ... (existing methods: _fetchBusinessDetails, _initFlashAnimation, dispose, _initMerchantNotificationListener, _playSound)

  Future<void> _fetchBusinessDetails() async {
    final business = await _businessService.getBusinessById(widget.businessId);
    if (mounted && business != null) {
      setState(() {
        _businessName = business.name;
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

  @override
  void dispose() {
    _orderSubscription.cancel(); // Changed from _merchantSubscription
    _flashController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // MARKET BİLDİRİM DİNLEYİCİSİ
  void _initMerchantNotificationListener() {
    // Sadece 'pending' (Yeni) siparişleri dinle
    // Not: Gerçek uygulamada 'business_id' filtrelemesi yapılmalı.
    _orderSubscription = FirebaseFirestore
        .instance // Changed from _merchantSubscription
        .collection('orders')
        .where(
          'business_id',
          isEqualTo: widget.businessId,
        ) // Dynamic Business ID
        .where(
          'status',
          isEqualTo: 'pending',
        ) // Changed from OrderStatus.pending.value
        .snapshots()
        .listen((snapshot) {
          // İlk veri akışını (sayfa açılışını) yoksay, sadece YENİ gelenleri dinle
          if (_isFirstListen) {
            _isFirstListen = false;
            return;
          }

          for (var change in snapshot.docChanges) {
            // Eğer YENİ bir sipariş EKLENDİYSE (Added)
            if (change.type == DocumentChangeType.added) {
              print("🔔 YENİ SİPARİŞ ALGILANDI! ID: ${change.doc.id}");

              // Ses Çal
              _playSound();

              // Görsel Uyarı (Flash)
              _flashController.forward(from: 0);
              // Çoklu flash için
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted) _flashController.forward(from: 0);
              });
              Future.delayed(const Duration(milliseconds: 1200), () {
                if (mounted) _flashController.forward(from: 0);
              });

              // Görsel Bildirim Göster
              if (mounted) {
                final data = change.doc.data();
                final amount = data?['total_amount'] ?? 0;

                // Mevcut Snackbar'ı temizle ki üst üste binmesin
                ScaffoldMessenger.of(context).clearSnackBars();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "YENİ SİPARİŞ GELDİ! ($amount ₺)",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red.shade800,
                    behavior: SnackBarBehavior.floating, // Yüzen snackbar
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    duration: const Duration(
                      seconds: 10,
                    ), // 10 saniye ekranda kalsın
                    action: SnackBarAction(
                      label: "GÖRÜNTÜLE",
                      textColor: Colors.white,
                      backgroundColor: Colors.white24,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tab Listesi
    final List<Widget> pages = [
      _buildDashboardContent(theme), // Ana Sayfa (Dashboard)
      MerchantProductListPage(businessId: widget.businessId), // Ürünler
      MerchantAnalyticsPage(businessId: widget.businessId), // Analiz
      MerchantSettingsPage(businessId: widget.businessId), // Ayarlar
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_businessName ?? "Market Paneli"),
        centerTitle: true,
        actions: [
          // Çıkış Yap Butonu
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.blueGrey,
            ), // Rengi yumuşattım
            tooltip: "Çıkış Yap",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Çıkış Yap"),
                  content: const Text(
                    "Çıkış yapmak istediğinize emin misiniz?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("İptal"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Çıkış Yap",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AuthService().signOut();
                // AuthWrapper stream'i dinlediği için otomatik yönlendirecek.
                // Ancak yine de stack'i temizlemek iyi olabilir.
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const AuthWrapper(),
                    ),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Aktif Sayfa
          pages[_currentIndex],

          // Flash Overlay (Sadece Dashboard'da aktif olsa da global durabilir)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                return Container(color: _flashAnimation.value);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // 4+ item olduğu için fixed olmalı
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Özet'),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Ürünler',
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
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "Bugün henüz sipariş yok.",
              style: theme.textTheme.titleMedium,
            ),
          );
        }

        final orders = snapshot.data!.docs;
        final pendingOrders = orders
            .where((doc) => doc['status'] == OrderStatus.pending.value)
            .length;
        final preparingOrders = orders
            .where((doc) => doc['status'] == OrderStatus.preparing.value)
            .length;
        final completedOrders = orders
            .where((doc) => doc['status'] == OrderStatus.delivered.value)
            .length;
        final cancelledOrders = orders
            .where((doc) => doc['status'] == OrderStatus.cancelled.value)
            .length;

        final totalRevenue = orders.fold<double>(0.0, (sum, doc) {
          final status = doc['status'];
          if (status == OrderStatus.delivered.value ||
              status == OrderStatus.preparing.value ||
              status == OrderStatus.pending.value) {
            return sum + (doc['total_amount'] ?? 0);
          }
          return sum;
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bugünkü Sipariş Özeti",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildRevenueCard(totalRevenue),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildSummaryCard(
                    context,
                    title: "Yeni Siparişler",
                    count: pendingOrders.toString(),
                    icon: Icons.fiber_new,
                    color: Colors.red.shade700,
                    onTap: () => _navigateToList(
                      context,
                      filter: OrderStatus.pending.value,
                    ),
                    isAlert: pendingOrders > 0,
                  ),
                  _buildSummaryCard(
                    context,
                    title: "Hazırlanan Siparişler",
                    count: preparingOrders.toString(),
                    icon: Icons.delivery_dining,
                    color: Colors.orange.shade700,
                    onTap: () => _navigateToList(
                      context,
                      filter: OrderStatus.preparing.value,
                    ),
                  ),
                  _buildSummaryCard(
                    context,
                    title: "Tamamlanan Siparişler",
                    count: completedOrders.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green.shade700,
                    onTap: () => _navigateToList(
                      context,
                      filter: OrderStatus.delivered.value,
                    ),
                  ),
                  _buildSummaryCard(
                    context,
                    title: "İptal Edilen Siparişler",
                    count: cancelledOrders.toString(),
                    icon: Icons.cancel,
                    color: Colors.grey.shade700,
                    onTap: () => _navigateToList(
                      context,
                      filter: OrderStatus.cancelled.value,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color),
                if (isAlert) Icon(Icons.circle, color: color, size: 10),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(double revenue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wallet, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                "Bugünkü Toplam Ciro",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${revenue.toStringAsFixed(2)} ₺",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

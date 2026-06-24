import 'dart:async'; // StreamSubscription için
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hoppa/shared/models/order_status.dart'; // Restored
import 'package:hoppa/shared/models/order.dart' as model;
import 'package:hoppa/shared/core/services/business_service.dart';
import 'package:hoppa/shared/core/services/product_service.dart';
import 'package:hoppa/apps/merchant/merchant_order_list_page.dart';
import 'package:hoppa/apps/merchant/merchant_main_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/apps/merchant/providers/merchant_api_providers.dart';
import 'package:hoppa/apps/merchant/merchant_settings_page.dart';
import 'package:hoppa/apps/merchant/repositories/merchant_order_repository.dart';
import 'package:fl_chart/fl_chart.dart';

class MerchantDashboardPage extends ConsumerStatefulWidget {
  final String businessId;

  const MerchantDashboardPage({super.key, required this.businessId});

  @override
  ConsumerState<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends ConsumerState<MerchantDashboardPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _flashController;
  late Animation<Color?> _flashAnimation;
  Timer? _pollingTimer;

  // İlk açılışta mevcut siparişleri bildirim olarak saymamak için bayrak
  bool _isFirstListen = true;
  String? _businessName;
  final BusinessService _businessService = BusinessService();

  @override
  void initState() {
    super.initState();
    _fetchBusinessDetails();
    _initFlashAnimation();
    
    // Polling orders every 15 seconds for notifications
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        ref.invalidate(merchantOrdersProvider);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _flashController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ... (existing helper methods)

  // ... (existing helper methods)

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
      end: Colors.red.withValues(alpha: 0.3),
    ).animate(_flashController);

    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flashController.reverse();
      }
    });
  }

  void _handleNewOrdersNotification(List<model.Order> previous, List<model.Order> next) {
    if (_isFirstListen) {
      _isFirstListen = false;
      return;
    }

    final prevPendingIds = previous
        .where((o) => o.status == OrderStatus.pending.value)
        .map((o) => o.id)
        .toSet();

    final newPendingOrders = next
        .where((o) => o.status == OrderStatus.pending.value && !prevPendingIds.contains(o.id))
        .toList();

    if (newPendingOrders.isNotEmpty) {
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

  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.wav'));
    } catch (e) {
      debugPrint("Ses hatası: $e");
    }
  }

  Future<void> _toggleShopStatus(bool value) async {
    try {
      await ref.read(shopControllerProvider.notifier).toggleStatus(value);
    } catch (e) {
      if (!mounted) return;
      
      final errorMsg = e.toString();
      final lowerError = errorMsg.toLowerCase();
      if (lowerError.contains("lütfen dükkan ve resmi işletme") || 
          lowerError.contains("ayarlarınızı tamamlayın") ||
          lowerError.contains("resmi isletme")) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Eksik Bilgi"),
            content: const Text(
              "Dükkanınızı açabilmek için lokasyon, çalışma saatleri ve resmi işletme (Vergi/Kimlik No) ayarlarınızı tamamlamanız gerekmektedir.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Kapat"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MerchantSettingsPage(
                        businessId: widget.businessId,
                      ),
                    ),
                  );
                },
                child: const Text("Ayarlara Git"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Durum güncellenemedi: $errorMsg")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopState = ref.watch(shopControllerProvider);
    final isShopOpen = shopState.value?.isActive ?? false;

    // Listen for new orders to show notification
    ref.listen<AsyncValue<List<model.Order>>>(
      merchantOrdersProvider,
      (previous, next) {
        if (next.hasValue) {
          final previousData = previous?.value ?? [];
          _handleNewOrdersNotification(previousData, next.value!);
        }
      },
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => merchantDrawerKey.currentState?.openDrawer(),
        ),
        title: Column(
          children: [
            Text(
              _businessName ?? "Market Paneli",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              isShopOpen ? "Dükkan AÇIK" : "Dükkan KAPALI",
              style: TextStyle(
                fontSize: 12,
                color: isShopOpen ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Transform.scale(
            scale: 0.8,
            child: shopState.isLoading 
              ? const SizedBox(
                  width: 40, 
                  height: 40, 
                  child: Padding(
                    padding: EdgeInsets.all(10.0), 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                )
              : Switch(
                  value: isShopOpen,
                  activeThumbColor: Colors.greenAccent,
                  activeTrackColor: Colors.greenAccent.withValues(alpha: 0.2),
                  inactiveThumbColor: Colors.redAccent,
                  inactiveTrackColor: Colors.redAccent.withValues(alpha: 0.2),
                  onChanged: _toggleShopStatus,
                ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _buildDashboardContent(theme),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) =>
                  Container(color: _flashAnimation.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(ThemeData theme) {
    final ordersAsync = ref.watch(merchantOrdersProvider);
    final statsAsync = ref.watch(merchantDashboardStatsProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text("Hata: $error")),
      data: (allOrders) {
        final activeCount = allOrders.where((d) =>
            d.status == OrderStatus.pending.value ||
            d.status == OrderStatus.preparing.value ||
            d.status == OrderStatus.onWay.value).length;

        final pendingCount = allOrders.where((d) => d.status == OrderStatus.pending.value).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. KPI CARDS (from API)
              statsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text("İstatistik Hatası: $error")),
                data: (stats) {
                  final totalRevenue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
                  final cancelRate = (stats['cancelRate'] as num?)?.toDouble() ?? 0.0;
                  final weeklyTrend = stats['weeklyTrend'] as List<dynamic>? ?? [];

                  return Column(
                    children: [
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
                            child: GestureDetector(
                              onTap: () => _navigateToList(context, filter: 'active'),
                              child: _buildKPICard(
                                "Aktif",
                                "$activeCount",
                                Colors.orange,
                                Icons.motorcycle,
                              ),
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
                      _buildWeeklyTrendChart(weeklyTrend, theme),
                    ],
                  );
                },
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
                        "${allOrders.where((d) => d.status == 'preparing').length}",
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
                        "${allOrders.where((d) => d.status == OrderStatus.onWay.value).length}",
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
                        "${allOrders.where((d) => d.status == 'delivered').length}",
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

  Widget _buildWeeklyTrendChart(List<dynamic> weeklyTrend, ThemeData theme) {
    if (weeklyTrend.isEmpty) return const SizedBox.shrink();

    final maxVal = weeklyTrend
        .map((e) => (e['orderCount'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal + (maxVal * 0.2) : 5.0; // %20 padding

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Son 7 Günlük Trend",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= weeklyTrend.length) return const SizedBox.shrink();
                        final dateStr = weeklyTrend[index]['date'] as String;
                        final dateParts = dateStr.split('-');
                        final display = "${dateParts[2]}/${dateParts[1]}"; // DD/MM
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            display,
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: weeklyTrend.asMap().entries.map((entry) {
                  final i = entry.key;
                  final count = (entry.value['orderCount'] as num).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: count,
                        color: theme.primaryColor,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
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
              color: Colors.red.withValues(alpha: 0.4),
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
                color: Colors.white.withValues(alpha: 0.2),
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

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
                  onPressed: () {
                    // Yönlendirme mantığını veya dialog'u buraya ekleyebilirsiniz
                  },
                  child: const Text("Tümünü Gör"),
                ),
              ],
            ),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                              errorBuilder: (_, _, _) => const Icon(
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
        builder: (context) => MerchantOrderListPage(
          businessId: widget.businessId,
          filterStatus: filter,
        ),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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
                color: color.withValues(alpha: 0.8),
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

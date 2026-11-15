import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:core_shared/shared/models/order.dart' as model;
import 'package:merchant_app/apps/merchant/merchant_main_layout.dart';
import 'package:merchant_app/apps/merchant/repositories/merchant_order_repository.dart';

class MerchantAnalyticsPage extends ConsumerStatefulWidget {
  final String businessId;

  const MerchantAnalyticsPage({super.key, required this.businessId});

  @override
  ConsumerState<MerchantAnalyticsPage> createState() => _MerchantAnalyticsPageState();
}

class _MerchantAnalyticsPageState extends ConsumerState<MerchantAnalyticsPage> {
  // Filter State
  String _selectedFilter = 'Bugün'; // Bugün, Bu Hafta, Bu Ay, Tarih Seç
  DateTimeRange? _customDateRange;

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedFilter == 'Bugün') {
      return DateTimeRange(start: today, end: now);
    } else if (_selectedFilter == 'Bu Hafta') {
      // Pazartesi'den başla
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      return DateTimeRange(start: startOfWeek, end: now);
    } else if (_selectedFilter == 'Bu Ay') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      return DateTimeRange(start: startOfMonth, end: now);
    } else if (_selectedFilter == 'Tarih Seç' && _customDateRange != null) {
      return DateTimeRange(
        start: _customDateRange!.start,
        end: DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    }

    // Default: Bugün
    return DateTimeRange(start: today, end: now);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && mounted) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = 'Tarih Seç';
      });
    }
  }

  _AnalyticsData _computeAnalytics(List<model.Order> allOrders, DateTimeRange range) {
    final hourlyOrderCounts = List<int>.filled(24, 0);
    final productQuantities = <String, int>{};
    final productRevenues = <String, double>{};

    final startDay = DateTime(range.start.year, range.start.month, range.start.day);
    final endDay = DateTime(range.end.year, range.end.month, range.end.day);
    final daysParam = endDay.difference(startDay).inDays + 1;
    final isDailyChart = daysParam <= 1;

    final revenueMap = <String, double>{};
    for (int i = 0; i < (isDailyChart ? 1 : daysParam); i++) {
      final d = startDay.add(Duration(days: i));
      final key = DateFormat('dd/MM').format(d);
      revenueMap[key] = 0.0;
    }

    for (final order in allOrders) {
      final dt = order.createdAt.toLocal();
      if (dt.isBefore(range.start) || dt.isAfter(range.end)) continue;
      if (order.status.toLowerCase() == 'cancelled') continue;

      hourlyOrderCounts[dt.hour]++;

      final dateKey = DateFormat('dd/MM').format(dt);
      if (revenueMap.containsKey(dateKey) || !isDailyChart) {
        revenueMap[dateKey] = (revenueMap[dateKey] ?? 0.0) + order.totalAmount;
      }

      for (final item in order.items) {
        final pName = item.name.isNotEmpty ? item.name : 'Bilinmeyen Ürün';
        final qty = item.quantity.round();
        productQuantities[pName] = (productQuantities[pName] ?? 0) + qty;
        productRevenues[pName] =
            (productRevenues[pName] ?? 0.0) + (item.price * item.quantity);
      }
    }

    final List<String> dailyLabels;
    final List<double> dailyRevenues;
    if (isDailyChart) {
      dailyLabels = ["Bugün"];
      dailyRevenues = [revenueMap.values.fold(0.0, (p, c) => p + c)];
    } else {
      dailyLabels = [];
      dailyRevenues = [];
      for (int i = 0; i < daysParam; i++) {
        final d = startDay.add(Duration(days: i));
        final key = DateFormat('dd/MM').format(d);
        dailyLabels.add(DateFormat('E', 'tr_TR').format(d));
        dailyRevenues.add(revenueMap[key] ?? 0.0);
      }
    }

    final topSellingProducts = productQuantities.entries
        .map((e) => <String, dynamic>{
              'name': e.key,
              'value': e.value,
              'sub': '${e.value} Adet',
            })
        .toList()
      ..sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));

    final topRevenueProducts = productRevenues.entries
        .map((e) => <String, dynamic>{
              'name': e.key,
              'value': e.value,
              'sub': '${(e.value).toStringAsFixed(0)}₺',
            })
        .toList()
      ..sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

    return _AnalyticsData(
      dailyRevenues: dailyRevenues,
      dailyLabels: dailyLabels,
      hourlyOrderCounts: hourlyOrderCounts,
      topSellingProducts: topSellingProducts.take(5).toList(),
      topRevenueProducts: topRevenueProducts.take(5).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(merchantOrdersProvider);
    final range = _getDateRange();

    return Scaffold(
      appBar: AppBar(
        title: const Text("İşletme Analizi"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => merchantDrawerKey.currentState?.openDrawer(),
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Bugün', 'Bu Hafta', 'Bu Ay', 'Tarih Seç'].map((
                  filter,
                ) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        if (selected) {
                          if (filter == 'Tarih Seç') {
                            _selectDateRange();
                          } else {
                            setState(() {
                              _selectedFilter = filter;
                              _customDateRange = null;
                            });
                          }
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Rapor verisi yüklenemedi: $error"),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(merchantOrdersProvider),
                      child: const Text("Yeniden Dene"),
                    ),
                  ],
                ),
              ),
              data: (orders) {
                final analytics = _computeAnalytics(orders, range);
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(merchantOrdersProvider.future),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle("Satış Grafiği"),
                        const SizedBox(height: 16),
                        _buildWeeklySalesChart(analytics),
                        const SizedBox(height: 32),

                        _buildSectionTitle("Saatlik Yoğunluk"),
                        const SizedBox(height: 16),
                        _buildHourlyDensityChart(analytics),
                        const SizedBox(height: 32),

                        _buildSectionTitle("En Çok Satan Ürünler"),
                        _buildTopList(analytics.topSellingProducts, Colors.blue),
                        const SizedBox(height: 24),

                        _buildSectionTitle("En Çok Ciro Getirenler"),
                        _buildTopList(analytics.topRevenueProducts, Colors.green),
                        const SizedBox(height: 34),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWeeklySalesChart(_AnalyticsData analytics) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < analytics.dailyLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        analytics.dailyLabels[index],
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(analytics.dailyRevenues.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: analytics.dailyRevenues[index],
                  color: Colors.green,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHourlyDensityChart(_AnalyticsData analytics) {
    final spots = <FlSpot>[];
    for (int i = 0; i < 24; i++) {
      spots.add(FlSpot(i.toDouble(), analytics.hourlyOrderCounts[i].toDouble()));
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 6, // Her 6 saatte bir çizgi
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            getDrawingVerticalLine: (value) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ), // Y ekseni değerlerini gizledik, temiz görünüm için
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 6, // 00:00, 06:00, 12:00, 18:00
                getTitlesWidget: (value, meta) {
                  final hour = value.toInt();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "$hour:00",
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orange.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopList(List<Map<String, dynamic>> items, Color color) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Veri bulunamadı.", style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${index + 1}",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                item['sub'],
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AnalyticsData {
  final List<double> dailyRevenues;
  final List<String> dailyLabels;
  final List<int> hourlyOrderCounts;
  final List<Map<String, dynamic>> topSellingProducts;
  final List<Map<String, dynamic>> topRevenueProducts;

  const _AnalyticsData({
    required this.dailyRevenues,
    required this.dailyLabels,
    required this.hourlyOrderCounts,
    required this.topSellingProducts,
    required this.topRevenueProducts,
  });
}

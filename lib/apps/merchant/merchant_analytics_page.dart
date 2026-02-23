import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hoppa/shared/core/services/order_service.dart';
import 'package:hoppa/apps/merchant/merchant_main_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantAnalyticsPage extends StatefulWidget {
  final String businessId;

  const MerchantAnalyticsPage({super.key, required this.businessId});

  @override
  State<MerchantAnalyticsPage> createState() => _MerchantAnalyticsPageState();
}

class _MerchantAnalyticsPageState extends State<MerchantAnalyticsPage> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;

  // Filter State
  String _selectedFilter = 'Bugün'; // Bugün, Bu Hafta, Bu Ay, Tarih Seç
  DateTimeRange? _customDateRange;

  // Processed Data
  List<double> _dailyRevenues = [];
  List<String> _dailyLabels = [];
  List<int> _hourlyOrderCounts = List.filled(24, 0);

  // Top Products
  List<Map<String, dynamic>> _topSellingProducts = [];
  List<Map<String, dynamic>> _topRevenueProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final range = _getDateRange();
      final orders = await _orderService.getOrdersInRange(
        businessId: widget.businessId,
        startDate: range.start,
        endDate: range.end,
      );

      _processData(orders, range);
    } catch (e) {
      debugPrint("Analytics Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      return _customDateRange!;
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
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = 'Tarih Seç';
      });
      _fetchData();
    }
  }

  void _processData(List<Map<String, dynamic>> orders, DateTimeRange range) {
    // 1. Reset Data
    _hourlyOrderCounts = List.filled(24, 0);
    _dailyRevenues = [];
    _dailyLabels = [];

    final productQuantities = <String, int>{};
    final productRevenues = <String, double>{};
    final productNames = <String, String>{};

    // Calculate days map for bar chart (if range > 1 day)
    final daysParam = range.end.difference(range.start).inDays + 1;
    final isDailyChart =
        daysParam <=
        1; // Eğer tek gün seçildiyse saatlik gösterilebilir ama istek bar chart

    // Tarih bazlı ciro haritası
    final revenueMap = <String, double>{};
    // Initialize map with 0
    for (int i = 0; i < (isDailyChart ? 1 : daysParam); i++) {
      final d = range.start.add(Duration(days: i));
      final key = DateFormat('dd/MM').format(d);
      revenueMap[key] = 0.0;
      if (!isDailyChart && i < 7) {
        // Max 7 columns for readability in this view or logic update needed
        // For logic simplicity, if range is huge, we might group by weeks/months, but user requested 'Weekly Sales' specifically.
        // Let's stick to showing all days in range for now, or last 7 if 'This Week'
      }
    }

    for (var order in orders) {
      final amount = (order['total_amount'] ?? 0).toDouble();
      final Timestamp? createdAt = order['created_at'];
      if (createdAt == null) continue;

      final dt = createdAt.toDate();

      // Hourly Density
      _hourlyOrderCounts[dt.hour]++;

      // Daily Revenue
      final dateKey = DateFormat('dd/MM').format(dt);
      if (revenueMap.containsKey(dateKey) || !isDailyChart) {
        revenueMap[dateKey] = (revenueMap[dateKey] ?? 0) + amount;
      }

      // Products
      if (order['items'] != null) {
        for (var item in order['items']) {
          final pName = item['name'] ?? 'Bilinmeyen Ürün';
          final qty = (item['quantity'] ?? 0) as int;
          final price = (item['price'] ?? 0).toDouble();

          productNames[pName] = pName;
          productQuantities[pName] = (productQuantities[pName] ?? 0) + qty;
          productRevenues[pName] =
              (productRevenues[pName] ?? 0) + (price * qty);
        }
      }
    }

    // Chart Data Preparation
    if (isDailyChart) {
      _dailyLabels = ["Bugün"];
      _dailyRevenues = [revenueMap.values.fold(0.0, (p, c) => p + c)];
    } else {
      // Sort keys by date
      final sortedKeys = revenueMap.keys
          .toList(); // Should be naturally sorted if we iterated correctly, but verify?
      // Actually `revenueMap` isn't sorted map.
      // Let's rebuild lists based on iteration of range
      _dailyLabels = [];
      _dailyRevenues = [];
      for (int i = 0; i < daysParam; i++) {
        final d = range.start.add(Duration(days: i));
        final key = DateFormat('dd/MM').format(d);
        _dailyLabels.add(DateFormat('E', 'tr_TR').format(d)); // Pzt
        _dailyRevenues.add(revenueMap[key] ?? 0.0);
      }
    }

    // Top Lists
    _topSellingProducts = productQuantities.entries.map((e) {
      return {'name': e.key, 'value': e.value, 'sub': '${e.value} Adet'};
    }).toList();
    _topSellingProducts.sort(
      (a, b) => (b['value'] as int).compareTo(a['value'] as int),
    );
    _topSellingProducts = _topSellingProducts.take(5).toList();

    _topRevenueProducts = productRevenues.entries.map((e) {
      return {
        'name': e.key,
        'value': e.value,
        'sub': '${(e.value).toStringAsFixed(0)}₺',
      };
    }).toList();
    _topRevenueProducts.sort(
      (a, b) => (b['value'] as double).compareTo(a['value'] as double),
    );
    _topRevenueProducts = _topRevenueProducts.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                            _fetchData();
                          }
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle("Satış Grafiği"),
                    const SizedBox(height: 16),
                    _buildWeeklySalesChart(),
                    const SizedBox(height: 32),

                    _buildSectionTitle("Saatlik Yoğunluk"),
                    const SizedBox(height: 16),
                    _buildHourlyDensityChart(),
                    const SizedBox(height: 32),

                    _buildSectionTitle("En Çok Satan Ürünler"),
                    _buildTopList(_topSellingProducts, Colors.blue),
                    const SizedBox(height: 24),

                    _buildSectionTitle("En Çok Ciro Getirenler"),
                    _buildTopList(_topRevenueProducts, Colors.green),
                    const SizedBox(height: 34),
                  ],
                ),
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

  Widget _buildWeeklySalesChart() {
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
                  if (index >= 0 && index < _dailyLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _dailyLabels[index],
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
          barGroups: List.generate(_dailyRevenues.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: _dailyRevenues[index],
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

  Widget _buildHourlyDensityChart() {
    List<FlSpot> spots = [];
    for (int i = 0; i < 24; i++) {
      spots.add(FlSpot(i.toDouble(), _hourlyOrderCounts[i].toDouble()));
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
                color: Colors.orange.withOpacity(0.2),
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
                color: Colors.black.withOpacity(0.03),
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
                  color: color.withOpacity(0.1),
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

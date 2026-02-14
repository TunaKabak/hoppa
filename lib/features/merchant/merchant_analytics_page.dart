import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hoppa/core/services/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/models/order_status.dart';

class MerchantAnalyticsPage extends StatefulWidget {
  final String businessId;

  const MerchantAnalyticsPage({super.key, required this.businessId});

  @override
  State<MerchantAnalyticsPage> createState() => _MerchantAnalyticsPageState();
}

class _MerchantAnalyticsPageState extends State<MerchantAnalyticsPage> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  // List<Map<String, dynamic>> _weeklyOrders = []; // Removed unused variable

  // Chart Data
  List<double> _dailyRevenues = List.filled(7, 0.0);
  Map<String, int> _statusCounts = {
    'completed': 0,
    'cancelled': 0,
    'active': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final orders = await _orderService.getWeeklyOrders(widget.businessId);
      _processData(orders);
    } catch (e) {
      debugPrint("Analytics Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processData(List<Map<String, dynamic>> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Reset Data
    _dailyRevenues = List.filled(7, 0.0);
    _statusCounts = {'completed': 0, 'cancelled': 0, 'active': 0};

    for (var order in orders) {
      final status = order['status'];
      final amount = (order['total_amount'] ?? 0).toDouble();
      final Timestamp? createdAt = order['created_at'];

      if (createdAt == null) continue;

      // 1. Durum Sayımları
      if (status == OrderStatus.delivered.value) {
        _statusCounts['completed'] = (_statusCounts['completed'] ?? 0) + 1;
      } else if (status == OrderStatus.cancelled.value) {
        _statusCounts['cancelled'] = (_statusCounts['cancelled'] ?? 0) + 1;
      } else {
        _statusCounts['active'] = (_statusCounts['active'] ?? 0) + 1;
      }

      // 2. Günlük Ciro (Sadece tamamlananlar veya hepsi? Genelde ciro tamamlanandır)
      // Şimdilik tüm aktif ve tamamlananları katalım (iptal hariç)
      if (status != OrderStatus.cancelled.value) {
        final orderDate = createdAt.toDate();
        final dayDiff = today
            .difference(
              DateTime(orderDate.year, orderDate.month, orderDate.day),
            )
            .inDays;

        if (dayDiff >= 0 && dayDiff < 7) {
          // dayDiff 0 = Bugün, 6 = 7 gün önce
          // Grafikte soldan sağa: 6 gün önce -> Bugün olmalı
          // List index: 0 -> 6 gün önce, 6 -> Bugün
          int index = 6 - dayDiff;
          _dailyRevenues[index] += amount;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Haftalık Ciro",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBarChart(),
          const SizedBox(height: 32),
          const Text(
            "Sipariş Durumları",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPieChart(),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return AspectRatio(
      aspectRatio: 1.5,
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
                  final date = DateTime.now().subtract(
                    Duration(days: 6 - index),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E', 'tr').format(date), // Pzt, Sal
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: _dailyRevenues[index],
                  color: Colors.green,
                  width: 16,
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

  Widget _buildPieChart() {
    final completed = _statusCounts['completed']!.toDouble();
    final cancelled = _statusCounts['cancelled']!.toDouble();
    final active = _statusCounts['active']!.toDouble();
    final total = completed + cancelled + active;

    if (total == 0) {
      return const Center(child: Text("Veri yok"));
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            if (completed > 0)
              PieChartSectionData(
                value: completed,
                color: Colors.green,
                title: '${(completed / total * 100).toStringAsFixed(0)}%',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (active > 0)
              PieChartSectionData(
                value: active,
                color: Colors.blue,
                title: '${(active / total * 100).toStringAsFixed(0)}%',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (cancelled > 0)
              PieChartSectionData(
                value: cancelled,
                color: Colors.red,
                title: '${(cancelled / total * 100).toStringAsFixed(0)}%',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

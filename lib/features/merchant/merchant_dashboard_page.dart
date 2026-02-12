import 'dart:async'; // StreamSubscription için
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hoppa/core/services/order_service.dart';
import 'package:hoppa/features/merchant/merchant_order_list_page.dart';

class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  final OrderService _orderService = OrderService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _merchantSubscription;

  // İlk açılışta mevcut siparişleri bildirim olarak saymamak için bayrak
  bool _isFirstListen = true;

  @override
  void initState() {
    super.initState();
    _initMerchantNotificationListener();
  }

  @override
  void dispose() {
    _merchantSubscription?.cancel();
    super.dispose();
  }

  // MARKET BİLDİRİM DİNLEYİCİSİ
  void _initMerchantNotificationListener() {
    // Sadece 'pending' (Yeni) siparişleri dinle
    _merchantSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('market_id', isEqualTo: 'market_1')
        .where('status', isEqualTo: 'pending')
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
                      onPressed: () =>
                          _navigateToList(context, filter: 'pending'),
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Market Paneli"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: "Ses Testi",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ses testi yapılıyor...")),
              );
              _playSound();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _orderService.getIncomingOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // --- Veri Hesaplama ---
          final pendingOrders = docs
              .where((d) => d['status'] == 'pending')
              .toList();
          final activeOrders = docs
              .where((d) => ['preparing', 'on_way'].contains(d['status']))
              .toList();

          // Basit Ciro Hesabı
          double currentRevenue = 0;
          for (var doc in docs) {
            currentRevenue += (doc['total_amount'] ?? 0).toDouble();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Günlük Özet",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Kartlar
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: "Onay Bekleyen",
                        count: pendingOrders.length.toString(),
                        icon: Icons.notifications_active,
                        color: Colors.red,
                        onTap: () =>
                            _navigateToList(context, filter: 'pending'),
                        isAlert: pendingOrders.isNotEmpty,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: "Hazırlanan/Yolda",
                        count: activeOrders.length.toString(),
                        icon: Icons.delivery_dining,
                        color: Colors.blue,
                        onTap: () => _navigateToList(context, filter: 'active'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRevenueCard(currentRevenue),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.list_alt),
                    label: const Text(
                      "Tüm Sipariş Listesini Aç",
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => _navigateToList(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
                "Anlık Ciro (Aktif)",
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

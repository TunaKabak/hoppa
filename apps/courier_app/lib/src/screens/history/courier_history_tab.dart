import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_network/core_network.dart';
import '../../models/courier_models.dart';

class CourierHistoryTab extends ConsumerStatefulWidget {
  const CourierHistoryTab({super.key});

  @override
  ConsumerState<CourierHistoryTab> createState() => _CourierHistoryTabState();
}

class _CourierHistoryTabState extends ConsumerState<CourierHistoryTab> {
  static const Color _hoppaOrange = Color(0xFFFF6B00);
  static const Color _hoppaGreen = Color(0xFF00A651);

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  CourierHistorySummary _summary = CourierHistorySummary.empty;
  CourierHistoryPagination _pagination = CourierHistoryPagination.empty;
  List<CourierOrder> _orders = const [];

  @override
  void initState() {
    super.initState();
    _fetchHistory(page: 1);
  }

  Future<void> _fetchHistory({int page = 1, bool append = false}) async {
    if (!mounted) return;
    if (append) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .get('/api/couriers/orders/history?page=$page&limit=20');
      final rawData = response['data'];
      if (rawData is Map<String, dynamic>) {
        final parsed = CourierOrderHistoryResponse.fromJson(rawData);
        if (!mounted) return;
        setState(() {
          _summary = parsed.summary;
          _pagination = parsed.pagination;
          _orders = append
              ? [..._orders, ...parsed.orders]
              : parsed.orders;
          _errorMessage = null;
        });
      } else if (rawData is Map) {
        final parsed = CourierOrderHistoryResponse.fromJson(
          Map<String, dynamic>.from(rawData),
        );
        if (!mounted) return;
        setState(() {
          _summary = parsed.summary;
          _pagination = parsed.pagination;
          _orders = append
              ? [..._orders, ...parsed.orders]
              : parsed.orders;
          _errorMessage = null;
        });
      }
    } on AppException catch (e) {
      debugPrint('🚨 Teslimat geçmişi yüklenemedi: ${e.message}');
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      debugPrint('🚨 Teslimat geçmişi yüklenemedi: $e');
      if (!mounted) return;
      setState(() => _errorMessage = 'Teslimat geçmişi alınamadı: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.$y • $hh:$mm';
  }

  String _paymentLabel(String paymentMethod) {
    switch (paymentMethod) {
      case 'CASH_ON_DELIVERY':
        return 'Kapıda Nakit';
      case 'CARD_ON_DELIVERY':
        return 'Kapıda Kart';
      case 'WALLET':
        return 'Cüzdan';
      case 'ONLINE_PAYMENT':
      default:
        return 'Online Ödeme';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading && _orders.isEmpty) {
      return const HoppaListCardSkeleton(itemCount: 4);
    }

    if (_errorMessage != null && _orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchHistory(page: 1),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    final hasMore = _pagination.page < _pagination.totalPages;

    return RefreshIndicator(
      onRefresh: () => _fetchHistory(page: 1),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards Row
          Row(
            children: [
              Expanded(
                child: _SummaryMetricCard(
                  title: 'Bugün',
                  count: _summary.todayCount,
                  amount: _summary.todayDeliveryFeeTotal,
                  accentColor: _hoppaOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetricCard(
                  title: 'Son 7 Gün',
                  count: _summary.weekCount,
                  amount: _summary.weekDeliveryFeeTotal,
                  accentColor: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetricCard(
                  title: 'Toplam',
                  count: _summary.totalCount,
                  amount: _summary.totalDeliveryFeeTotal,
                  accentColor: _hoppaGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text(
            'Tamamlanan Teslimatlar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),

          if (_orders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 56,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Henüz tamamlanmış teslimatınız bulunmuyor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ..._orders.map(
              (order) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.displayOrderNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _hoppaOrange,
                                fontFeatures: HoppaDesignTokens.tabularFigures,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? HoppaDesignTokens.brandGreen
                                      .withValues(alpha: 0.2)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Teslim Edildi',
                              style: TextStyle(
                                color: isDark
                                    ? HoppaDesignTokens.statusSuccessDark
                                    : const Color(0xFF166534),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.shop?.name ?? 'Mağaza',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.resolvedDeliveryAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDateTime(order.updatedAt ?? order.createdAt),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFeatures: HoppaDesignTokens.tabularFigures,
                            ),
                          ),
                          Text(
                            '${_paymentLabel(order.paymentMethod)} • ₺${order.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              fontFeatures: HoppaDesignTokens.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Teslimat Kazancı',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '₺${order.deliveryFee.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? HoppaDesignTokens.statusSuccessDark
                                  : _hoppaGreen,
                              fontFeatures: HoppaDesignTokens.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 12),
                child: OutlinedButton(
                  onPressed: _isLoadingMore
                      ? null
                      : () => _fetchHistory(
                          page: _pagination.page + 1,
                          append: true,
                        ),
                  child: _isLoadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Daha Fazla Yükle'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  final String title;
  final int count;
  final double amount;
  final Color accentColor;

  const _SummaryMetricCard({
    required this.title,
    required this.count,
    required this.amount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? HoppaDesignTokens.borderOutdoorDark
              : HoppaDesignTokens.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₺${amount.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: accentColor,
              fontFeatures: HoppaDesignTokens.tabularFigures,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count teslimat',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontFeatures: HoppaDesignTokens.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

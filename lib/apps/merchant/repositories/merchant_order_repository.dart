import 'package:core_auth/core_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_network/core_network.dart';
import 'package:hoppa/shared/models/order.dart';

class MerchantOrderRepository {
  final ApiClient _apiClient;

  MerchantOrderRepository(this._apiClient);

  Future<List<Order>> getMerchantOrders() async {
    final response = await _apiClient.get('/api/merchant/orders');
    final data = response['data'] as List;
    return data
        .map((json) => Order.fromMap(json, json['id'] as String))
        .toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _apiClient.put(
      '/api/merchant/orders/$orderId/status',
      body: {'status': status},
    );
  }

  Future<void> cancelOrder(String orderId, String cancelReason) async {
    await _apiClient.post(
      '/api/merchant/orders/$orderId/cancel',
      body: {'cancelReason': cancelReason},
    );
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _apiClient.get('/api/merchant/dashboard/stats');
    return response['data'] as Map<String, dynamic>;
  }
}

final merchantOrderRepositoryProvider = Provider<MerchantOrderRepository>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return MerchantOrderRepository(apiClient);
});

final merchantOrdersProvider = FutureProvider.autoDispose<List<Order>>((
  ref,
) async {
  final repository = ref.watch(merchantOrderRepositoryProvider);
  return await repository.getMerchantOrders();
});

final merchantDashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.watch(merchantOrderRepositoryProvider);
  return await repository.getDashboardStats();
});

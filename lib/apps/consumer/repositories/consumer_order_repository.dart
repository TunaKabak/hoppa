import 'package:core_network/core_network.dart';
import 'package:core_auth/core_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/shared/models/order.dart';

class ConsumerOrderRepository {
  final ApiClient _apiClient;

  ConsumerOrderRepository(this._apiClient);

  /// POST /api/consumer/orders
  Future<Order> createOrder(Map<String, dynamic> orderData) async {
    final response = await _apiClient.post('/api/consumer/orders', body: orderData);
    final data = response['data'] as Map<String, dynamic>;
    final id = data['id'] as String? ?? '';
    return Order.fromMap(data, id);
  }

  /// GET /api/consumer/orders
  Future<List<Order>> getMyOrders() async {
    final response = await _apiClient.get('/api/consumer/orders');
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data.map((json) {
      final id = json['id'] as String? ?? '';
      return Order.fromMap(Map<String, dynamic>.from(json), id);
    }).toList();
  }
}

// Riverpod Providers
final consumerOrderRepositoryProvider = Provider<ConsumerOrderRepository>((ref) {
  return ConsumerOrderRepository(ref.watch(apiClientProvider));
});

final consumerOrdersProvider = FutureProvider<List<Order>>((ref) async {
  return ref.watch(consumerOrderRepositoryProvider).getMyOrders();
});

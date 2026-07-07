import 'package:core_network/core_network.dart';
import 'package:core_auth/core_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConsumerReviewRepository {
  final ApiClient _apiClient;

  ConsumerReviewRepository(this._apiClient);

  /// POST /api/consumer/reviews
  Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/consumer/reviews',
        body: {
          'orderId': orderId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      return response;
    } catch (e) {
      print("submitReview error: $e");
      rethrow;
    }
  }

  /// GET /api/consumer/shops/:shopId/reviews
  Future<List<Map<String, dynamic>>> fetchShopReviews(String shopId) async {
    try {
      final response = await _apiClient.get('/api/consumer/shops/$shopId/reviews');
      final data = response['data'] as List<dynamic>?;
      if (data == null) return [];
      return data.map((json) => Map<String, dynamic>.from(json)).toList();
    } catch (e) {
      print("fetchShopReviews error: $e");
      return [];
    }
  }
}

// Riverpod Provider
final consumerReviewRepositoryProvider = Provider<ConsumerReviewRepository>((ref) {
  return ConsumerReviewRepository(ref.watch(apiClientProvider));
});

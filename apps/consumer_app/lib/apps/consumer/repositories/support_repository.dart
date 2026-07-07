import 'package:core_network/core_network.dart';
import 'package:core_auth/core_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupportRepository {
  final ApiClient _apiClient;

  SupportRepository(this._apiClient);

  /// POST /api/consumer/support/chat
  Future<Map<String, dynamic>> sendMessageToAssistant({
    required String message,
    String? activeOrderId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/consumer/support/chat',
        body: {
          'message': message,
          if (activeOrderId != null) 'activeOrderId': activeOrderId,
        },
      );
      return response;
    } catch (e) {
      print("sendMessageToAssistant error: $e");
      rethrow;
    }
  }
}

// Riverpod Provider
final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(apiClientProvider));
});

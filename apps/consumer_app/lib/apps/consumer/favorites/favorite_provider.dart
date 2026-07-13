import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';

class FavoriteProvider extends ChangeNotifier {
  final WidgetRef _ref;
  List<String> _favoriteProductIds = [];

  List<String> get favoriteProductIds => _favoriteProductIds;

  FavoriteProvider(this._ref) {
    _init();
  }

  void _init() {
    // Load favorites initially if already authenticated
    final authState = _ref.read(authControllerProvider);
    if (authState is AuthAuthenticated) {
      _loadFavorites();
    }

    // Listen to auth state changes manually/programmatically
    _ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (next is AuthAuthenticated) {
          _loadFavorites();
        } else {
          _favoriteProductIds.clear();
          notifyListeners();
        }
      },
    );
  }

  Future<void> _loadFavorites() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get('/api/consumer/favorites/products');
      final data = response['data'] as List<dynamic>?;
      if (data != null) {
        _favoriteProductIds = data.map((item) {
          final productJson = item['product'] ?? item;
          return productJson['id'] as String? ?? '';
        }).where((id) => id.isNotEmpty).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("FavoriteProvider _loadFavorites error: $e");
    }
  }

  bool isFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  Future<void> toggleFavorite(String productId) async {
    final authState = _ref.read(authControllerProvider);
    if (authState is! AuthAuthenticated) return;

    final originalList = List<String>.from(_favoriteProductIds);

    // Optimistic Update
    if (isFavorite(productId)) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    notifyListeners();

    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/api/consumer/favorites/products/toggle',
        body: {'productId': productId},
      );

      final data = response['data'] as Map<String, dynamic>?;
      final bool isFav = data != null && data['isFavorite'] == true;
      // Sync state just in case
      if (isFav) {
        if (!_favoriteProductIds.contains(productId)) {
          _favoriteProductIds.add(productId);
        }
      } else {
        _favoriteProductIds.remove(productId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("FavoriteProvider toggleFavorite error: $e");
      // Rollback on error
      _favoriteProductIds = originalList;
      notifyListeners();
    }
  }
}

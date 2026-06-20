import 'package:core_network/core_network.dart';
import 'package:core_auth/core_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/shared/models/address.dart';

class AddressRepository {
  final ApiClient _apiClient;

  AddressRepository(this._apiClient);

  /// GET /api/consumer/addresses
  Future<List<Address>> getMyAddresses() async {
    final response = await _apiClient.get('/api/consumer/addresses');
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data.map((json) {
      final id = json['id'] as String? ?? '';
      return Address.fromMap(Map<String, dynamic>.from(json), id);
    }).toList();
  }

  /// POST /api/consumer/addresses
  Future<Address> createAddress(Address address) async {
    final response = await _apiClient.post(
      '/api/consumer/addresses',
      body: address.toMap(),
    );
    final data = response['data'] as Map<String, dynamic>;
    final id = data['id'] as String? ?? '';
    return Address.fromMap(data, id);
  }

  /// PUT /api/consumer/addresses/:id
  Future<Address> updateAddress(Address address) async {
    final response = await _apiClient.put(
      '/api/consumer/addresses/${address.id}',
      body: address.toMap(),
    );
    final data = response['data'] as Map<String, dynamic>;
    final id = data['id'] as String? ?? '';
    return Address.fromMap(data, id);
  }

  /// DELETE /api/consumer/addresses/:id
  Future<void> deleteAddress(String id) async {
    await _apiClient.delete('/api/consumer/addresses/$id');
  }
}

// Riverpod Providers
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(apiClientProvider));
});

final addressesProvider = FutureProvider<List<Address>>((ref) async {
  return ref.watch(addressRepositoryProvider).getMyAddresses();
});

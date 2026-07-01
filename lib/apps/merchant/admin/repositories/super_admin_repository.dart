import 'package:core_network/core_network.dart';
import 'package:hoppa/shared/models/business_category.dart';

class PendingMerchant {
  final String id;
  final String email;
  final String businessName;
  final String? phone;
  final String status;
  final String? revisionMessage;
  final DateTime? createdAt;

  PendingMerchant({
    required this.id,
    required this.email,
    required this.businessName,
    this.phone,
    required this.status,
    this.revisionMessage,
    this.createdAt,
  });

  factory PendingMerchant.fromMap(Map<String, dynamic> map) {
    return PendingMerchant(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      businessName: map['businessName'] ?? 'İsimsiz İşletme',
      phone: map['phone'],
      status: map['status'] ?? 'PENDING',
      revisionMessage: map['revisionMessage'],
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
    );
  }
}

class SuperAdminRepository {
  final ApiClient _apiClient;

  SuperAdminRepository(this._apiClient);

  Future<List<PendingMerchant>> getPendingMerchants() async {
    final response = await _apiClient.get('/api/admin/merchants/pending');
    final data = response['data'] as List?;
    if (data == null) return [];
    return data.map((e) => PendingMerchant.fromMap(e)).toList();
  }

  Future<void> updateMerchantStatus(String id, String status, {String? revisionMessage}) async {
    final body = <String, dynamic>{'status': status};
    if (revisionMessage != null) {
      body['revisionMessage'] = revisionMessage;
    }
    await _apiClient.put('/api/admin/merchants/$id/status', body: body);
  }

  Future<List<BusinessCategory>> adminGetBusinessCategories() async {
    final response = await _apiClient.get('/api/admin/business-categories');
    final data = response['data'] as List?;
    if (data == null) return [];
    return data.map((e) => BusinessCategory.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<BusinessCategory> adminCreateBusinessCategory(BusinessCategory category) async {
    final response = await _apiClient.post(
      '/api/admin/business-categories',
      body: {
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'badge': category.badge,
        'avgDeliveryTime': category.avgDeliveryTime,
        'subtitle': category.subtitle,
        'isActive': category.isActive,
        'order': category.order,
      },
    );
    return BusinessCategory.fromJson(Map<String, dynamic>.from(response['data']));
  }

  Future<BusinessCategory> adminUpdateBusinessCategory(BusinessCategory category) async {
    final response = await _apiClient.put(
      '/api/admin/business-categories/${category.id}',
      body: {
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'badge': category.badge,
        'avgDeliveryTime': category.avgDeliveryTime,
        'subtitle': category.subtitle,
        'isActive': category.isActive,
        'order': category.order,
      },
    );
    return BusinessCategory.fromJson(Map<String, dynamic>.from(response['data']));
  }

  Future<void> adminDeleteBusinessCategory(String id) async {
    await _apiClient.delete('/api/admin/business-categories/$id');
  }
}

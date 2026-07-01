import 'package:flutter_riverpod/flutter_riverpod.dart';
// core_auth supplies apiClientProvider
import 'package:core_auth/core_auth.dart';
import 'package:hoppa/shared/models/business_category.dart';
import '../repositories/super_admin_repository.dart';

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SuperAdminRepository(apiClient);
});

class PendingMerchantsController extends AsyncNotifier<List<PendingMerchant>> {
  @override
  Future<List<PendingMerchant>> build() async {
    return _fetchPendingMerchants();
  }

  Future<List<PendingMerchant>> _fetchPendingMerchants() async {
    final repo = ref.read(superAdminRepositoryProvider);
    return await repo.getPendingMerchants();
  }

  Future<void> updateMerchantStatus({
    required String id,
    required String status,
    String? revisionMessage,
  }) async {
    final repo = ref.read(superAdminRepositoryProvider);
    await repo.updateMerchantStatus(id, status, revisionMessage: revisionMessage);
    
    // Refresh the list directly so the UI properly syncs with Backend state
    ref.invalidateSelf();
  }
}

final pendingMerchantsProvider = AsyncNotifierProvider<PendingMerchantsController, List<PendingMerchant>>(
  PendingMerchantsController.new,
);

class AdminBusinessCategoriesController extends AsyncNotifier<List<BusinessCategory>> {
  @override
  Future<List<BusinessCategory>> build() async {
    return _fetchCategories();
  }

  Future<List<BusinessCategory>> _fetchCategories() async {
    final repo = ref.read(superAdminRepositoryProvider);
    return await repo.adminGetBusinessCategories();
  }

  Future<void> createCategory(BusinessCategory category) async {
    final repo = ref.read(superAdminRepositoryProvider);
    await repo.adminCreateBusinessCategory(category);
    ref.invalidateSelf();
  }

  Future<void> updateCategory(BusinessCategory category) async {
    final repo = ref.read(superAdminRepositoryProvider);
    await repo.adminUpdateBusinessCategory(category);
    ref.invalidateSelf();
  }

  Future<void> deleteCategory(String id) async {
    final repo = ref.read(superAdminRepositoryProvider);
    await repo.adminDeleteBusinessCategory(id);
    ref.invalidateSelf();
  }
}

final adminBusinessCategoriesProvider = AsyncNotifierProvider<AdminBusinessCategoriesController, List<BusinessCategory>>(
  AdminBusinessCategoriesController.new,
);

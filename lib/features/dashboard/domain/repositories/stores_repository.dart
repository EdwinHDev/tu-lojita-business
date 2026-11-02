import '../entities/store.dart';
import '../entities/dashboard_stats.dart';
import '../entities/dashboard_analytics.dart';

abstract class StoresRepository {
  Future<List<Store>> getCompanyStores(String companyId);
  Future<DashboardStats> getDashboardStats(String companyId);
  Future<DashboardAnalytics> getAnalytics({
    required String companyId,
    String period = 'month',
    String storeId = 'all',
    String? startDate,
    String? endDate,
  });
  Future<Store> createStore(Map<String, dynamic> storeData);
  Future<Store> getStoreById(String storeId);
  Future<Store> updateStore(String storeId, Map<String, dynamic> storeData);

  // Lifecycle Methods (Deactivation & Scheduled Deletion)
  Future<({bool canProceed, List<String> blockers, Map<String, dynamic> details})> validateLifecyclePreflight(String storeId);
  Future<({bool success, String message, String email})> requestLifecycleOtp(String storeId, String actionType);
  Future<Store> deactivateBranch(String storeId, String otpCode);
  Future<Store> reactivateBranch(String storeId);
  Future<Store> scheduleBranchDeletion(String storeId, String otpCode);
  Future<Store> cancelScheduledDeletion(String storeId);
}

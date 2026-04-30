import '../entities/store.dart';
import '../entities/dashboard_stats.dart';

abstract class StoresRepository {
  Future<List<Store>> getCompanyStores(String companyId);
  Future<DashboardStats> getDashboardStats(String companyId);
  Future<Store> createStore(Map<String, dynamic> storeData);
  Future<Store> getStoreById(String storeId);
  Future<Store> updateStore(String storeId, Map<String, dynamic> storeData);
}

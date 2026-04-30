import '../entities/store_dashboard.dart';

abstract class StoreDashboardRepository {
  Future<StoreDashboard> getStoreDashboard(String storeId);
}

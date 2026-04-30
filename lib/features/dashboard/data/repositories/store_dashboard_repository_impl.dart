import 'package:dio/dio.dart';
import '../../domain/entities/store_dashboard.dart';
import '../../domain/repositories/store_dashboard_repository.dart';
import '../models/store_dashboard_model.dart';

class StoreDashboardRepositoryImpl implements StoreDashboardRepository {
  final Dio _dio;

  StoreDashboardRepositoryImpl(this._dio);

  @override
  Future<StoreDashboard> getStoreDashboard(String storeId) async {
    try {
      final response = await _dio.get('/stores/$storeId/dashboard');
      return StoreDashboardModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

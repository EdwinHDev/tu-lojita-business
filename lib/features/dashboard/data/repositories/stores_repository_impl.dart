import 'package:dio/dio.dart';
import '../models/store_model.dart';
import '../models/dashboard_stats_model.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/stores_repository.dart';

class StoresRepositoryImpl implements StoresRepository {
  final Dio _dio;

  StoresRepositoryImpl(this._dio);

  @override
  Future<List<Store>> getCompanyStores(String companyId) async {
    try {
      final response = await _dio.get('/companies/$companyId/dashboard/stores');
      final data = response.data['stores'] as List;
      return data.map((json) => StoreModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<DashboardStats> getDashboardStats(String companyId) async {
    try {
      final response = await _dio.get('/companies/$companyId/dashboard/stats');
      return DashboardStatsModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Store> createStore(Map<String, dynamic> storeData) async {
    try {
      final response = await _dio.post('/stores', data: storeData);
      return StoreModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Store> getStoreById(String storeId) async {
    try {
      final response = await _dio.get('/stores/$storeId');
      return StoreModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  @override
  Future<Store> updateStore(String storeId, Map<String, dynamic> storeData) async {
    try {
      final response = await _dio.patch('/stores/$storeId', data: storeData);
      return StoreModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

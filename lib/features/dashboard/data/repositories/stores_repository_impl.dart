import 'package:dio/dio.dart';
import '../models/store_model.dart';
import '../models/dashboard_stats_model.dart';
import '../models/dashboard_analytics_model.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/dashboard_analytics.dart';
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
  Future<DashboardAnalytics> getAnalytics({
    required String companyId,
    String period = 'month',
    String storeId = 'all',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'period': period,
        'storeId': storeId,
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
      };

      final response = await _dio.get(
        '/companies/$companyId/dashboard/analytics',
        queryParameters: queryParams,
      );
      return DashboardAnalyticsModel.fromJson(response.data);
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

  @override
  Future<({bool canProceed, List<String> blockers, Map<String, dynamic> details})> validateLifecyclePreflight(String storeId) async {
    try {
      final response = await _dio.post('/stores/$storeId/lifecycle/validate-preflight');
      final data = response.data as Map<String, dynamic>;
      final blockersRaw = data['blockers'] as List? ?? [];
      final blockers = blockersRaw.map((e) => e.toString()).toList();
      return (
        canProceed: data['canProceed'] == true,
        blockers: blockers,
        details: (data['details'] as Map<String, dynamic>?) ?? {},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<({bool success, String message, String email})> requestLifecycleOtp(String storeId, String actionType) async {
    try {
      final response = await _dio.post(
        '/stores/$storeId/lifecycle/request-otp',
        data: {'actionType': actionType},
      );
      final data = response.data as Map<String, dynamic>;
      return (
        success: data['success'] == true,
        message: data['message']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Store> deactivateBranch(String storeId, String otpCode) async {
    try {
      final response = await _dio.post(
        '/stores/$storeId/lifecycle/deactivate',
        data: {'otpCode': otpCode},
      );
      return StoreModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Store> reactivateBranch(String storeId) async {
    try {
      final response = await _dio.post('/stores/$storeId/lifecycle/reactivate');
      return StoreModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Store> scheduleBranchDeletion(String storeId, String otpCode) async {
    try {
      final response = await _dio.post(
        '/stores/$storeId/lifecycle/schedule-deletion',
        data: {'otpCode': otpCode},
      );
      return StoreModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Store> cancelScheduledDeletion(String storeId) async {
    try {
      final response = await _dio.post('/stores/$storeId/lifecycle/cancel-deletion');
      return StoreModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

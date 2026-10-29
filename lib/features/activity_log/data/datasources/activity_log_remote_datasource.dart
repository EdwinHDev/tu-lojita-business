import 'package:dio/dio.dart';
import '../../domain/entities/activity_log.dart';

abstract class ActivityLogRemoteDataSource {
  Future<PaginatedActivityLogs> getActivityLogs(
    String companyId, {
    String? storeId,
    String? actorId,
    String? module,
    int limit = 20,
    int offset = 0,
  });
}

class ActivityLogRemoteDataSourceImpl implements ActivityLogRemoteDataSource {
  final Dio dio;

  ActivityLogRemoteDataSourceImpl(this.dio);

  @override
  Future<PaginatedActivityLogs> getActivityLogs(
    String companyId, {
    String? storeId,
    String? actorId,
    String? module,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParameters = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (storeId != null && storeId.isNotEmpty) {
      queryParameters['storeId'] = storeId;
    }
    if (actorId != null && actorId.isNotEmpty) {
      queryParameters['actorId'] = actorId;
    }
    if (module != null && module.isNotEmpty) {
      queryParameters['module'] = module;
    }

    final response = await dio.get(
      '/companies/$companyId/activity-logs',
      queryParameters: queryParameters,
    );

    return PaginatedActivityLogs.fromJson(
        response.data as Map<String, dynamic>);
  }
}


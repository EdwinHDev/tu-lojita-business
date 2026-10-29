import '../../domain/entities/activity_log.dart';
import '../../domain/repositories/activity_log_repository.dart';
import '../datasources/activity_log_remote_datasource.dart';

class ActivityLogRepositoryImpl implements ActivityLogRepository {
  final ActivityLogRemoteDataSource remoteDataSource;

  ActivityLogRepositoryImpl(this.remoteDataSource);

  @override
  Future<PaginatedActivityLogs> getActivityLogs(
    String companyId, {
    String? storeId,
    String? actorId,
    String? module,
    int limit = 20,
    int offset = 0,
  }) {
    return remoteDataSource.getActivityLogs(
      companyId,
      storeId: storeId,
      actorId: actorId,
      module: module,
      limit: limit,
      offset: offset,
    );
  }
}


import '../entities/activity_log.dart';

abstract class ActivityLogRepository {
  Future<PaginatedActivityLogs> getActivityLogs(
    String companyId, {
    String? storeId,
    String? actorId,
    String? module,
    int limit = 20,
    int offset = 0,
  });
}


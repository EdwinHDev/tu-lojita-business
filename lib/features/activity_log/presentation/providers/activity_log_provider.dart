import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import '../../data/datasources/activity_log_remote_datasource.dart';
import '../../data/repositories/activity_log_repository_impl.dart';
import '../../domain/entities/activity_log.dart';
import '../../domain/repositories/activity_log_repository.dart';

final activityLogRemoteDataSourceProvider =
    Provider<ActivityLogRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ActivityLogRemoteDataSourceImpl(dio);
});

final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  final remote = ref.watch(activityLogRemoteDataSourceProvider);
  return ActivityLogRepositoryImpl(remote);
});

class ActivityLogState {
  final List<ActivityLog> logs;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int total;
  final int offset;
  final String? selectedStoreId;
  final String? selectedModule;
  final String? errorMessage;

  const ActivityLogState({
    this.logs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.total = 0,
    this.offset = 0,
    this.selectedStoreId,
    this.selectedModule,
    this.errorMessage,
  });

  ActivityLogState copyWith({
    List<ActivityLog>? logs,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? total,
    int? offset,
    String? selectedStoreId,
    bool clearStoreId = false,
    String? selectedModule,
    bool clearModule = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActivityLogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
      offset: offset ?? this.offset,
      selectedStoreId:
          clearStoreId ? null : (selectedStoreId ?? this.selectedStoreId),
      selectedModule:
          clearModule ? null : (selectedModule ?? this.selectedModule),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ActivityLogNotifier extends Notifier<ActivityLogState> {
  static const int _pageSize = 20;

  @override
  ActivityLogState build() {
    return const ActivityLogState();
  }

  ActivityLogRepository get _repository =>
      ref.read(activityLogRepositoryProvider);

  String _getCompanyId() {
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      return authState.user.company?.id ?? '';
    }
    return '';
  }

  Future<void> loadLogs({bool refresh = false}) async {
    final companyId = _getCompanyId();
    if (companyId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Empresa no identificada.',
      );
      return;
    }

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        offset: 0,
      );
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final result = await _repository.getActivityLogs(
        companyId,
        storeId: state.selectedStoreId,
        module: state.selectedModule,
        limit: _pageSize,
        offset: 0,
      );

      state = state.copyWith(
        logs: result.items,
        total: result.total,
        hasMore: result.hasMore,
        offset: result.items.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar actividades: $e',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final companyId = _getCompanyId();
    if (companyId.isEmpty) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getActivityLogs(
        companyId,
        storeId: state.selectedStoreId,
        module: state.selectedModule,
        limit: _pageSize,
        offset: state.offset,
      );

      state = state.copyWith(
        logs: [...state.logs, ...result.items],
        total: result.total,
        hasMore: result.hasMore,
        offset: state.offset + result.items.length,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Error al cargar más actividades: $e',
      );
    }
  }

  void setStoreFilter(String? storeId) {
    if (state.selectedStoreId == storeId) return;
    state = state.copyWith(
      selectedStoreId: storeId,
      clearStoreId: storeId == null,
    );
    loadLogs(refresh: true);
  }

  void setModuleFilter(String? module) {
    if (state.selectedModule == module) return;
    state = state.copyWith(
      selectedModule: module,
      clearModule: module == null,
    );
    loadLogs(refresh: true);
  }
}

final activityLogProvider =
    NotifierProvider<ActivityLogNotifier, ActivityLogState>(
        ActivityLogNotifier.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'dashboard_analytics_state.dart';
import 'dashboard_providers.dart';

class DashboardAnalyticsNotifier extends Notifier<DashboardAnalyticsState> {
  @override
  DashboardAnalyticsState build() {
    Future.microtask(() => loadAnalytics());
    return const DashboardAnalyticsState();
  }

  Future<void> loadAnalytics({bool isRefresh = false}) async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    final companyId = authState.user.company?.id;
    if (companyId == null) {
      state = state.copyWith(
        status: DashboardAnalyticsStatus.error,
        errorMessage: 'Empresa no encontrada',
      );
      return;
    }

    if (!isRefresh && state.status != DashboardAnalyticsStatus.loaded) {
      state = state.copyWith(status: DashboardAnalyticsStatus.loading, errorMessage: null);
    }

    try {
      final repository = ref.read(storesRepositoryProvider);
      final analytics = await repository.getAnalytics(
        companyId: companyId,
        period: state.selectedPeriod,
        storeId: state.selectedStoreId,
        startDate: state.customStartDate?.toIso8601String(),
        endDate: state.customEndDate?.toIso8601String(),
      );

      if (!ref.mounted) return;

      state = state.copyWith(
        status: DashboardAnalyticsStatus.loaded,
        analytics: analytics,
        errorMessage: null,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: DashboardAnalyticsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void setPeriod(String period) {
    if (state.selectedPeriod == period && period != 'custom') return;
    state = state.copyWith(selectedPeriod: period);
    loadAnalytics();
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    state = state.copyWith(
      selectedPeriod: 'custom',
      customStartDate: start,
      customEndDate: end,
    );
    loadAnalytics();
  }

  void setStoreId(String storeId) {
    if (state.selectedStoreId == storeId) return;
    state = state.copyWith(selectedStoreId: storeId);
    loadAnalytics();
  }
}

final dashboardAnalyticsProvider =
    NotifierProvider<DashboardAnalyticsNotifier, DashboardAnalyticsState>(() {
  return DashboardAnalyticsNotifier();
});

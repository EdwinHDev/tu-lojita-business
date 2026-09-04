import '../../domain/entities/dashboard_analytics.dart';

enum DashboardAnalyticsStatus { initial, loading, loaded, error }

class DashboardAnalyticsState {
  final DashboardAnalyticsStatus status;
  final DashboardAnalytics? analytics;
  final String selectedPeriod;
  final String selectedStoreId;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String? errorMessage;

  const DashboardAnalyticsState({
    this.status = DashboardAnalyticsStatus.initial,
    this.analytics,
    this.selectedPeriod = 'month',
    this.selectedStoreId = 'all',
    this.customStartDate,
    this.customEndDate,
    this.errorMessage,
  });

  DashboardAnalyticsState copyWith({
    DashboardAnalyticsStatus? status,
    DashboardAnalytics? analytics,
    String? selectedPeriod,
    String? selectedStoreId,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? errorMessage,
  }) {
    return DashboardAnalyticsState(
      status: status ?? this.status,
      analytics: analytics ?? this.analytics,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      errorMessage: errorMessage,
    );
  }
}

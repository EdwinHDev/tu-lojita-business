import '../../domain/entities/store.dart';
import '../../domain/entities/dashboard_stats.dart';

class StoresState {
  final List<Store> stores;
  final DashboardStats? stats;
  final bool isLoading;
  final String? errorMessage;

  const StoresState({
    this.stores = const [],
    this.stats,
    this.isLoading = false,
    this.errorMessage,
  });

  StoresState copyWith({
    List<Store>? stores,
    DashboardStats? stats,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StoresState(
      stores: stores ?? this.stores,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

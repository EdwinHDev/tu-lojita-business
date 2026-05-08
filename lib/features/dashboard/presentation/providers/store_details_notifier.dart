import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/dashboard/domain/repositories/store_dashboard_repository.dart';
import 'package:tu_lojita_business/features/dashboard/domain/repositories/store_category_repository.dart';
import 'package:tu_lojita_business/features/dashboard/domain/repositories/stores_repository.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_dashboard.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_category.dart';
import 'dashboard_providers.dart';
export 'store_details_state.dart';
import 'store_details_state.dart';

class StoreDetailsNotifier extends Notifier<StoreDetailsState> {
  @override
  StoreDetailsState build() {
    return const StoreDetailsState();
  }

  StoreDashboardRepository get _dashboardRepo => ref.read(storeDashboardRepositoryProvider);
  StoreCategoryRepository get _categoryRepo => ref.read(storeCategoryRepositoryProvider);
  StoresRepository get _storesRepo => ref.read(storesRepositoryProvider);

  Future<void> loadData(String storeId, {bool force = false}) async {
    final storeData = state.forStore(storeId);
    
    if (storeData.isLoading) return;
    if (!force && storeData.errorMessage != null) return;
    if (!force && storeData.dashboard != null) return;

    _setStoreLoading(storeId, true);

    try {
      final results = await Future.wait([
        _dashboardRepo.getStoreDashboard(storeId),
        _categoryRepo.getCategoriesByStore(storeId),
        _storesRepo.getStoreById(storeId),
      ]);

      if (!ref.mounted) return;

      _updateStoreData(storeId, StoreDetailsData(
        dashboard: results[0] as StoreDashboard,
        items: const [], // No longer showing items in home
        categories: results[1] as List<StoreCategory>,
        store: results[2] as Store,
        isLoading: false,
      ));
    } catch (e) {
      if (!ref.mounted) return;
      _updateStoreData(storeId, storeData.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _setStoreLoading(String storeId, bool loading) {
    final newData = state.forStore(storeId).copyWith(isLoading: loading, errorMessage: null);
    final newMap = Map<String, StoreDetailsData>.from(state.storeData);
    newMap[storeId] = newData;
    state = state.copyWith(storeData: newMap);
  }

  void _updateStoreData(String storeId, StoreDetailsData data) {
    final newMap = Map<String, StoreDetailsData>.from(state.storeData);
    newMap[storeId] = data;
    state = state.copyWith(storeData: newMap);
  }

  Future<void> refresh(String storeId) => loadData(storeId, force: true);
}

final storeDetailsProvider = NotifierProvider<StoreDetailsNotifier, StoreDetailsState>(() {
  return StoreDetailsNotifier();
});

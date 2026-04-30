import '../../domain/entities/store_dashboard.dart';
import '../../domain/entities/store_category.dart';
import '../../domain/entities/store.dart';
import '../../../items/domain/entities/item.dart';

class StoreDetailsState {
  final Map<String, StoreDetailsData> storeData;
  final bool isLoading;
  final String? errorMessage;

  const StoreDetailsState({
    this.storeData = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  StoreDetailsData forStore(String storeId) {
    return storeData[storeId] ?? const StoreDetailsData();
  }

  StoreDetailsState copyWith({
    Map<String, StoreDetailsData>? storeData,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StoreDetailsState(
      storeData: storeData ?? this.storeData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class StoreDetailsData {
  final Store? store;
  final StoreDashboard? dashboard;
  final List<Item> items;
  final List<StoreCategory> categories;
  final bool isLoading;
  final String? errorMessage;

  const StoreDetailsData({
    this.store,
    this.dashboard,
    this.items = const [],
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  StoreDetailsData copyWith({
    Store? store,
    StoreDashboard? dashboard,
    List<Item>? items,
    List<StoreCategory>? categories,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StoreDetailsData(
      store: store ?? this.store,
      dashboard: dashboard ?? this.dashboard,
      items: items ?? this.items,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

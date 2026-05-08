import 'package:equatable/equatable.dart';
import '../../domain/entities/item.dart';

class ItemListState extends Equatable {
  final Map<String, ItemListData> storeData;

  const ItemListState({
    this.storeData = const {},
  });

  ItemListData forStore(String storeId) {
    return storeData[storeId] ?? const ItemListData();
  }

  ItemListState copyWith({
    Map<String, ItemListData>? storeData,
  }) {
    return ItemListState(
      storeData: storeData ?? this.storeData,
    );
  }

  @override
  List<Object?> get props => [storeData];
}

class ItemListData extends Equatable {
  final List<Item> items;
  final bool isLoading;
  final bool isLoadMoreLoading;
  final bool hasMore;
  final int offset;
  final int limit;
  final int total;
  final String searchQuery;
  final String? selectedCategoryId;
  final String sortBy;
  final String order;
  final bool onlyInStock;
  final String? errorMessage;

  const ItemListData({
    this.items = const [],
    this.isLoading = false,
    this.isLoadMoreLoading = false,
    this.hasMore = true,
    this.offset = 0,
    this.limit = 50,
    this.total = 0,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.sortBy = 'createdAt',
    this.order = 'DESC',
    this.onlyInStock = false,
    this.errorMessage,
  });

  ItemListData copyWith({
    List<Item>? items,
    bool? isLoading,
    bool? isLoadMoreLoading,
    bool? hasMore,
    int? offset,
    int? limit,
    int? total,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearCategoryId = false,
    String? sortBy,
    String? order,
    bool? onlyInStock,
    String? errorMessage,
  }) {
    return ItemListData(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadMoreLoading: isLoadMoreLoading ?? this.isLoadMoreLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategoryId ? null : (selectedCategoryId ?? this.selectedCategoryId),
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
      onlyInStock: onlyInStock ?? this.onlyInStock,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        isLoading,
        isLoadMoreLoading,
        hasMore,
        offset,
        limit,
        total,
        searchQuery,
        selectedCategoryId,
        sortBy,
        order,
        onlyInStock,
        errorMessage,
      ];
}

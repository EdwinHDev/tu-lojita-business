import 'package:equatable/equatable.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/item_catalog_summary.dart';

export '../../domain/entities/item_catalog_summary.dart';

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
  final bool isSummaryLoading;
  final bool hasMore;
  final int offset;
  final int limit;
  final int total;
  final String searchQuery;
  final String? selectedCategoryId;
  final String sortBy;
  final String order;
  final bool onlyInStock;
  final ItemCatalogStatusFilter statusFilter;
  final ItemType? itemTypeFilter;
  final ItemCatalogSummary? summary;
  final ItemCatalogSummary? fallbackSummary;
  final String? errorMessage;

  const ItemListData({
    this.items = const [],
    this.isLoading = false,
    this.isLoadMoreLoading = false,
    this.isSummaryLoading = false,
    this.hasMore = true,
    this.offset = 0,
    this.limit = 50,
    this.total = 0,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.sortBy = 'createdAt',
    this.order = 'DESC',
    this.onlyInStock = false,
    this.statusFilter = ItemCatalogStatusFilter.all,
    this.itemTypeFilter,
    this.summary,
    this.fallbackSummary,
    this.errorMessage,
  });

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      selectedCategoryId != null ||
      onlyInStock ||
      statusFilter != ItemCatalogStatusFilter.all ||
      itemTypeFilter != null ||
      !(sortBy == 'createdAt' && order == 'DESC');

  bool get hasNonDefaultSortOrType =>
      itemTypeFilter != null || !(sortBy == 'createdAt' && order == 'DESC');

  ItemCatalogSummary get effectiveSummary =>
      summary ?? fallbackSummary ?? ItemCatalogSummary.fromItems(items);

  ItemListData copyWith({
    List<Item>? items,
    bool? isLoading,
    bool? isLoadMoreLoading,
    bool? isSummaryLoading,
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
    ItemCatalogStatusFilter? statusFilter,
    ItemType? itemTypeFilter,
    bool clearItemTypeFilter = false,
    ItemCatalogSummary? summary,
    ItemCatalogSummary? fallbackSummary,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ItemListData(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadMoreLoading: isLoadMoreLoading ?? this.isLoadMoreLoading,
      isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategoryId
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
      onlyInStock: onlyInStock ?? this.onlyInStock,
      statusFilter: statusFilter ?? this.statusFilter,
      itemTypeFilter: clearItemTypeFilter
          ? null
          : (itemTypeFilter ?? this.itemTypeFilter),
      summary: summary ?? this.summary,
      fallbackSummary: fallbackSummary ?? this.fallbackSummary,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        items,
        isLoading,
        isLoadMoreLoading,
        isSummaryLoading,
        hasMore,
        offset,
        limit,
        total,
        searchQuery,
        selectedCategoryId,
        sortBy,
        order,
        onlyInStock,
        statusFilter,
        itemTypeFilter,
        summary,
        fallbackSummary,
        errorMessage,
      ];
}

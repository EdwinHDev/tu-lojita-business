import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/item_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import 'item_list_state.dart';

class ItemListNotifier extends Notifier<ItemListState> {
  @override
  ItemListState build() {
    return const ItemListState();
  }

  ItemRepository get _repository => ref.read(itemRepositoryProvider);

  Future<void> loadInitial(String storeId) async {
    final storeData = state.forStore(storeId).copyWith(
      isLoading: true,
      errorMessage: null,
      items: [],
      offset: 0,
      hasMore: true,
    );
    _updateStoreData(storeId, storeData);
    await _fetchItems(storeId);
  }

  Future<void> loadNextPage(String storeId) async {
    final storeData = state.forStore(storeId);
    if (storeData.isLoadMoreLoading || !storeData.hasMore) return;
    
    _updateStoreData(storeId, storeData.copyWith(isLoadMoreLoading: true));
    await _fetchItems(storeId, isLoadMore: true);
  }

  Future<void> _fetchItems(String storeId, {bool isLoadMore = false}) async {
    final storeData = state.forStore(storeId);
    try {
      final result = await _repository.getItemsPaginated(
        storeId: storeId,
        limit: storeData.limit,
        offset: storeData.offset,
        searchQuery: storeData.searchQuery,
        categoryId: storeData.selectedCategoryId,
        sortBy: storeData.sortBy,
        order: storeData.order,
        onlyInStock: storeData.onlyInStock,
      );
      
      if (!ref.mounted) return;

      final newItems = isLoadMore ? [...storeData.items, ...result.items] : result.items;
      final hasMore = newItems.length < result.total;

      _updateStoreData(storeId, storeData.copyWith(
        items: newItems,
        isLoading: false,
        isLoadMoreLoading: false,
        hasMore: hasMore,
        offset: storeData.offset + result.items.length,
        total: result.total,
      ));
    } catch (e) {
      _updateStoreData(storeId, storeData.copyWith(
        isLoading: false,
        isLoadMoreLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void setSearchQuery(String storeId, String query) {
    final storeData = state.forStore(storeId);
    if (storeData.searchQuery == query) return;
    _updateStoreData(storeId, storeData.copyWith(searchQuery: query));
    loadInitial(storeId);
  }

  void setCategory(String storeId, String? categoryId) {
    final storeData = state.forStore(storeId);
    // Toggle: deselect if the same category is clicked again
    if (storeData.selectedCategoryId == categoryId) {
      _updateStoreData(storeId, storeData.copyWith(clearCategoryId: true));
      loadInitial(storeId);
      return;
    }
    if (categoryId == null) {
      _updateStoreData(storeId, storeData.copyWith(clearCategoryId: true));
    } else {
      _updateStoreData(storeId, storeData.copyWith(selectedCategoryId: categoryId));
    }
    loadInitial(storeId);
  }

  void setSort(String storeId, String sortBy, String order) {
    final storeData = state.forStore(storeId);
    if (storeData.sortBy == sortBy && storeData.order == order) return;
    _updateStoreData(storeId, storeData.copyWith(sortBy: sortBy, order: order));
    loadInitial(storeId);
  }

  void setOnlyInStock(String storeId, bool value) {
    final storeData = state.forStore(storeId);
    if (storeData.onlyInStock == value) return;
    _updateStoreData(storeId, storeData.copyWith(onlyInStock: value));
    loadInitial(storeId);
  }

  void resetFilters(String storeId) {
    _updateStoreData(storeId, const ItemListData());
    loadInitial(storeId);
  }

  Future<void> deleteItem(String storeId, String itemId) async {
    try {
      final storeData = state.forStore(storeId);
      final itemIndex = storeData.items.indexWhere((i) => i.id == itemId);
      final List<String> images = itemIndex != -1 ? storeData.items[itemIndex].images : const [];

      await _repository.deleteItem(itemId);

      if (images.isNotEmpty) {
        _repository.deleteImages(images);
      }

      if (!ref.mounted) return;
      await loadInitial(storeId);
    } catch (e) {
      rethrow;
    }
  }

  void _updateStoreData(String storeId, ItemListData data) {
    final newMap = Map<String, ItemListData>.from(state.storeData);
    newMap[storeId] = data;
    state = state.copyWith(storeData: newMap);
  }
}

final itemListProvider = NotifierProvider<ItemListNotifier, ItemListState>(() {
  return ItemListNotifier();
});

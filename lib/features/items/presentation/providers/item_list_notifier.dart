import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import 'item_list_state.dart';

class ItemListNotifier extends Notifier<ItemListState> {
  @override
  ItemListState build() {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is! Authenticated) {
        reset();
      }
    });
    return const ItemListState();
  }

  void reset() {
    state = const ItemListState();
  }

  ItemRepository get _repository => ref.read(itemRepositoryProvider);

  Future<void> loadInitial(String storeId) async {
    final storeData = state.forStore(storeId).copyWith(
          isLoading: true,
          clearErrorMessage: true,
          items: const [],
          offset: 0,
          hasMore: true,
        );
    _updateStoreData(storeId, storeData);
    await Future.wait([
      _fetchItems(storeId),
      refreshSummary(storeId),
    ]);
  }

  Future<void> refreshSummary(String storeId) async {
    final current = state.forStore(storeId);
    _updateStoreData(storeId, current.copyWith(isSummaryLoading: true));
    try {
      final summary = await _repository.getStoreCatalogSummary(storeId);
      if (!ref.mounted) return;
      final latest = state.forStore(storeId);
      _updateStoreData(
        storeId,
        latest.copyWith(summary: summary, isSummaryLoading: false),
      );
    } catch (_) {
      if (!ref.mounted) return;
      // Never overwrite `summary` with `ItemCatalogSummary.fromItems(latest.items)`
      // because `latest.items` may still be `[]` during initial parallel load.
      final latest = state.forStore(storeId);
      _updateStoreData(
        storeId,
        latest.copyWith(isSummaryLoading: false),
      );
    }
  }

  Future<void> loadNextPage(String storeId) async {
    final storeData = state.forStore(storeId);
    if (storeData.isLoadMoreLoading || !storeData.hasMore) return;

    _updateStoreData(storeId, storeData.copyWith(isLoadMoreLoading: true));
    await _fetchItems(storeId, isLoadMore: true);
  }

  bool _isUnfilteredQuery(ItemListData storeData) {
    return storeData.statusFilter == ItemCatalogStatusFilter.all &&
        storeData.itemTypeFilter == null &&
        storeData.selectedCategoryId == null &&
        storeData.searchQuery.trim().isEmpty &&
        !storeData.onlyInStock;
  }

  Future<void> _fetchItems(String storeId, {bool isLoadMore = false}) async {
    final storeData = state.forStore(storeId);
    bool? isActive;
    bool? onlyOutOfStock;
    bool? hasDiscount;

    switch (storeData.statusFilter) {
      case ItemCatalogStatusFilter.published:
        isActive = true;
        break;
      case ItemCatalogStatusFilter.paused:
        isActive = false;
        break;
      case ItemCatalogStatusFilter.outOfStock:
        onlyOutOfStock = true;
        break;
      case ItemCatalogStatusFilter.discounted:
        hasDiscount = true;
        break;
      case ItemCatalogStatusFilter.all:
        break;
    }

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
        isActive: isActive,
        onlyOutOfStock: onlyOutOfStock,
        hasDiscount: hasDiscount,
        itemType: storeData.itemTypeFilter,
      );

      if (!ref.mounted) return;

      final latest = state.forStore(storeId);
      final newItems =
          isLoadMore ? [...latest.items, ...result.items] : result.items;
      final hasMore = newItems.length < result.total;

      ItemCatalogSummary? updatedFallback = latest.fallbackSummary;
      if (_isUnfilteredQuery(latest)) {
        final derived = ItemCatalogSummary.fromItems(newItems);
        updatedFallback = result.total > derived.total
            ? derived.copyWith(total: result.total)
            : derived;
      }

      _updateStoreData(
        storeId,
        latest.copyWith(
          items: newItems,
          isLoading: false,
          isLoadMoreLoading: false,
          hasMore: hasMore,
          offset: latest.offset + result.items.length,
          total: result.total,
          fallbackSummary: updatedFallback,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      final latest = state.forStore(storeId);
      _updateStoreData(
        storeId,
        latest.copyWith(
          isLoading: false,
          isLoadMoreLoading: false,
          errorMessage: e.toString(),
        ),
      );
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
    if (storeData.selectedCategoryId == categoryId) {
      _updateStoreData(storeId, storeData.copyWith(clearCategoryId: true));
      loadInitial(storeId);
      return;
    }
    if (categoryId == null) {
      _updateStoreData(storeId, storeData.copyWith(clearCategoryId: true));
    } else {
      _updateStoreData(
        storeId,
        storeData.copyWith(selectedCategoryId: categoryId),
      );
    }
    loadInitial(storeId);
  }

  void setStatusFilter(String storeId, ItemCatalogStatusFilter filter) {
    final storeData = state.forStore(storeId);
    final nextFilter = storeData.statusFilter == filter &&
            filter != ItemCatalogStatusFilter.all
        ? ItemCatalogStatusFilter.all
        : filter;
    if (storeData.statusFilter == nextFilter) return;
    _updateStoreData(storeId, storeData.copyWith(statusFilter: nextFilter));
    loadInitial(storeId);
  }

  void setItemTypeFilter(String storeId, ItemType? itemType) {
    final storeData = state.forStore(storeId);
    if (storeData.itemTypeFilter == itemType) {
      if (itemType != null) {
        _updateStoreData(
          storeId,
          storeData.copyWith(clearItemTypeFilter: true),
        );
        loadInitial(storeId);
      }
      return;
    }
    if (itemType == null) {
      _updateStoreData(storeId, storeData.copyWith(clearItemTypeFilter: true));
    } else {
      _updateStoreData(
        storeId,
        storeData.copyWith(itemTypeFilter: itemType),
      );
    }
    loadInitial(storeId);
  }

  void setSort(String storeId, String sortBy, String order) {
    final storeData = state.forStore(storeId);
    if (storeData.sortBy == sortBy && storeData.order == order) return;
    _updateStoreData(
      storeId,
      storeData.copyWith(sortBy: sortBy, order: order),
    );
    loadInitial(storeId);
  }

  void setOnlyInStock(String storeId, bool value) {
    final storeData = state.forStore(storeId);
    if (storeData.onlyInStock == value) return;
    _updateStoreData(storeId, storeData.copyWith(onlyInStock: value));
    loadInitial(storeId);
  }

  void resetFilters(String storeId) {
    final current = state.forStore(storeId);
    _updateStoreData(
      storeId,
      ItemListData(
        summary: current.summary,
        fallbackSummary: current.fallbackSummary,
      ),
    );
    loadInitial(storeId);
  }

  bool _matchesCurrentFilters(ItemListData storeData, Item item) {
    switch (storeData.statusFilter) {
      case ItemCatalogStatusFilter.published:
        if (!item.isActive) return false;
        break;
      case ItemCatalogStatusFilter.paused:
        if (item.isActive) return false;
        break;
      case ItemCatalogStatusFilter.outOfStock:
        if (!item.isOutOfStock) return false;
        break;
      case ItemCatalogStatusFilter.discounted:
        final hasActiveDiscount = item.discountPrice != null &&
            item.discountPrice! > 0 &&
            item.discountPrice! < item.price;
        if (!hasActiveDiscount) return false;
        break;
      case ItemCatalogStatusFilter.all:
        break;
    }

    if (storeData.itemTypeFilter != null &&
        item.itemType != storeData.itemTypeFilter) {
      return false;
    }

    if (storeData.onlyInStock && !item.isInStock) {
      return false;
    }

    return true;
  }

  void upsertItem(String storeId, Item updatedItem) {
    final storeData = state.forStore(storeId);
    final index = storeData.items.indexWhere((i) => i.id == updatedItem.id);
    if (index == -1) return;

    final matches = _matchesCurrentFilters(storeData, updatedItem);
    final updatedItems = List<Item>.from(storeData.items);
    int newTotal = storeData.total;

    if (matches) {
      updatedItems[index] = updatedItem;
    } else {
      updatedItems.removeAt(index);
      if (newTotal > 0) newTotal--;
    }

    final updatedFallback = _isUnfilteredQuery(storeData)
        ? ItemCatalogSummary.fromItems(updatedItems)
        : storeData.fallbackSummary;

    _updateStoreData(
      storeId,
      storeData.copyWith(
        items: updatedItems,
        total: newTotal,
        fallbackSummary: updatedFallback,
      ),
    );
    unawaited(refreshSummary(storeId));
  }

  Future<void> refreshSingleItem(String storeId, String itemId) async {
    try {
      final refreshed = await _repository.getItemById(itemId);
      if (!ref.mounted) return;
      upsertItem(storeId, refreshed);
    } catch (_) {
      // Keep existing list state if single item fetch fails
    }
  }

  Future<void> toggleItemActive(String storeId, Item item) async {
    final newActive = !item.isActive;
    final storeData = state.forStore(storeId);
    final optimisticItem = item.copyWith(isActive: newActive);

    final matches = _matchesCurrentFilters(storeData, optimisticItem);
    final updatedItems = <Item>[];
    for (final existing in storeData.items) {
      if (existing.id == item.id) {
        if (matches) {
          updatedItems.add(optimisticItem);
        }
      } else {
        updatedItems.add(existing);
      }
    }
    final newTotal = !matches && storeData.total > 0
        ? storeData.total - 1
        : storeData.total;

    final updatedFallback = _isUnfilteredQuery(storeData)
        ? ItemCatalogSummary.fromItems(updatedItems)
        : storeData.fallbackSummary;

    _updateStoreData(
      storeId,
      storeData.copyWith(
        items: updatedItems,
        total: newTotal,
        fallbackSummary: updatedFallback,
      ),
    );

    try {
      final saved =
          await _repository.updateItem(item.id, {'isActive': newActive});
      if (!ref.mounted) return;
      upsertItem(storeId, saved);
    } catch (e) {
      if (ref.mounted) {
        _updateStoreData(storeId, storeData);
      }
      rethrow;
    }
  }

  Future<void> deleteItem(String storeId, String itemId) async {
    try {
      await _repository.deleteItem(itemId);

      if (!ref.mounted) return;

      final storeData = state.forStore(storeId);
      final updatedItems =
          storeData.items.where((i) => i.id != itemId).toList();
      final newTotal = storeData.total > 0 ? storeData.total - 1 : 0;

      final updatedFallback = _isUnfilteredQuery(storeData)
          ? ItemCatalogSummary.fromItems(updatedItems)
          : storeData.fallbackSummary;

      _updateStoreData(
        storeId,
        storeData.copyWith(
          items: updatedItems,
          total: newTotal,
          fallbackSummary: updatedFallback,
        ),
      );
      unawaited(refreshSummary(storeId));
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

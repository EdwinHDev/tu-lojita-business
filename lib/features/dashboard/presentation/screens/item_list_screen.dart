import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/repositories/payment_methods_repository.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_list_notifier.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/list/item_bento_grid_card.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/list/item_list_quick_actions_sheet.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/list/items_bento_filter_bar.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/list/items_bento_shimmer.dart';
import '../widgets/item_creation_prerequisites_modal.dart';

class ItemListScreen extends ConsumerStatefulWidget {
  final String storeId;
  const ItemListScreen({super.key, required this.storeId});

  @override
  ConsumerState<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends ConsumerState<ItemListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearchingLocal = false;
  bool _isCheckingPrerequisites = false;

  Future<void> _checkPrerequisitesAndNavigate() async {
    final authState = ref.read(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    if (user != null && !user.canEditProducts) {
      NotificationService.showWarning(
        context,
        'No tienes permisos requeridos para crear artículos.',
      );
      return;
    }

    if (_isCheckingPrerequisites) return;
    setState(() => _isCheckingPrerequisites = true);

    try {
      var storeData = ref.read(storeDetailsProvider).forStore(widget.storeId);
      if (storeData.categories.isEmpty && !storeData.isLoading) {
        await ref
            .read(storeDetailsProvider.notifier)
            .loadData(widget.storeId, force: true);
        storeData = ref.read(storeDetailsProvider).forStore(widget.storeId);
      }
      final bool hasCategories = storeData.categories.isNotEmpty;

      final methods = await ref
          .read(paymentMethodsRepositoryProvider)
          .getStoreMethods(widget.storeId);
      final bool hasActivePaymentMethods = methods.any((m) => m.isActive);

      if (!mounted) return;
      setState(() => _isCheckingPrerequisites = false);

      if (hasCategories && hasActivePaymentMethods) {
        final result = await context.push(
          '/dashboard/stores/${widget.storeId}/items/new',
        );
        if (result == true && mounted) {
          ref.read(itemListProvider.notifier).loadInitial(widget.storeId);
        }
      } else {
        ItemCreationPrerequisitesModal.show(
          context: context,
          storeId: widget.storeId,
          hasCategories: hasCategories,
          hasActivePaymentMethods: hasActivePaymentMethods,
          onPrerequisitesMet: () async {
            final result = await context.push(
              '/dashboard/stores/${widget.storeId}/items/new',
            );
            if (result == true && mounted) {
              ref.read(itemListProvider.notifier).loadInitial(widget.storeId);
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingPrerequisites = false);
        NotificationService.showError(
          context,
          'Error al verificar requisitos: $e',
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemListProvider.notifier).loadInitial(widget.storeId);
      ref.read(storeDetailsProvider.notifier).loadData(widget.storeId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(itemListProvider.notifier).loadNextPage(widget.storeId);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearchingLocal = true;
    });
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) {
        ref
            .read(itemListProvider.notifier)
            .setSearchQuery(widget.storeId, query);
        setState(() {
          _isSearchingLocal = false;
        });
      }
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _isSearchingLocal = false);
    ref.read(itemListProvider.notifier).setSearchQuery(widget.storeId, '');
  }

  Future<void> _openItemDetail(Item item) async {
    final result = await context.push(
      '/dashboard/stores/${widget.storeId}/items/detail',
      extra: item,
    );
    if (!mounted) return;
    if (result is Item) {
      ref.read(itemListProvider.notifier).upsertItem(widget.storeId, result);
    } else {
      await ref
          .read(itemListProvider.notifier)
          .refreshSingleItem(widget.storeId, item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final canEditProducts = user?.canEditProducts ?? true;
    final canChangePrices = user?.canChangePrices ?? true;
    final canManageStock = user?.canManageStock ?? true;
    final canShowQuickActions =
        canEditProducts || canChangePrices || canManageStock;

    final storeData = ref.watch(storeDetailsProvider).forStore(widget.storeId);
    final listState = ref.watch(itemListProvider).forStore(widget.storeId);
    final notifier = ref.read(itemListProvider.notifier);
    final items = listState.items;
    final rowCount = (items.length / 2).ceil();

    return Scaffold(
      backgroundColor: TuLojitaBrandColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Gestionar Artículos',
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
            ),
            SizedBox(height: 2),
            BcvRateHeaderPill(compactSubtitle: true),
          ],
        ),
        actions: const [],
        backgroundColor: TuLojitaBrandColors.surface,
        foregroundColor: TuLojitaBrandColors.inkPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: canEditProducts
          ? FloatingActionButton.extended(
              key: const Key('create_item_fab'),
              onPressed: _isCheckingPrerequisites
                  ? null
                  : _checkPrerequisitesAndNavigate,
              backgroundColor: TuLojitaBrandColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: _isCheckingPrerequisites
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add_rounded, size: 20),
              label: Text(
                _isCheckingPrerequisites ? 'Verificando...' : 'Agregar artículo',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          ItemsBentoFilterBar(
            searchController: _searchController,
            isSearching: _isSearchingLocal,
            listState: listState,
            categories: storeData.categories,
            onSearchChanged: _onSearchChanged,
            onClearSearch: _clearSearch,
            onStatusFilterSelected: (filter) =>
                notifier.setStatusFilter(widget.storeId, filter),
            onItemTypeSelected: (type) =>
                notifier.setItemTypeFilter(widget.storeId, type),
            onCategorySelected: (catId) =>
                notifier.setCategory(widget.storeId, catId),
            onSortSelected: (sortBy, order) =>
                notifier.setSort(widget.storeId, sortBy, order),
            onResetFilters: () {
              _debounce?.cancel();
              _searchController.clear();
              setState(() => _isSearchingLocal = false);
              notifier.resetFilters(widget.storeId);
            },
          ),
          Expanded(
            child: listState.isLoading && items.isEmpty
                ? const ItemsBentoGridShimmer()
                : RefreshIndicator(
                    color: TuLojitaBrandColors.primary,
                    onRefresh: () => notifier.loadInitial(widget.storeId),
                    child: CustomScrollView(
                      key: const Key('catalog_bento_scroll_view'),
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (items.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(
                              context,
                              canEditProducts: canEditProducts,
                              hasFilters: listState.hasActiveFilters ||
                                  _searchController.text.isNotEmpty,
                            ),
                          )
                        else ...[
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              14,
                              16,
                              canEditProducts ? 88 : 24,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, rowIndex) {
                                  final leftIndex = rowIndex * 2;
                                  final rightIndex = leftIndex + 1;
                                  final leftItem = items[leftIndex];
                                  final rightItem = rightIndex < items.length
                                      ? items[rightIndex]
                                      : null;

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          rowIndex < rowCount - 1 ? 12 : 0,
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: _buildGridCard(
                                              leftItem,
                                              canShowQuickActions:
                                                  canShowQuickActions,
                                              canEditProducts: canEditProducts,
                                              canChangePrices: canChangePrices,
                                              canManageStock: canManageStock,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: rightItem != null
                                                ? _buildGridCard(
                                                    rightItem,
                                                    canShowQuickActions:
                                                        canShowQuickActions,
                                                    canEditProducts:
                                                        canEditProducts,
                                                    canChangePrices:
                                                        canChangePrices,
                                                    canManageStock:
                                                        canManageStock,
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                childCount: rowCount,
                              ),
                            ),
                          ),
                          if (listState.isLoadMoreLoading)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: TuLojitaBrandColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(
    Item item, {
    required bool canShowQuickActions,
    required bool canEditProducts,
    required bool canChangePrices,
    required bool canManageStock,
  }) {
    return ItemBentoGridCard(
      item: item,
      canShowQuickActions: canShowQuickActions,
      onTap: () => _openItemDetail(item),
      onMoreTap: canShowQuickActions
          ? () => showItemListQuickActionsSheet(
                context: context,
                ref: ref,
                storeId: widget.storeId,
                item: item,
                canEditProducts: canEditProducts,
                canChangePrices: canChangePrices,
                canManageStock: canManageStock,
              )
          : null,
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required bool canEditProducts,
    required bool hasFilters,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: TuLojitaBrandColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedPackage01,
                color: TuLojitaBrandColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasFilters
                  ? 'No se encontraron resultados'
                  : 'No hay artículos aún',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: TuLojitaBrandColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Prueba con una búsqueda diferente o restablece los filtros activos para explorar tu catálogo.'
                  : (canEditProducts
                      ? 'Agrega tu primer producto o servicio para organizar tu inventario y comenzar a vender.'
                      : 'Actualmente no hay artículos registrados en el catálogo de esta sucursal.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TuLojitaBrandColors.inkSecondary,
                height: 1.4,
                fontSize: 13.5,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  _debounce?.cancel();
                  _searchController.clear();
                  setState(() => _isSearchingLocal = false);
                  ref
                      .read(itemListProvider.notifier)
                      .resetFilters(widget.storeId);
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Restablecer filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

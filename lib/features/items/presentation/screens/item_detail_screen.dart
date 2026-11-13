import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/item.dart';
import '../providers/item_list_notifier.dart';
import '../providers/item_owner_stats_provider.dart';
import '../providers/item_promotion_provider.dart';
import '../widgets/promote_item_sheet.dart';
import '../widgets/detail/item_detail_hero_gallery.dart';
import '../widgets/detail/item_overview_bento_grid.dart';
import '../widgets/detail/item_owner_bottom_bar.dart';
import '../widgets/detail/item_performance_card.dart';
import '../widgets/detail/item_price_profit_card.dart';
import '../widgets/detail/item_promotion_banner_card.dart';
import '../widgets/detail/item_quick_actions_sheets.dart';
import '../widgets/detail/item_specs_and_options_section.dart';
import '../widgets/detail/item_variants_bento_section.dart';

/// Modular Bento owner command center for inspecting and managing a product
/// or service item.
class ItemDetailScreen extends ConsumerStatefulWidget {
  final String storeId;
  final Item item;

  const ItemDetailScreen({
    super.key,
    required this.storeId,
    required this.item,
  });

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late final PageController _pageController;
  late final ScrollController _scrollController;
  int _currentPageIndex = 0;
  bool _isCollapsed = false;
  bool _isTogglingActive = false;
  late Item _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _pageController = PageController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final nextCollapsed = _scrollController.offset > 195;
    if (nextCollapsed != _isCollapsed && mounted) {
      setState(() => _isCollapsed = nextCollapsed);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshItem() async {
    ref.invalidate(itemOwnerStatsProvider(_currentItem.id));
    ref.invalidate(itemPromotionByItemProvider(_currentItem.id));

    await Future.wait([
      (() async {
        try {
          final fresh = await ref
              .read(itemRepositoryProvider)
              .getItemById(_currentItem.id);
          if (mounted) {
            setState(() => _currentItem = fresh);
          }
        } catch (_) {}
      })(),
      (() async {
        try {
          await ref.read(exchangeRateProvider.notifier).refreshRate();
        } catch (_) {}
      })(),
    ]);
  }

  Future<void> _togglePublishInPlace() async {
    if (_isTogglingActive) return;

    if (_currentItem.isActive) {
      final confirmed =
          await showItemUnpublishConfirmDialog(context, _currentItem);
      if (!confirmed || !mounted) return;
    }

    setState(() => _isTogglingActive = true);
    try {
      await ref
          .read(itemListProvider.notifier)
          .toggleItemActive(widget.storeId, _currentItem);
      if (!mounted) return;
      final nextActive = !_currentItem.isActive;
      setState(() {
        _currentItem = _currentItem.copyWith(isActive: nextActive);
        _isTogglingActive = false;
      });
      NotificationService.showSuccess(
        context,
        nextActive ? 'Artículo publicado' : 'Artículo despublicado',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTogglingActive = false);
      NotificationService.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _openEditWizard() async {
    final result = await context.push(
      '/dashboard/stores/${widget.storeId}/items/new',
      extra: _currentItem,
    );
    if (result == true && mounted) {
      ref.read(itemListProvider.notifier).loadInitial(widget.storeId);
      await _refreshItem();
    }
  }

  Future<void> _openDuplicateWizard() async {
    await context.push(
      '/dashboard/stores/${widget.storeId}/items/new',
      extra: {'duplicateFrom': _currentItem},
    );
  }

  Future<void> _openPromoteSheet() async {
    await PromoteItemSheet.show(context, _currentItem, widget.storeId);
    if (mounted) {
      ref.invalidate(itemPromotionByItemProvider(_currentItem.id));
    }
  }

  Future<void> _openQuickPriceSheet() async {
    final updated = await showQuickPriceSheet(context, _currentItem);
    if (updated != null && mounted) {
      final resolvedItem = updated;
      setState(() => _currentItem = resolvedItem);
      ref
          .read(itemListProvider.notifier)
          .upsertItem(widget.storeId, resolvedItem);
    }
  }

  Future<void> _openQuickInventoryOrVariants({
    required bool canManageStock,
    required bool canChangePrices,
  }) async {
    Item? updated;
    if (_currentItem.hasVariants && _currentItem.variants.isNotEmpty) {
      updated = await showQuickVariantsSheet(
        context,
        _currentItem,
        canManageStock: canManageStock,
        canChangePrices: canChangePrices,
      );
    } else {
      updated = await showQuickStockSheet(context, _currentItem);
    }

    if (updated != null && mounted) {
      final resolvedItem = updated;
      setState(() => _currentItem = resolvedItem);
      ref
          .read(itemListProvider.notifier)
          .upsertItem(widget.storeId, resolvedItem);
    }
  }

  Future<void> _confirmDeleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TuLojitaBrandColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Eliminar Artículo?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${_currentItem.title}"? Esta acción no se puede deshacer.',
          style: const TextStyle(
            fontSize: 14,
            color: TuLojitaBrandColors.inkSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TuLojitaBrandColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref
            .read(itemListProvider.notifier)
            .deleteItem(widget.storeId, _currentItem.id);
        if (mounted) {
          NotificationService.showSuccess(
            context,
            'Artículo eliminado exitosamente',
          );
          context.pop(true);
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(
            context,
            e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;

    final canEditProducts = user?.canEditProducts ?? false;
    final canChangePrices = user?.canChangePrices ?? false;
    final canManageStock = user?.canManageStock ?? false;
    final canViewSensitiveFinances = user?.canViewSensitiveFinances ?? false;

    final item = _currentItem;

    return Scaffold(
      backgroundColor: TuLojitaBrandColors.canvas,
      bottomNavigationBar: ItemOwnerBottomBar(
        item: item,
        canEditProducts: canEditProducts,
        isTogglingActive: _isTogglingActive,
        onTogglePublish: _togglePublishInPlace,
        onEdit: _openEditWizard,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshItem,
        color: TuLojitaBrandColors.indigo600,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            ItemDetailHeroGallery(
              item: item,
              pageController: _pageController,
              currentPageIndex: _currentPageIndex,
              onPageChanged: (index) => setState(() => _currentPageIndex = index),
              isCollapsed: _isCollapsed,
              canEditProducts: canEditProducts,
              onPromote: _openPromoteSheet,
              onEdit: _openEditWizard,
              onDuplicate: _openDuplicateWizard,
              onDelete: _confirmDeleteItem,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ItemPriceProfitCard(
                      item: item,
                      canChangePrices: canChangePrices,
                      canViewSensitiveFinances: canViewSensitiveFinances,
                      onAdjustPrice: _openQuickPriceSheet,
                    ),
                    if (canEditProducts) ...[
                      const SizedBox(height: 14),
                      ItemPromotionBannerCard(
                        item: item,
                        canEditProducts: canEditProducts,
                        onPromote: _openPromoteSheet,
                      ),
                    ],
                    const SizedBox(height: 14),
                    ItemPerformanceCard(
                      item: item,
                      canViewSensitiveFinances: canViewSensitiveFinances,
                    ),
                    const SizedBox(height: 14),
                    ItemOverviewBentoGrid(
                      item: item,
                      canEditProducts: canEditProducts,
                      canManageStock: canManageStock,
                      isTogglingActive: _isTogglingActive,
                      onToggleActive:
                          canEditProducts ? _togglePublishInPlace : null,
                      onAdjustInventory: canManageStock && item.trackInventory
                          ? () => _openQuickInventoryOrVariants(
                                canManageStock: canManageStock,
                                canChangePrices: canChangePrices,
                              )
                          : null,
                    ),
                    if (item.hasVariants && item.variants.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ItemVariantsBentoSection(
                        item: item,
                        canManageVariants: canManageStock || canChangePrices,
                        onManageVariants: () => _openQuickInventoryOrVariants(
                          canManageStock: canManageStock,
                          canChangePrices: canChangePrices,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    ItemSpecsAndOptionsSection(item: item),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

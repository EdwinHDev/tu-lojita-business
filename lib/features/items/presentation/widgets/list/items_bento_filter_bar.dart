import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_category.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_list_state.dart';

/// Header pill showing the active BCV rate (`Tasa BCV: Bs. XX,XX`) and tap-to-refresh.
class BcvRateHeaderPill extends ConsumerWidget {
  final bool compactSubtitle;

  const BcvRateHeaderPill({
    super.key,
    this.compactSubtitle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateAsync = ref.watch(exchangeRateProvider);
    final ExchangeRateConfig rateConfig = rateAsync.maybeWhen(
      data: (c) => c,
      orElse: ExchangeRateConfig.disabled,
    );

    if (!PriceFormatter.isDualEnabled(rateConfig)) {
      return const SizedBox.shrink();
    }

    final formattedRate = PriceFormatter.formatRateValue(
      rateConfig.rate,
      symbol: rateConfig.symbol,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('bcv_rate_header_pill'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => ref.read(exchangeRateProvider.notifier).refreshRate(),
        child: Container(
          padding: compactSubtitle
              ? const EdgeInsets.symmetric(horizontal: 7, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: TuLojitaBrandColors.primarySoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: TuLojitaBrandColors.primary.withValues(alpha: 0.22),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.currency_exchange_rounded,
                  size: compactSubtitle ? 11 : 13,
                  color: TuLojitaBrandColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tasa BCV: $formattedRate',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: compactSubtitle ? 10.5 : 11,
                    fontWeight: FontWeight.w700,
                    color: TuLojitaBrandColors.primary,
                  ),
                ),
                if (compactSubtitle) ...[
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.refresh_rounded,
                    size: 10,
                    color: TuLojitaBrandColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ItemsBentoFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final ItemListData listState;
  final List<StoreCategory> categories;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<ItemCatalogStatusFilter> onStatusFilterSelected;
  final ValueChanged<ItemType?> onItemTypeSelected;
  final ValueChanged<String?> onCategorySelected;
  final void Function(String sortBy, String order) onSortSelected;
  final VoidCallback onResetFilters;

  const ItemsBentoFilterBar({
    super.key,
    required this.searchController,
    required this.isSearching,
    required this.listState,
    required this.categories,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStatusFilterSelected,
    required this.onItemTypeSelected,
    required this.onCategorySelected,
    required this.onSortSelected,
    required this.onResetFilters,
  });

  void _showSortAndTypeSheet(BuildContext context) {
    final summary = listState.effectiveSummary;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TuLojitaBrandColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TuLojitaBrandColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filtrar y ordenar catálogo',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tipo de artículo',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _BentoFilterChip(
                      chipKey: const Key('filter_type_all'),
                      label: 'Todos (${summary.total})',
                      isSelected: listState.itemTypeFilter == null,
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        onItemTypeSelected(null);
                      },
                    ),
                    _BentoFilterChip(
                      chipKey: const Key('filter_type_product'),
                      label: 'Productos (${summary.products})',
                      isSelected:
                          listState.itemTypeFilter == ItemType.product,
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        onItemTypeSelected(ItemType.product);
                      },
                    ),
                    _BentoFilterChip(
                      chipKey: const Key('filter_type_service'),
                      label: 'Servicios (${summary.services})',
                      isSelected:
                          listState.itemTypeFilter == ItemType.service,
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        onItemTypeSelected(ItemType.service);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ordenar por',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _BentoFilterChip(
                      chipKey: const Key('sort_recent'),
                      label: 'Recientes',
                      isSelected: listState.sortBy == 'createdAt' &&
                          listState.order == 'DESC',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        onSortSelected('createdAt', 'DESC');
                      },
                    ),
                    _BentoFilterChip(
                      chipKey: const Key('sort_price_asc'),
                      label: 'Precio: menor a mayor',
                      isSelected: listState.sortBy == 'price' &&
                          listState.order == 'ASC',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        onSortSelected('price', 'ASC');
                      },
                    ),
                    _BentoFilterChip(
                      chipKey: const Key('sort_price_desc'),
                      label: 'Precio: mayor a menor',
                      isSelected: listState.sortBy == 'price' &&
                          listState.order == 'DESC',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        onSortSelected('price', 'DESC');
                      },
                    ),
                    _BentoFilterChip(
                      chipKey: const Key('sort_stock_asc'),
                      label: 'Menor stock',
                      isSelected: listState.sortBy == 'stockQuantity' &&
                          listState.order == 'ASC',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        onSortSelected('stockQuantity', 'ASC');
                      },
                    ),
                    _BentoFilterChip(
                      chipKey: const Key('sort_favorites_desc'),
                      label: 'Más favoritos',
                      isSelected: listState.sortBy == 'favoritesCount' &&
                          listState.order == 'DESC',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        onSortSelected('favoritesCount', 'DESC');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = listState.effectiveSummary;
    final hasSortOrTypeActive = listState.hasNonDefaultSortOrType;
    final showCategoryOrResetRow =
        categories.isNotEmpty || listState.hasActiveFilters;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: TuLojitaBrandColors.surface,
        border: Border(
          bottom: BorderSide(color: TuLojitaBrandColors.borderMuted),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 0: Search Input + Compact Sort/Type Trigger Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('catalog_search_input'),
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar por título...',
                    hintStyle: const TextStyle(
                      color: TuLojitaBrandColors.inkMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: TuLojitaBrandColors.inkMuted,
                      size: 20,
                    ),
                    suffixIcon: (isSearching || listState.isLoading) &&
                            searchController.text.isNotEmpty
                        ? const UnconstrainedBox(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: TuLojitaBrandColors.primary,
                              ),
                            ),
                          )
                        : searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: TuLojitaBrandColors.inkSecondary,
                                  size: 18,
                                ),
                                onPressed: onClearSearch,
                              )
                            : null,
                    filled: true,
                    fillColor: TuLojitaBrandColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: TuLojitaBrandColors.borderMuted,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: TuLojitaBrandColors.borderMuted,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: TuLojitaBrandColors.primary,
                        width: 1.4,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('catalog_sort_type_button'),
                  onTap: () => _showSortAndTypeSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: hasSortOrTypeActive
                          ? TuLojitaBrandColors.primarySoft
                          : TuLojitaBrandColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasSortOrTypeActive
                            ? TuLojitaBrandColors.primary
                            : TuLojitaBrandColors.borderMuted,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: hasSortOrTypeActive
                              ? TuLojitaBrandColors.primary
                              : TuLojitaBrandColors.inkSecondary,
                        ),
                        if (hasSortOrTypeActive) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: TuLojitaBrandColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 1: Unified Operational Status + Live Count Bento Pills (Single source of truth)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _UnifiedStatusCountPill(
                  pillKey: const Key('filter_status_all'),
                  countKey: const Key('status_count_all'),
                  label: 'Todos',
                  count: summary.total,
                  accentColor: TuLojitaBrandColors.primary,
                  badgeBgColor: TuLojitaBrandColors.primarySoft,
                  isSelected:
                      listState.statusFilter == ItemCatalogStatusFilter.all,
                  onTap: () =>
                      onStatusFilterSelected(ItemCatalogStatusFilter.all),
                ),
                _UnifiedStatusCountPill(
                  pillKey: const Key('filter_status_published'),
                  countKey: const Key('status_count_published'),
                  label: 'Publicados',
                  count: summary.published,
                  accentColor: TuLojitaBrandColors.positive,
                  badgeBgColor: TuLojitaBrandColors.positiveBg,
                  isSelected: listState.statusFilter ==
                      ItemCatalogStatusFilter.published,
                  onTap: () =>
                      onStatusFilterSelected(ItemCatalogStatusFilter.published),
                ),
                _UnifiedStatusCountPill(
                  pillKey: const Key('filter_status_paused'),
                  countKey: const Key('status_count_paused'),
                  label: 'Pausados',
                  count: summary.paused,
                  accentColor: TuLojitaBrandColors.danger,
                  badgeBgColor: TuLojitaBrandColors.dangerBg,
                  isSelected:
                      listState.statusFilter == ItemCatalogStatusFilter.paused,
                  onTap: () =>
                      onStatusFilterSelected(ItemCatalogStatusFilter.paused),
                ),
                _UnifiedStatusCountPill(
                  pillKey: const Key('filter_status_out_of_stock'),
                  countKey: const Key('status_count_outOfStock'),
                  label: 'Agotados',
                  count: summary.outOfStock,
                  accentColor: TuLojitaBrandColors.amber700,
                  badgeBgColor: TuLojitaBrandColors.amber50,
                  isSelected: listState.statusFilter ==
                      ItemCatalogStatusFilter.outOfStock,
                  onTap: () => onStatusFilterSelected(
                    ItemCatalogStatusFilter.outOfStock,
                  ),
                ),
                _UnifiedStatusCountPill(
                  pillKey: const Key('filter_status_discounted'),
                  countKey: const Key('status_count_discounted'),
                  label: 'En oferta',
                  count: summary.discounted,
                  accentColor: TuLojitaBrandColors.positive,
                  badgeBgColor: TuLojitaBrandColors.positiveBg,
                  isSelected: listState.statusFilter ==
                      ItemCatalogStatusFilter.discounted,
                  onTap: () => onStatusFilterSelected(
                    ItemCatalogStatusFilter.discounted,
                  ),
                ),
              ],
            ),
          ),
          // Row 2: Dedicated Store Categories Row + Active Reset Button
          if (showCategoryOrResetRow) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (categories.isNotEmpty) ...[
                    _BentoFilterChip(
                      chipKey: const Key('filter_category_all'),
                      label: 'Todas',
                      isSelected: listState.selectedCategoryId == null,
                      onTap: () => onCategorySelected(null),
                    ),
                    ...categories.map(
                      (cat) => _BentoFilterChip(
                        chipKey: Key('filter_category_${cat.id}'),
                        label: cat.name,
                        isSelected: listState.selectedCategoryId == cat.id,
                        onTap: () => onCategorySelected(cat.id),
                      ),
                    ),
                  ],
                  if (listState.hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: InkWell(
                        key: const Key('reset_catalog_filters_button'),
                        onTap: onResetFilters,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: TuLojitaBrandColors.dangerBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: TuLojitaBrandColors.danger
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 13,
                                color: TuLojitaBrandColors.danger,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Limpiar',
                                style: TextStyle(
                                  color: TuLojitaBrandColors.danger,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnifiedStatusCountPill extends StatelessWidget {
  final Key pillKey;
  final Key countKey;
  final String label;
  final int count;
  final Color accentColor;
  final Color badgeBgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnifiedStatusCountPill({
    required this.pillKey,
    required this.countKey,
    required this.label,
    required this.count,
    required this.accentColor,
    required this.badgeBgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: pillKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? badgeBgColor : TuLojitaBrandColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : TuLojitaBrandColors.borderMuted,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor
                        : accentColor.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? accentColor
                        : TuLojitaBrandColors.inkPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.14)
                        : TuLojitaBrandColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.25)
                          : TuLojitaBrandColors.borderMuted,
                    ),
                  ),
                  child: Text(
                    '$count',
                    key: countKey,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? accentColor
                          : TuLojitaBrandColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BentoFilterChip extends StatelessWidget {
  final Key? chipKey;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BentoFilterChip({
    this.chipKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: chipKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? TuLojitaBrandColors.primarySoft
                  : TuLojitaBrandColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? TuLojitaBrandColors.primary
                    : TuLojitaBrandColors.borderMuted,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected
                    ? TuLojitaBrandColors.primary
                    : TuLojitaBrandColors.inkSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item_catalog_summary.dart';
import '../detail/item_detail_helpers.dart';

class ItemsBentoKpiStrip extends StatelessWidget {
  final ItemCatalogSummary summary;
  final ItemCatalogStatusFilter selectedFilter;
  final ValueChanged<ItemCatalogStatusFilter> onSelectFilter;

  const ItemsBentoKpiStrip({
    super.key,
    required this.summary,
    required this.selectedFilter,
    required this.onSelectFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoKpiTile(
                  key: const Key('kpi_tile_all'),
                  label: 'Total',
                  subtitle: '${summary.products} prod · ${summary.services} serv',
                  count: summary.total,
                  icon: Icons.inventory_2_outlined,
                  accentColor: TuLojitaBrandColors.primary,
                  badgeBgColor: TuLojitaBrandColors.primarySoft,
                  isSelected: selectedFilter == ItemCatalogStatusFilter.all,
                  onTap: () => onSelectFilter(ItemCatalogStatusFilter.all),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BentoKpiTile(
                  key: const Key('kpi_tile_published'),
                  label: 'Publicados',
                  subtitle: 'Visibles en tienda',
                  count: summary.published,
                  icon: Icons.check_circle_outline_rounded,
                  accentColor: TuLojitaBrandColors.positive,
                  badgeBgColor: TuLojitaBrandColors.positiveBg,
                  isSelected:
                      selectedFilter == ItemCatalogStatusFilter.published,
                  onTap: () =>
                      onSelectFilter(ItemCatalogStatusFilter.published),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoKpiTile(
                  key: const Key('kpi_tile_paused'),
                  label: 'Pausados',
                  subtitle: 'Ocultos al público',
                  count: summary.paused,
                  icon: Icons.pause_circle_outline_rounded,
                  accentColor: TuLojitaBrandColors.danger,
                  badgeBgColor: TuLojitaBrandColors.dangerBg,
                  isSelected: selectedFilter == ItemCatalogStatusFilter.paused,
                  onTap: () => onSelectFilter(ItemCatalogStatusFilter.paused),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BentoKpiTile(
                  key: const Key('kpi_tile_out_of_stock'),
                  label: 'Agotados',
                  subtitle: 'Sin stock disponible',
                  count: summary.outOfStock,
                  icon: Icons.warning_amber_rounded,
                  accentColor: TuLojitaBrandColors.amber700,
                  badgeBgColor: TuLojitaBrandColors.amber50,
                  isSelected:
                      selectedFilter == ItemCatalogStatusFilter.outOfStock,
                  onTap: () =>
                      onSelectFilter(ItemCatalogStatusFilter.outOfStock),
                ),
              ),
            ],
          ),
        ),
        if (summary.discounted > 0 ||
            selectedFilter == ItemCatalogStatusFilter.discounted) ...[
          const SizedBox(height: 10),
          _DiscountedSummaryBanner(
            key: const Key('kpi_tile_discounted'),
            count: summary.discounted,
            isSelected: selectedFilter == ItemCatalogStatusFilter.discounted,
            onTap: () => onSelectFilter(ItemCatalogStatusFilter.discounted),
          ),
        ],
      ],
    );
  }
}

class _BentoKpiTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color accentColor;
  final Color badgeBgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _BentoKpiTile({
    super.key,
    required this.label,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.badgeBgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: itemBentoCardDecoration(
            color: isSelected
                ? badgeBgColor.withValues(alpha: 0.55)
                : TuLojitaBrandColors.surface,
            borderColor:
                isSelected ? accentColor : TuLojitaBrandColors.borderMuted,
            radius: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 15, color: accentColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? accentColor
                            : TuLojitaBrandColors.inkPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? accentColor
                      : TuLojitaBrandColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: TuLojitaBrandColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscountedSummaryBanner extends StatelessWidget {
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _DiscountedSummaryBanner({
    super.key,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? TuLojitaBrandColors.positiveBg
                : TuLojitaBrandColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? TuLojitaBrandColors.positive
                  : TuLojitaBrandColors.borderMuted,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 15,
                color: TuLojitaBrandColors.positive,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ofertas activas: $count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isSelected ? 'Quitar filtro' : 'Filtrar',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: TuLojitaBrandColors.positive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

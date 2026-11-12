import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item_owner_stats.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_owner_stats_provider.dart';
import 'item_detail_helpers.dart';

/// Bento card showing commercial item metrics (`unitsSold`, `ordersCount`,
/// `favoritesCount`) and RBAC-gated financial revenue totals (`grossRevenue` &
/// `netRevenue`) in USD + `~ Bs.`.
class ItemPerformanceCard extends ConsumerWidget {
  final Item item;
  final bool canViewSensitiveFinances;

  const ItemPerformanceCard({
    super.key,
    required this.item,
    required this.canViewSensitiveFinances,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(itemOwnerStatsProvider(item.id));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: itemBentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedChartHistogram,
                size: 18,
                color: TuLojitaBrandColors.indigo600,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rendimiento Comercial',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          statsAsync.when(
            loading: () => const _StatsLoadingPlaceholder(),
            error: (_, _) => _buildCountersRow(
              unitsSold: 0,
              ordersCount: 0,
              favoritesCount: item.favoritesCount,
              isFallback: true,
            ),
            data: (stats) => _buildLoadedStats(stats),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedStats(ItemOwnerStats stats) {
    final favorites = stats.favoritesCount > 0
        ? stats.favoritesCount
        : item.favoritesCount;
    final showFinancials = canViewSensitiveFinances &&
        stats.canViewFinancials &&
        stats.grossRevenue != null &&
        stats.netRevenue != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCountersRow(
          unitsSold: stats.unitsSold,
          ordersCount: stats.ordersCount,
          favoritesCount: favorites,
        ),
        if (showFinancials) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TuLojitaBrandColors.borderMuted),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                final stack = constraints.maxWidth < 260 || textScale >= 1.3;
                final grossWidget = _FinancialStatTile(
                  label: 'Ingresos brutos',
                  amountUsd: stats.grossRevenue!,
                  valueColor: TuLojitaBrandColors.inkPrimary,
                );
                final netWidget = _FinancialStatTile(
                  label: 'Neto acumulado',
                  amountUsd: stats.netRevenue!,
                  valueColor: TuLojitaBrandColors.positive,
                );
                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      grossWidget,
                      const SizedBox(height: 10),
                      netWidget,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: grossWidget),
                    Container(
                      width: 1,
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: TuLojitaBrandColors.borderMuted,
                    ),
                    Expanded(child: netWidget),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCountersRow({
    required int unitsSold,
    required int ordersCount,
    required int favoritesCount,
    bool isFallback = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final cols =
            (constraints.maxWidth >= 280 && textScale <= 1.25) ? 3 : 2;
        const spacing = 8.0;
        final tileWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _CounterTile(
                    label: 'Vendidos',
                    value: isFallback ? '—' : '$unitsSold',
                    icon: Icons.shopping_bag_outlined,
                    tint: TuLojitaBrandColors.indigo600,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _CounterTile(
                    label: 'Órdenes',
                    value: isFallback ? '—' : '$ordersCount',
                    icon: Icons.receipt_long_outlined,
                    tint: TuLojitaBrandColors.indigo600,
                  ),
                ),
                SizedBox(
                  width: cols == 2 ? constraints.maxWidth : tileWidth,
                  child: _CounterTile(
                    label: 'Favoritos',
                    value: '$favoritesCount',
                    icon: Icons.favorite_border_rounded,
                    tint: TuLojitaBrandColors.danger,
                  ),
                ),
              ],
            ),
            if (isFallback) ...[
              const SizedBox(height: 8),
              const Text(
                'No se pudieron cargar las métricas de ventas ahora.',
                style: TextStyle(
                  fontSize: 11,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CounterTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  const _CounterTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TuLojitaBrandColors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: tint),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: TuLojitaBrandColors.inkPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialStatTile extends StatelessWidget {
  final String label;
  final double amountUsd;
  final Color valueColor;

  const _FinancialStatTile({
    required this.label,
    required this.amountUsd,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: TuLojitaBrandColors.inkSecondary,
          ),
        ),
        const SizedBox(height: 3),
        DualPriceText(
          amountInUsd: amountUsd,
          useScaleDown: true,
          usdStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
          bsStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: TuLojitaBrandColors.inkSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatsLoadingPlaceholder extends StatelessWidget {
  const _StatsLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: ShimmerWidget(width: double.infinity, height: 54)),
            SizedBox(width: 8),
            Expanded(child: ShimmerWidget(width: double.infinity, height: 54)),
            SizedBox(width: 8),
            Expanded(child: ShimmerWidget(width: double.infinity, height: 54)),
          ],
        ),
        SizedBox(height: 10),
        ShimmerWidget(width: double.infinity, height: 48),
      ],
    );
  }
}

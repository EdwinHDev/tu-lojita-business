import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_dashboard.dart';

/// Formats day-over-day growth percentage without ever rendering double signs like "+-".
String formatSignedPercentage(double percentage) {
  if (percentage > 0) return '+${percentage.toStringAsFixed(1)}%';
  if (percentage < 0) return '${percentage.toStringAsFixed(1)}%';
  return 'Sin cambios';
}

/// Permission-adaptive Bento KPI block for a single store branch.
class StoreDetailsMetricsBento extends StatelessWidget {
  final StoreStats stats;
  final bool canViewFinancials;
  final bool canViewOrders;
  final VoidCallback? onTapPendingOrders;
  final VoidCallback? onTapItems;
  final VoidCallback? onTapCategories;

  const StoreDetailsMetricsBento({
    super.key,
    required this.stats,
    required this.canViewFinancials,
    required this.canViewOrders,
    this.onTapPendingOrders,
    this.onTapItems,
    this.onTapCategories,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <_KpiTileData>[
      if (canViewOrders)
        _KpiTileData(
          label: 'Por atender',
          value: '${stats.pendingOrdersCount}',
          icon: HugeIcons.strokeRoundedShoppingBag01,
          iconColor: stats.pendingOrdersCount > 0
              ? TuLojitaBrandColors.amber700
              : TuLojitaBrandColors.indigo600,
          iconBg: stats.pendingOrdersCount > 0
              ? TuLojitaBrandColors.amber50
              : TuLojitaBrandColors.indigo50,
          onTap: onTapPendingOrders,
        ),
      if (!canViewFinancials) ...[
        _KpiTileData(
          label: 'Artículos',
          value: '${stats.totalItems}',
          icon: HugeIcons.strokeRoundedPackage,
          iconColor: TuLojitaBrandColors.indigo600,
          iconBg: TuLojitaBrandColors.indigo50,
          onTap: onTapItems,
        ),
        _KpiTileData(
          label: 'Categorías',
          value: '${stats.totalCategories}',
          icon: HugeIcons.strokeRoundedFolder01,
          iconColor: TuLojitaBrandColors.amber700,
          iconBg: TuLojitaBrandColors.amber50,
          onTap: onTapCategories,
        ),
        _KpiTileData(
          label: 'Clientes',
          value: '${stats.totalCustomers}',
          icon: HugeIcons.strokeRoundedUserMultiple,
          iconColor: TuLojitaBrandColors.positive,
          iconBg: TuLojitaBrandColors.positiveBg,
        ),
      ] else ...[
        _KpiTileData(
          label: 'Clientes',
          value: '${stats.totalCustomers}',
          icon: HugeIcons.strokeRoundedUserMultiple,
          iconColor: const Color(0xFF2563EB),
          iconBg: const Color(0xFFEFF6FF),
        ),
        _KpiTileData(
          label: 'Artículos',
          value: '${stats.totalItems}',
          icon: HugeIcons.strokeRoundedPackage,
          iconColor: TuLojitaBrandColors.indigo600,
          iconBg: TuLojitaBrandColors.indigo50,
          onTap: onTapItems,
        ),
        if (!canViewOrders)
          _KpiTileData(
            label: 'Categorías',
            value: '${stats.totalCategories}',
            icon: HugeIcons.strokeRoundedFolder01,
            iconColor: TuLojitaBrandColors.amber700,
            iconBg: TuLojitaBrandColors.amber50,
            onTap: onTapCategories,
          ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Métricas Clave',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: TuLojitaBrandColors.inkPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Hoy',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TuLojitaBrandColors.inkSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (canViewFinancials) ...[
          _SalesHeroCard(
            salesToday: stats.salesToday,
            salesTodayPercentage: stats.salesTodayPercentage,
          ),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final useThreeColumns = !canViewFinancials
                ? constraints.maxWidth >= 560
                : (constraints.maxWidth >= 380 && textScale <= 1.15);
            final columns = useThreeColumns
                ? (tiles.length >= 3 ? 3 : tiles.length.clamp(1, 3))
                : (tiles.length >= 2 ? 2 : 1);
            final tileWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var i = 0; i < tiles.length; i++)
                  SizedBox(
                    width: (!useThreeColumns &&
                            columns == 2 &&
                            tiles.length.isOdd &&
                            i == tiles.length - 1)
                        ? constraints.maxWidth
                        : tileWidth,
                    child: _KpiMiniCard(data: tiles[i]),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SalesHeroCard extends StatelessWidget {
  final double salesToday;
  final double salesTodayPercentage;

  const _SalesHeroCard({
    required this.salesToday,
    required this.salesTodayPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final deltaText = formatSignedPercentage(salesTodayPercentage);
    final isPositive = salesTodayPercentage > 0;
    final isNegative = salesTodayPercentage < 0;

    final Color pillBg = isPositive
        ? const Color(0xFF10B981).withValues(alpha: 0.22)
        : isNegative
            ? const Color(0xFFEF4444).withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.16);
    final Color pillFg = isPositive
        ? const Color(0xFFA7F3D0)
        : isNegative
            ? const Color(0xFFFECACA)
            : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            TuLojitaBrandColors.indigo600,
            TuLojitaBrandColors.indigo700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: TuLojitaBrandColors.indigo600.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDollarCircle,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ventas de hoy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      deltaText,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: pillFg,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DualPriceText(
            amountInUsd: salesToday,
            usdStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            bsStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTileData {
  final String label;
  final String value;
  final dynamic icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  const _KpiTileData({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  });
}

class _KpiMiniCard extends StatelessWidget {
  final _KpiTileData data;

  const _KpiMiniCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TuLojitaBrandColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: data.icon,
                  color: data.iconColor,
                  size: 16,
                ),
              ),
              const Spacer(),
              if (data.onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                data.value,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.inkPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                data.label,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (data.onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}

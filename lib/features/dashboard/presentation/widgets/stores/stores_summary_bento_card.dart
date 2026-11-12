import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';

/// Unified Bento summary card replacing the legacy 3-color metric cards.
///
/// Renders Indigo 600 hero `Ventas Hoy` with dual pricing when [canViewFinancials]
/// is true, or strictly operational non-monetary totals when disallowed.
class StoresSummaryBentoCard extends StatelessWidget {
  final DashboardStats stats;
  final List<Store> stores;
  final Map<String, int> unreadDisputesByStore;
  final bool canViewFinancials;

  const StoresSummaryBentoCard({
    super.key,
    required this.stats,
    required this.stores,
    required this.unreadDisputesByStore,
    this.canViewFinancials = true,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = stores.where((s) => s.isOperationalActive).length;
    final attentionCount = stores
        .where(
          (s) => s.needsOperationalAttention(
            unreadDisputesCount: unreadDisputesByStore[s.id] ?? 0,
            canViewFinancials: canViewFinancials,
          ),
        )
        .length;

    if (!canViewFinancials) {
      return _buildOperationalCard(
        authorizedCount: stores.length,
        attentionCount: attentionCount,
        productsCount: stats.totalProducts.count,
      );
    }

    final pct = stats.salesToday.percentage;
    final String deltaLabel;
    final Color deltaBg;
    final Color deltaFg;
    if (pct > 0) {
      deltaLabel = '+${pct.toStringAsFixed(1)}%';
      deltaBg = Colors.white.withValues(alpha: 0.18);
      deltaFg = TuLojitaBrandColors.amber400;
    } else if (pct < 0) {
      deltaLabel = '${pct.toStringAsFixed(1)}%';
      deltaBg = TuLojitaBrandColors.dangerBg;
      deltaFg = TuLojitaBrandColors.danger;
    } else {
      deltaLabel = 'Sin cambios';
      deltaBg = Colors.white.withValues(alpha: 0.16);
      deltaFg = Colors.white70;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TuLojitaBrandColors.indigo600,
            TuLojitaBrandColors.indigo700,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'VENTAS DE HOY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: deltaBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  deltaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: deltaFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DualPriceText(
            amountInUsd: stats.salesToday.amount,
            usdStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: Colors.white,
            ),
            bsStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroMiniStat(
                  label: 'Sedes Activas',
                  value: '$activeCount',
                  badge: stats.totalStores.increment > 0
                      ? '+${stats.totalStores.increment} mes'
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMiniStat(
                  label: 'Con Atención',
                  value: '$attentionCount',
                  valueColor: attentionCount > 0
                      ? TuLojitaBrandColors.amber400
                      : Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMiniStat(
                  label: 'Productos',
                  value: '${stats.totalProducts.count}',
                  badge: stats.totalProducts.increment > 0
                      ? '+${stats.totalProducts.increment} sem'
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalCard({
    required int authorizedCount,
    required int attentionCount,
    required int productsCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: TuLojitaBrandColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedStore01,
                color: TuLojitaBrandColors.indigo600,
                size: 16,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'RESUMEN OPERATIVO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LightMiniStat(
                  label: 'Sedes Autorizadas',
                  value: '$authorizedCount',
                  valueColor: TuLojitaBrandColors.indigo600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LightMiniStat(
                  label: 'Con Atención',
                  value: '$attentionCount',
                  valueColor: attentionCount > 0
                      ? TuLojitaBrandColors.amber800
                      : TuLojitaBrandColors.inkPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LightMiniStat(
                  label: 'Productos',
                  value: '$productsCount',
                  valueColor: TuLojitaBrandColors.inkPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  final Color valueColor;

  const _HeroMiniStat({
    required this.label,
    required this.value,
    this.badge,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 5,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: TuLojitaBrandColors.amber400,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LightMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _LightMiniStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.canvas,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: TuLojitaBrandColors.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_analytics.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_branch_resolver.dart';

/// Responsive 3-slide swipeable Bento KPI carousel on mobile (`< 600px`)
/// expanding into a multi-column Bento grid on tablets (`>= 600px`).
class HomeKpiCarousel extends ConsumerStatefulWidget {
  final DashboardAnalytics analytics;
  final List<Store> stores;
  final String selectedStoreId;

  const HomeKpiCarousel({
    super.key,
    required this.analytics,
    required this.stores,
    required this.selectedStoreId,
  });

  @override
  ConsumerState<HomeKpiCarousel> createState() => _HomeKpiCarouselState();
}

class _HomeKpiCarouselState extends ConsumerState<HomeKpiCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openStoresTab() {
    ref.read(dashboardIndexProvider.notifier).state = 1;
  }

  void _navigateRanking(BuildContext context) {
    final topStoreId = widget.analytics.operationalSummary.topRankingStoreId;
    if (topStoreId != null && topStoreId.isNotEmpty) {
      context.push('/dashboard/stores/$topStoreId/ranking');
      return;
    }
    if (widget.selectedStoreId != 'all' && widget.selectedStoreId.isNotEmpty) {
      context.push('/dashboard/stores/${widget.selectedStoreId}/ranking');
      return;
    }
    if (widget.stores.length == 1) {
      context.push('/dashboard/stores/${widget.stores.first.id}/ranking');
      return;
    }
    _openStoresTab();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(exchangeRateProvider).asData?.value;
    final showBs = PriceFormatter.isDualEnabled(config);
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.35);

    final kpis = widget.analytics.kpis;
    final summary = widget.analytics.operationalSummary;

    final pendingOptions = kpis.pendingOrders > 0
        ? buildPendingOrdersOriginOptions(
            summary: summary,
            stores: widget.stores,
          )
        : const <OriginStoreOption>[];

    final receivablesOptions = kpis.accountsReceivable > 0
        ? buildReceivablesOriginOptions(
            summary: summary,
            stores: widget.stores,
            exchangeConfig: config,
          )
        : const <OriginStoreOption>[];

    final hasDebtOrReports = summary.totalCommissionDebt > 0 ||
        summary.pendingCommissionReportsCount > 0;
    final commissionOptions = hasDebtOrReports
        ? buildCommissionOriginOptions(
            summary: summary,
            stores: widget.stores,
            exchangeConfig: config,
          )
        : const <OriginStoreOption>[];

    final promoOptions = buildPromotionsOriginOptions(
      summary: summary,
      stores: widget.stores,
    );

    final slides = <Widget>[
      _HeroPulseSlide(
        kpis: kpis,
        salesChart: widget.analytics.salesChart,
        onOrdersTap: () => navigateOriginOrHub(
          context,
          selectedStoreId: widget.selectedStoreId,
          fallbackStores: widget.stores,
          options: pendingOptions,
          sheetTitle: 'Pedidos pendientes por sede',
          routeSuffix: 'orders',
          onPushRoute: (path) => context.push(path),
          onOpenStoresTab: _openStoresTab,
        ),
      ),
      _CashAndReceivablesSlide(
        kpis: kpis,
        onInstallmentsTap: kpis.accountsReceivable > 0
            ? () => navigateOriginOrHub(
                  context,
                  selectedStoreId: widget.selectedStoreId,
                  fallbackStores: widget.stores,
                  options: receivablesOptions,
                  sheetTitle: 'Cartera por cobrar por sede',
                  routeSuffix: 'installments',
                  onPushRoute: (path) => context.push(path),
                  onOpenStoresTab: _openStoresTab,
                )
            : null,
      ),
      _NoveltiesAndHealthSlide(
        summary: summary,
        onDebtsTap: hasDebtOrReports
            ? () => navigateOriginOrHub(
                  context,
                  selectedStoreId: widget.selectedStoreId,
                  fallbackStores: widget.stores,
                  options: commissionOptions,
                  sheetTitle: 'Comisiones y pagos por sede',
                  routeSuffix: 'debts',
                  onPushRoute: (path) => context.push(path),
                  onOpenStoresTab: _openStoresTab,
                )
            : null,
        onPromotionsTap: () => navigateOriginOrHub(
          context,
          selectedStoreId: widget.selectedStoreId,
          fallbackStores: widget.stores,
          options: promoOptions,
          sheetTitle: 'Promociones en vitrina',
          routeSuffix: 'items',
          onPushRoute: (path) => context.push(path),
          onOpenStoresTab: _openStoresTab,
        ),
        onRankingTap: () => _navigateRanking(context),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 600) {
          final columns = width >= 900 ? 3 : 2;
          if (columns == 3) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: slides[0]),
                  const SizedBox(width: 12),
                  Expanded(child: slides[1]),
                  const SizedBox(width: 12),
                  Expanded(child: slides[2]),
                ],
              ),
            );
          }

          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: slides[0]),
                    const SizedBox(width: 12),
                    Expanded(child: slides[1]),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              slides[2],
            ],
          );
        }

        final bool isCompact = width < 360;
        final double baseHeight = showBs
            ? (isCompact ? 256.0 : 244.0)
            : (isCompact ? 226.0 : 214.0);
        final double carouselHeight = baseHeight * textScale;

        return Column(
          children: [
            SizedBox(
              height: carouselHeight,
              child: PageView.builder(
                controller: _pageController,
                padEnds: false,
                itemCount: slides.length,
                onPageChanged: (idx) {
                  setState(() => _currentPage = idx);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == slides.length - 1 ? 0 : 12,
                    ),
                    child: slides[index],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (index) {
                final isActive = _currentPage == index;
                final activeColor = index == 2
                    ? TuLojitaBrandColors.amber500
                    : TuLojitaBrandColors.indigo600;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _HeroPulseSlide extends StatelessWidget {
  final KpiMetrics kpis;
  final List<SalesChartPoint> salesChart;
  final VoidCallback onOrdersTap;

  const _HeroPulseSlide({
    required this.kpis,
    required this.salesChart,
    required this.onOrdersTap,
  });

  @override
  Widget build(BuildContext context) {
    final salesGrowth = kpis.growth.salesGrowthPercentage;
    final salesPositive = salesGrowth >= 0;
    final salesBadge = salesPositive
        ? '+${salesGrowth.toStringAsFixed(1)}%'
        : '${salesGrowth.toStringAsFixed(1)}%';

    final ordersGrowth = kpis.growth.ordersGrowthPercentage;
    final ordersPositive = ordersGrowth >= 0;
    final ordersBadge = ordersPositive
        ? '+${ordersGrowth.toStringAsFixed(0)}%'
        : '${ordersGrowth.toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'VENTAS TOTALES',
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
                    color: salesPositive
                        ? Colors.white.withValues(alpha: 0.18)
                        : TuLojitaBrandColors.dangerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    salesBadge,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: salesPositive
                          ? TuLojitaBrandColors.amber400
                          : TuLojitaBrandColors.danger,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DualPriceText(
                    amountInUsd: kpis.totalSales,
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
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 82,
                  height: 36,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                      values: salesChart.map((p) => p.sales).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.16),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onOrdersTap,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pedidos',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${kpis.totalOrders}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                if (kpis.pendingOrders > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: TuLojitaBrandColors.amber400,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${kpis.pendingOrders} pend.',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: TuLojitaBrandColors.inkPrimary,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    ordersBadge,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: TuLojitaBrandColors.amber400,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ticket Promedio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      DualPriceText(
                        amountInUsd: kpis.averageTicket,
                        usdStyle: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        bsStyle: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CashAndReceivablesSlide extends StatelessWidget {
  final KpiMetrics kpis;
  final VoidCallback? onInstallmentsTap;

  const _CashAndReceivablesSlide({
    required this.kpis,
    required this.onInstallmentsTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalFlow = kpis.totalCollected + kpis.accountsReceivable;
    final bool hasFlow = totalFlow > 0;
    final collectedRatio =
        hasFlow ? (kpis.totalCollected / totalFlow).clamp(0.0, 1.0) : 0.0;
    final collectedPct = hasFlow ? (collectedRatio * 100).round() : 0;

    return Container(
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
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'CAJA Y CARTERA',
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
                if (onInstallmentsTap != null)
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: onInstallmentsTap,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Text(
                          'Ver cuotas ›',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: TuLojitaBrandColors.indigo600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          _DotLegend(color: TuLojitaBrandColors.indigo600),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Recaudado en Bancos',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: TuLojitaBrandColors.inkSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      DualPriceText(
                        amountInUsd: kpis.totalCollected,
                        usdStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: TuLojitaBrandColors.inkPrimary,
                        ),
                        bsStyle: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: TuLojitaBrandColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: onInstallmentsTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    _DotLegend(
                                        color: TuLojitaBrandColors.amber400),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Por Cobrar (Cuotas)',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              TuLojitaBrandColors.inkSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                DualPriceText(
                                  amountInUsd: kpis.accountsReceivable,
                                  usdStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: TuLojitaBrandColors.amber700,
                                  ),
                                  bsStyle: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: TuLojitaBrandColors.inkSecondary,
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
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(78, 78),
                            painter: _DonutGaugePainter(
                              primaryRatio: collectedRatio,
                              hasFlow: hasFlow,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$collectedPct%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: TuLojitaBrandColors.inkPrimary,
                                ),
                              ),
                              Text(
                                hasFlow ? 'Cobrado' : 'Sin cobros',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  color: TuLojitaBrandColors.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.amber50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: TuLojitaBrandColors.amber100,
                        ),
                      ),
                      child: Text(
                        '${kpis.installmentRatio.installmentPercentage.toStringAsFixed(0)}% en cuotas',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: TuLojitaBrandColors.amber800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoveltiesAndHealthSlide extends StatelessWidget {
  final OperationalSummary summary;
  final VoidCallback? onDebtsTap;
  final VoidCallback onPromotionsTap;
  final VoidCallback onRankingTap;

  const _NoveltiesAndHealthSlide({
    required this.summary,
    required this.onDebtsTap,
    required this.onPromotionsTap,
    required this.onRankingTap,
  });

  @override
  Widget build(BuildContext context) {
    final divisionLabel = summary.topDivisionTitle ?? 'Sin liga activa';
    final hasDebt = summary.totalCommissionDebt > 0;
    final rankingStats =
        '${summary.highestPR} PR · ${summary.dailyMissionsCompletedToday} misiones hoy';
    final topStoreName = summary.topRankingStoreName?.trim() ?? '';
    final rankingSubtitle = topStoreName.isNotEmpty
        ? '$rankingStats · $topStoreName'
        : rankingStats;

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'NOVEDADES Y SALUD',
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
                if (summary.storesInDangerZoneCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: TuLojitaBrandColors.dangerBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${summary.storesInDangerZoneCount} en riesgo',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: TuLojitaBrandColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // 1. Comisiones
            _NoveltyRowTile(
              icon: HugeIcons.strokeRoundedInvoice01,
              iconColor: hasDebt
                  ? TuLojitaBrandColors.amber800
                  : TuLojitaBrandColors.indigo600,
              iconBg: hasDebt
                  ? TuLojitaBrandColors.amber100
                  : TuLojitaBrandColors.indigo50,
              title: 'Comisiones',
              body: DualPriceText(
                amountInUsd: summary.totalCommissionDebt,
                isInline: true,
                usdStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: hasDebt
                      ? TuLojitaBrandColors.amber800
                      : TuLojitaBrandColors.inkPrimary,
                ),
                bsStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
              badgeText: summary.pendingCommissionReportsCount > 0
                  ? '${summary.pendingCommissionReportsCount} rev.'
                  : null,
              onTap: onDebtsTap,
            ),
            const SizedBox(height: 6),

            // 2. Promociones en Vitrina
            _NoveltyRowTile(
              icon: HugeIcons.strokeRoundedMegaphone01,
              iconColor: TuLojitaBrandColors.indigo600,
              iconBg: TuLojitaBrandColors.indigo50,
              title: 'Vitrina',
              body: Text(
                '${summary.activePromotionsCount} activas · ${summary.pendingPromotionsCount} pend.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              onTap: onPromotionsTap,
            ),
            const SizedBox(height: 6),

            // 3. Liga y Racha de Ventas
            _NoveltyRowTile(
              icon: HugeIcons.strokeRoundedAward01,
              iconColor: TuLojitaBrandColors.amber700,
              iconBg: TuLojitaBrandColors.amber50,
              title: divisionLabel,
              body: Text(
                rankingSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              badgeText: summary.maxConsecutiveSalesDays > 0
                  ? '${summary.maxConsecutiveSalesDays}d racha'
                  : null,
              onTap: onRankingTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoveltyRowTile extends StatelessWidget {
  final dynamic icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget body;
  final String? badgeText;
  final VoidCallback? onTap;

  const _NoveltyRowTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TuLojitaBrandColors.canvas,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: HugeIcon(icon: icon, color: iconColor, size: 15),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                    body,
                  ],
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.amber100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: TuLojitaBrandColors.amber800,
                    ),
                  ),
                ),
              ] else if (onTap != null) ...[
                const SizedBox(width: 4),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: TuLojitaBrandColors.inkSecondary,
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DotLegend extends StatelessWidget {
  final Color color;
  const _DotLegend({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;

  const _SparklinePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.fold<double>(0.0, math.max);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double topPad = 4;
    final double bottomPad = 4;
    final double usableH = math.max(1.0, size.height - topPad - bottomPad);

    if (values.length == 1 || maxVal <= 0) {
      final y = maxVal <= 0 ? size.height - bottomPad : size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      canvas.drawCircle(
        Offset(size.width, y),
        3.2,
        Paint()..color = TuLojitaBrandColors.amber400,
      );
      return;
    }

    final points = <Offset>[];
    final stepX = size.width / (values.length - 1);
    for (int i = 0; i < values.length; i++) {
      final norm = (values[i] / maxVal).clamp(0.0, 1.0);
      final x = i * stepX;
      final y = topPad + usableH * (1 - norm);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(ctrlX, p0.dy, ctrlX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Highlight last point in Amber 400
    canvas.drawCircle(
      points.last,
      3.5,
      Paint()..color = TuLojitaBrandColors.amber400,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _DonutGaugePainter extends CustomPainter {
  final double primaryRatio;
  final bool hasFlow;

  const _DonutGaugePainter({
    required this.primaryRatio,
    this.hasFlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final rect = Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);

    final trackPaint = Paint()
      ..color = hasFlow
          ? TuLojitaBrandColors.amber400
          : TuLojitaBrandColors.borderMuted
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (!hasFlow) return;

    final primaryPaint = Paint()
      ..color = TuLojitaBrandColors.indigo600
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweep = (primaryRatio.clamp(0.0, 1.0)) * math.pi * 2;
    if (sweep > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, primaryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutGaugePainter oldDelegate) {
    return oldDelegate.primaryRatio != primaryRatio ||
        oldDelegate.hasFlow != hasFlow;
  }
}

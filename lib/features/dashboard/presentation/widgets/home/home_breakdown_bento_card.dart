import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_analytics.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_image_resolver.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_share_progress_tile.dart';

enum _BreakdownTab { topProducts, topDesired, paymentMethods, stores }

/// Unified segmented Bento module consolidating top sold products, desired
/// items, payment methods, and branch performance into a single card.
class HomeBreakdownBentoCard extends ConsumerStatefulWidget {
  final DashboardAnalytics analytics;
  final List<Store> stores;
  final String selectedStoreId;

  const HomeBreakdownBentoCard({
    super.key,
    required this.analytics,
    required this.stores,
    required this.selectedStoreId,
  });

  @override
  ConsumerState<HomeBreakdownBentoCard> createState() =>
      _HomeBreakdownBentoCardState();
}

class _HomeBreakdownBentoCardState
    extends ConsumerState<HomeBreakdownBentoCard> {
  _BreakdownTab _activeTab = _BreakdownTab.topProducts;
  bool _isNavigatingItem = false;

  bool get _showStoresTab =>
      widget.selectedStoreId == 'all' &&
      widget.analytics.storesPerformance.isNotEmpty;

  @override
  void didUpdateWidget(covariant HomeBreakdownBentoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeTab == _BreakdownTab.stores && !_showStoresTab) {
      _activeTab = _BreakdownTab.topProducts;
    }
  }

  Future<void> _openItemDrillDown(
    String itemId,
    String itemTitle, {
    String? storeId,
  }) async {
    if (_isNavigatingItem) return;
    final String? resolvedStoreId;
    if (storeId != null && storeId.isNotEmpty) {
      resolvedStoreId = storeId;
    } else if (widget.selectedStoreId != 'all' &&
        widget.selectedStoreId.isNotEmpty) {
      resolvedStoreId = widget.selectedStoreId;
    } else if (widget.stores.length == 1) {
      resolvedStoreId = widget.stores.first.id;
    } else {
      ref.read(dashboardIndexProvider.notifier).state = 1;
      return;
    }

    setState(() => _isNavigatingItem = true);
    try {
      final fullItem = await ref.read(itemRepositoryProvider).getItemById(itemId);
      if (!mounted) return;
      context.push(
        '/dashboard/stores/$resolvedStoreId/items/detail',
        extra: fullItem,
      );
    } catch (_) {
      if (!mounted) return;
      context.push('/dashboard/stores/$resolvedStoreId/items');
    } finally {
      if (mounted) {
        setState(() => _isNavigatingItem = false);
      }
    }
  }

  dynamic _getMethodIcon(String method) {
    if (method == 'PAGO_MOVIL') return HugeIcons.strokeRoundedSmartPhone01;
    if (method == 'TRANSFER') return HugeIcons.strokeRoundedBank;
    if (method == 'BINANCE') return HugeIcons.strokeRoundedBitcoin01;
    if (method == 'ZELLE') return HugeIcons.strokeRoundedMoney01;
    return HugeIcons.strokeRoundedCreditCard;
  }

  @override
  Widget build(BuildContext context) {
    final currentTab =
        (_activeTab == _BreakdownTab.stores && !_showStoresTab)
            ? _BreakdownTab.topProducts
            : _activeTab;

    final tabs = <({_BreakdownTab tab, String label})>[
      (tab: _BreakdownTab.topProducts, label: 'Vendidos'),
      (tab: _BreakdownTab.topDesired, label: 'Deseados'),
      (tab: _BreakdownTab.paymentMethods, label: 'Métodos'),
      if (_showStoresTab) (tab: _BreakdownTab.stores, label: 'Sedes'),
    ];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Desglose Comercial',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                ),
              ),
              if (_isNavigatingItem)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TuLojitaBrandColors.indigo600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Segmented control strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: tabs.map((item) {
                final isSelected = currentTab == item.tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Material(
                    color: isSelected
                        ? TuLojitaBrandColors.indigo600
                        : TuLojitaBrandColors.canvas,
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      onTap: () => setState(() => _activeTab = item.tab),
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: isSelected
                                ? TuLojitaBrandColors.indigo600
                                : TuLojitaBrandColors.borderMuted,
                          ),
                        ),
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : TuLojitaBrandColors.inkSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(currentTab),
              child: _buildTabBody(currentTab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody(_BreakdownTab tab) {
    switch (tab) {
      case _BreakdownTab.topProducts:
        final items = widget.analytics.topProducts.take(5).toList();
        if (items.isEmpty) {
          return _buildEmptyState('Aún no hay productos vendidos en este período');
        }
        return Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final prod = entry.value;
            final isLast = index == items.length - 1;
            final imageUrl = resolveDashboardImageUrl(prod.mainImage);

            return InkWell(
              onTap: () => _openItemDrillDown(
                prod.itemId,
                prod.title,
                storeId: prod.storeId,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.only(
                  bottom: isLast ? 0 : 11,
                  top: index == 0 ? 0 : 11,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: TuLojitaBrandColors.borderSubtle,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    _RankBadge(index: index),
                    const SizedBox(width: 10),
                    _CleanProductThumb(imageUrl: imageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: TuLojitaBrandColors.inkPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Builder(
                            builder: (_) {
                              final showOrigin = widget.selectedStoreId == 'all' &&
                                  widget.stores.length > 1 &&
                                  prod.storeName != null &&
                                  prod.storeName!.trim().isNotEmpty;
                              final subtitleText = showOrigin
                                  ? '${prod.unitsSold} unid. · ${prod.storeName!.trim()}'
                                  : '${prod.unitsSold} unid. vendidas';
                              return Text(
                                subtitleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: TuLojitaBrandColors.inkSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: DualPriceText(
                        amountInUsd: prod.totalRevenue,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        usdStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: TuLojitaBrandColors.indigo600,
                        ),
                        bsStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: TuLojitaBrandColors.inkSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );

      case _BreakdownTab.topDesired:
        final items = widget.analytics.topDesiredProducts.take(5).toList();
        if (items.isEmpty) {
          return _buildEmptyState('Sin artículos en favoritos aún');
        }
        return Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final prod = entry.value;
            final isLast = index == items.length - 1;
            final imageUrl = resolveDashboardImageUrl(prod.mainImage);

            return InkWell(
              onTap: () => _openItemDrillDown(
                prod.itemId,
                prod.title,
                storeId: prod.storeId,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.only(
                  bottom: isLast ? 0 : 11,
                  top: index == 0 ? 0 : 11,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: TuLojitaBrandColors.borderSubtle,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    _RankBadge(index: index),
                    const SizedBox(width: 10),
                    _CleanProductThumb(imageUrl: imageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: TuLojitaBrandColors.inkPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              DualPriceText(
                                amountInUsd: prod.price,
                                usdStyle: const TextStyle(
                                  fontSize: 11.5,
                                  color: TuLojitaBrandColors.indigo600,
                                  fontWeight: FontWeight.w700,
                                ),
                                bsStyle: const TextStyle(
                                  fontSize: 10,
                                  color: TuLojitaBrandColors.inkSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (prod.isOutOfStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TuLojitaBrandColors.dangerBg,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    'Agotado',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: TuLojitaBrandColors.danger,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (widget.selectedStoreId == 'all' &&
                              widget.stores.length > 1 &&
                              prod.storeName != null &&
                              prod.storeName!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              prod.storeName!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: TuLojitaBrandColors.inkSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.amber50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: TuLojitaBrandColors.amber100,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 12.5,
                            color: TuLojitaBrandColors.amber700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${prod.favoritesCount}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: TuLojitaBrandColors.amber800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );

      case _BreakdownTab.paymentMethods:
        final methods = widget.analytics.paymentMethods.take(5).toList();
        if (methods.isEmpty) {
          return _buildEmptyState('Sin cobros registrados en este período');
        }
        return Column(
          children: methods.asMap().entries.map((entry) {
            final isLast = entry.key == methods.length - 1;
            final pm = entry.value;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: HomeShareProgressTile(
                icon: _getMethodIcon(pm.method),
                title: pm.label,
                amountInUsd: pm.totalAmount,
                percentage: pm.percentage,
                summaryLabel:
                    '${pm.percentage.toStringAsFixed(1)}% (${pm.transactionCount} pagos)',
              ),
            );
          }).toList(),
        );

      case _BreakdownTab.stores:
        final storesPerf = widget.analytics.storesPerformance.take(5).toList();
        if (storesPerf.isEmpty) {
          return _buildEmptyState('Sin ventas por sucursal en este período');
        }
        final alertsByStoreId = {
          for (final a in widget.analytics.operationalSummary.storeAlerts)
            a.storeId: a,
        };
        return Column(
          children: storesPerf.asMap().entries.map((entry) {
            final isLast = entry.key == storesPerf.length - 1;
            final item = entry.value;
            final pendingOrdersCount =
                alertsByStoreId[item.storeId]?.pendingOrders ?? 0;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: InkWell(
                onTap: () => context.push('/dashboard/stores/${item.storeId}'),
                borderRadius: BorderRadius.circular(10),
                child: HomeShareProgressTile(
                  icon: HugeIcons.strokeRoundedStore01,
                  title: item.storeName,
                  amountInUsd: item.totalSales,
                  percentage: item.percentageOfTotal,
                  summaryLabel:
                      '${item.percentageOfTotal.toStringAsFixed(1)}% (${item.ordersCount} ped)',
                  badgeText: pendingOrdersCount > 0
                      ? '$pendingOrdersCount pend.'
                      : null,
                ),
              ),
            );
          }).toList(),
        );
    }
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: TuLojitaBrandColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int index;

  const _RankBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    final isTop = index == 0;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop
            ? TuLojitaBrandColors.amber100
            : TuLojitaBrandColors.canvas,
        shape: BoxShape.circle,
      ),
      child: Text(
        '#${index + 1}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isTop
              ? TuLojitaBrandColors.amber700
              : TuLojitaBrandColors.inkSecondary,
        ),
      ),
    );
  }
}

class _CleanProductThumb extends StatelessWidget {
  final String imageUrl;

  const _CleanProductThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 42,
        height: 42,
        color: TuLojitaBrandColors.canvas,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedPackage,
                    color: TuLojitaBrandColors.inkSecondary,
                    size: 18,
                  ),
                ),
              )
            : const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPackage,
                  color: TuLojitaBrandColors.inkSecondary,
                  size: 18,
                ),
              ),
      ),
    );
  }
}

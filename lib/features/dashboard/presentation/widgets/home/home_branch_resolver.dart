import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_analytics.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_image_resolver.dart';

/// Origin store candidate carrying specific operational context for Home drill-down.
class OriginStoreOption {
  final Store store;
  final String metricBadge;
  final String? subtitle;
  final bool useAmberBadge;

  const OriginStoreOption({
    required this.store,
    required this.metricBadge,
    this.subtitle,
    this.useAmberBadge = false,
  });
}

/// Concise branch label for inline pills and alerts.
String storeShortLabel(Store store) {
  final branch = store.branchName?.trim() ?? '';
  if (branch.isNotEmpty) return branch;
  return store.name;
}

/// Builds origin options by pairing [summary.storeAlerts] with authorized [stores].
List<OriginStoreOption> buildPendingOrdersOriginOptions({
  required OperationalSummary summary,
  required List<Store> stores,
}) {
  final storeMap = {for (final s in stores) s.id: s};
  final options = <OriginStoreOption>[];
  for (final alert in summary.storeAlerts) {
    if (alert.pendingOrders <= 0) continue;
    final store = storeMap[alert.storeId];
    if (store == null) continue;
    options.add(
      OriginStoreOption(
        store: store,
        metricBadge: alert.pendingOrders == 1
            ? '1 pedido'
            : '${alert.pendingOrders} pedidos',
        useAmberBadge: true,
      ),
    );
  }
  return options;
}

List<OriginStoreOption> buildReceivablesOriginOptions({
  required OperationalSummary summary,
  required List<Store> stores,
  required ExchangeRateConfig? exchangeConfig,
}) {
  final storeMap = {for (final s in stores) s.id: s};
  final options = <OriginStoreOption>[];
  for (final alert in summary.storeAlerts) {
    if (alert.accountsReceivable <= 0) continue;
    final store = storeMap[alert.storeId];
    if (store == null) continue;
    options.add(
      OriginStoreOption(
        store: store,
        metricBadge: PriceFormatter.formatDualInline(
          alert.accountsReceivable,
          exchangeConfig,
        ),
        useAmberBadge: true,
      ),
    );
  }
  return options;
}

List<OriginStoreOption> buildCommissionOriginOptions({
  required OperationalSummary summary,
  required List<Store> stores,
  required ExchangeRateConfig? exchangeConfig,
}) {
  final storeMap = {for (final s in stores) s.id: s};
  final options = <OriginStoreOption>[];
  for (final alert in summary.storeAlerts) {
    final hasDebt = alert.commissionDebt > 0;
    final hasReports = alert.pendingCommissionReportsCount > 0;
    if (!hasDebt && !hasReports) continue;
    final store = storeMap[alert.storeId];
    if (store == null) continue;
    final badge = hasDebt
        ? PriceFormatter.formatDualInline(alert.commissionDebt, exchangeConfig)
        : '${alert.pendingCommissionReportsCount} en rev.';
    options.add(
      OriginStoreOption(
        store: store,
        metricBadge: badge,
        subtitle: hasDebt && hasReports
            ? '${alert.pendingCommissionReportsCount} pago(s) en revisión'
            : null,
        useAmberBadge: true,
      ),
    );
  }
  return options;
}

List<OriginStoreOption> buildPromotionsOriginOptions({
  required OperationalSummary summary,
  required List<Store> stores,
}) {
  final storeMap = {for (final s in stores) s.id: s};
  final options = <OriginStoreOption>[];
  for (final alert in summary.storeAlerts) {
    if (alert.activePromotionsCount <= 0 && alert.pendingPromotionsCount <= 0) {
      continue;
    }
    final store = storeMap[alert.storeId];
    if (store == null) continue;
    final String badge;
    if (alert.activePromotionsCount > 0 && alert.pendingPromotionsCount > 0) {
      badge =
          '${alert.activePromotionsCount} act. · ${alert.pendingPromotionsCount} pend.';
    } else if (alert.activePromotionsCount > 0) {
      badge = alert.activePromotionsCount == 1
          ? '1 activa'
          : '${alert.activePromotionsCount} activas';
    } else {
      badge = alert.pendingPromotionsCount == 1
          ? '1 pendiente'
          : '${alert.pendingPromotionsCount} pend.';
    }
    options.add(
      OriginStoreOption(
        store: store,
        metricBadge: badge,
        useAmberBadge: alert.pendingPromotionsCount > 0,
      ),
    );
  }
  return options;
}

List<OriginStoreOption> buildScheduledDeletionOriginOptions(List<Store> stores) {
  return stores
      .where((s) => s.isScheduledForDeletion)
      .map(
        (s) => OriginStoreOption(
          store: s,
          metricBadge: 'Eliminación en ${s.remainingGraceDays}d',
          useAmberBadge: true,
        ),
      )
      .toList();
}

List<OriginStoreOption> buildSuspendedOriginOptions({
  required List<Store> stores,
  required ExchangeRateConfig? exchangeConfig,
  required bool canAccessFinancials,
}) {
  return stores
      .where(
        (s) =>
            s.status.toUpperCase() == 'SUSPENDED' && !s.isScheduledForDeletion,
      )
      .map((s) {
        final String badge;
        final String subtitle;
        if (canAccessFinancials && s.pendingCommissionReportsCount > 0) {
          badge = 'Pago en rev.';
          subtitle = 'Comprobante enviado en revisión';
        } else if (canAccessFinancials && s.commissionDebt > 0) {
          badge =
              'Deuda ${PriceFormatter.formatDualInline(s.commissionDebt, exchangeConfig)}';
          subtitle = 'Toca para pagar y reactivar';
        } else {
          badge = 'Suspendida';
          subtitle = 'Toca para revisar el estado de la sede';
        }
        return OriginStoreOption(
          store: s,
          metricBadge: badge,
          subtitle: subtitle,
          useAmberBadge: true,
        );
      })
      .toList();
}

/// Resolves an originating store ID strictly from contextual [options].
///
/// - If [options] is empty, returns `null` (never opens a blind all-stores sheet).
/// - If [selectedStoreId] is a concrete branch matching [options], returns it directly.
/// - If exactly 1 option matches, returns `options.first.store.id` directly.
/// - If 2+ affected branches exist, opens an origin-filtered bottom sheet displaying
///   exclusively those [options] alongside their specific [metricBadge].
Future<String?> resolveOriginStoreId(
  BuildContext context, {
  required String selectedStoreId,
  required List<OriginStoreOption> options,
  String title = 'Selecciona la sucursal de origen',
  String? subtitle,
}) async {
  if (options.isEmpty) {
    return null;
  }

  if (selectedStoreId != 'all' && selectedStoreId.isNotEmpty) {
    final matching = options.where((o) => o.store.id == selectedStoreId);
    if (matching.isNotEmpty) {
      return matching.first.store.id;
    }
  }

  if (options.length == 1) {
    return options.first.store.id;
  }

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: TuLojitaBrandColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: TuLojitaBrandColors.inkPrimary,
                          ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: TuLojitaBrandColors.inkSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, index) {
                    final option = options[index];
                    final store = option.store;
                    final logoUrl = resolveDashboardImageUrl(store.logo);
                    final subtitleParts = <String>[
                      if (store.shouldShowBranch) store.branchLabel,
                      if (option.subtitle != null &&
                          option.subtitle!.trim().isNotEmpty)
                        option.subtitle!.trim(),
                    ];
                    final branchSubtitle = subtitleParts.isEmpty
                        ? null
                        : subtitleParts.join(' · ');
                    final badgeBg = option.useAmberBadge
                        ? TuLojitaBrandColors.amber100
                        : TuLojitaBrandColors.indigo50;
                    final badgeFg = option.useAmberBadge
                        ? TuLojitaBrandColors.amber800
                        : TuLojitaBrandColors.indigo600;

                    return Material(
                      color: TuLojitaBrandColors.canvas,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(ctx, store.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  color: TuLojitaBrandColors.indigo50,
                                  child: logoUrl.isNotEmpty
                                      ? Image.network(
                                          logoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const Center(
                                            child: HugeIcon(
                                              icon:
                                                  HugeIcons.strokeRoundedStore01,
                                              color:
                                                  TuLojitaBrandColors.indigo600,
                                              size: 18,
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: HugeIcon(
                                            icon:
                                                HugeIcons.strokeRoundedStore01,
                                            color:
                                                TuLojitaBrandColors.indigo600,
                                            size: 18,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: TuLojitaBrandColors.inkPrimary,
                                      ),
                                    ),
                                    if (branchSubtitle != null)
                                      Text(
                                        branchSubtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color:
                                              TuLojitaBrandColors.inkSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    option.metricBadge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: badgeFg,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowRight01,
                                color: TuLojitaBrandColors.indigo600,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Routes via contextual origin options, unambiguous single/selected branch,
/// or falls back to opening the `Tiendas` tab when consolidated and ambiguous.
Future<void> navigateOriginOrHub(
  BuildContext context, {
  required String selectedStoreId,
  required List<Store> fallbackStores,
  required List<OriginStoreOption> options,
  required String sheetTitle,
  String? sheetSubtitle,
  required String routeSuffix,
  required void Function(String targetPath) onPushRoute,
  required VoidCallback onOpenStoresTab,
}) async {
  final tail = routeSuffix.isEmpty ? '' : '/$routeSuffix';

  if (options.isNotEmpty) {
    final storeId = await resolveOriginStoreId(
      context,
      selectedStoreId: selectedStoreId,
      options: options,
      title: sheetTitle,
      subtitle: sheetSubtitle,
    );
    if (storeId != null && context.mounted) {
      onPushRoute('/dashboard/stores/$storeId$tail');
    }
    return;
  }

  if (selectedStoreId != 'all' && selectedStoreId.isNotEmpty) {
    onPushRoute('/dashboard/stores/$selectedStoreId$tail');
    return;
  }

  if (fallbackStores.length == 1) {
    onPushRoute('/dashboard/stores/${fallbackStores.first.id}$tail');
    return;
  }

  onOpenStoresTab();
}

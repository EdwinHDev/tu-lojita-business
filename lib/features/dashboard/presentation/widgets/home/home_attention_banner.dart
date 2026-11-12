import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_analytics.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_branch_resolver.dart';

/// Conditional Amber 400 strip surfacing urgent operational alerts above the KPIs.
/// Collapses to `SizedBox.shrink()` when all permitted alert pills are absent.
class HomeAttentionBanner extends ConsumerWidget {
  final User? user;
  final int pendingOrders;
  final int unreadDisputesCount;
  final OperationalSummary summary;
  final List<Store> stores;
  final String selectedStoreId;
  final bool canViewFinancials;
  final EdgeInsetsGeometry margin;

  const HomeAttentionBanner({
    super.key,
    this.user,
    required this.pendingOrders,
    required this.unreadDisputesCount,
    required this.summary,
    required this.stores,
    required this.selectedStoreId,
    this.canViewFinancials = true,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeConfig = ref.watch(exchangeRateProvider).asData?.value;
    final bool isCollab = user != null && user!.isCollaborator;
    final bool canAccessOrders =
        !isCollab || user!.canViewOrders || user!.canProcessOrders;
    final bool canAccessDisputes = !isCollab || user!.canViewDisputes;
    final bool canAccessBranchAdmin = !isCollab ||
        user!.canManageBranches ||
        user!.hasPermission('branches:view');
    final bool canAccessFinancials =
        canViewFinancials && (!isCollab || user!.canViewFinancialMetrics);

    final authorizedStores = (isCollab && !user!.hasFullBranchAccess)
        ? stores.where((s) => user!.canAccessBranch(s.id)).toList()
        : stores;

    final scheduledStores = canAccessBranchAdmin
        ? authorizedStores.where((s) => s.isScheduledForDeletion).toList()
        : const <Store>[];
    final suspendedStores = authorizedStores
        .where(
          (s) =>
              s.status.toUpperCase() == 'SUSPENDED' && !s.isScheduledForDeletion,
        )
        .toList();
    final scheduledCount = !canAccessBranchAdmin
        ? 0
        : (isCollab && !user!.hasFullBranchAccess)
            ? scheduledStores.length
            : math.max(
                summary.storesScheduledForDeletionCount,
                scheduledStores.length,
              );

    final hasDebtAlert =
        canAccessFinancials && summary.totalCommissionDebt > 0;
    final hasPendingReportsAlert =
        canAccessFinancials && summary.pendingCommissionReportsCount > 0;

    void openStoresTab() => ref.read(dashboardIndexProvider.notifier).state = 1;

    final pills = <Widget>[];

    // 0. Prioridad crítica: sedes suspendidas
    if (suspendedStores.isNotEmpty) {
      final suspendedOptions = buildSuspendedOriginOptions(
        stores: authorizedStores,
        exchangeConfig: exchangeConfig,
        canAccessFinancials: canAccessFinancials,
      );
      final String suspendedLabel;
      if (suspendedOptions.length == 1) {
        suspendedLabel =
            'Suspendida · ${storeShortLabel(suspendedOptions.first.store)}';
      } else {
        suspendedLabel = '${suspendedOptions.length} sedes suspendidas';
      }

      pills.add(
        _AttentionPill(
          icon: HugeIcons.strokeRoundedAlertCircle,
          label: suspendedLabel,
          isCritical: true,
          onTap: () async {
            final storeId = await resolveOriginStoreId(
              context,
              selectedStoreId: selectedStoreId,
              options: suspendedOptions,
              title: 'Sedes suspendidas',
              subtitle: 'Selecciona la sede para regularizar o revisar su estado',
            );
            if (!context.mounted) return;
            if (storeId == null) {
              openStoresTab();
              return;
            }
            final targetStore = authorizedStores
                    .cast<Store>()
                    .where((s) => s.id == storeId)
                    .firstOrNull ??
                suspendedStores.first;
            final routeToDebts = canAccessFinancials &&
                (targetStore.commissionDebt > 0 ||
                    targetStore.pendingCommissionReportsCount > 0);
            context.push(
              routeToDebts
                  ? '/dashboard/stores/$storeId/debts'
                  : '/dashboard/stores/$storeId',
            );
          },
        ),
      );
    }

    // 1. Pedidos pendientes con origen específico
    if (canAccessOrders && pendingOrders > 0) {
      final pendingOptions = buildPendingOrdersOriginOptions(
        summary: summary,
        stores: authorizedStores,
      );
      final String ordersLabel;
      if (pendingOptions.length == 1) {
        final name = storeShortLabel(pendingOptions.first.store);
        ordersLabel = pendingOrders == 1
            ? '1 pedido · $name'
            : '$pendingOrders pedidos · $name';
      } else if (pendingOptions.length >= 2) {
        ordersLabel = '$pendingOrders pedidos (${pendingOptions.length} sedes)';
      } else {
        ordersLabel = pendingOrders == 1
            ? '1 pedido pendiente'
            : '$pendingOrders pedidos pendientes';
      }

      pills.add(
        _AttentionPill(
          icon: HugeIcons.strokeRoundedPackage,
          label: ordersLabel,
          onTap: () => navigateOriginOrHub(
            context,
            selectedStoreId: selectedStoreId,
            fallbackStores: authorizedStores,
            options: pendingOptions,
            sheetTitle: 'Pedidos pendientes por sede',
            routeSuffix: 'orders',
            onPushRoute: (path) => context.push(path),
            onOpenStoresTab: openStoresTab,
          ),
        ),
      );
    }

    // 2. Reclamos sin leer: multi-sede directo a Alertas (/dashboard/notifications)
    if (canAccessDisputes && unreadDisputesCount > 0) {
      final hasConcreteSingleStore =
          (selectedStoreId != 'all' && selectedStoreId.isNotEmpty) ||
              authorizedStores.length == 1;
      final singleStoreId =
          (selectedStoreId != 'all' && selectedStoreId.isNotEmpty)
              ? selectedStoreId
              : (authorizedStores.length == 1
                  ? authorizedStores.first.id
                  : null);

      pills.add(
        _AttentionPill(
          icon: HugeIcons.strokeRoundedAlertCircle,
          label: unreadDisputesCount == 1
              ? '1 reclamo sin leer'
              : '$unreadDisputesCount reclamos sin leer',
          isCritical: true,
          onTap: () {
            if (hasConcreteSingleStore &&
                singleStoreId != null &&
                canAccessOrders) {
              context.push('/dashboard/stores/$singleStoreId/orders');
            } else {
              context.push('/dashboard/notifications');
            }
          },
        ),
      );
    }

    // 3. Comisiones / Pagos en revisión con origen específico
    if (hasDebtAlert || hasPendingReportsAlert) {
      final commissionOptions = buildCommissionOriginOptions(
        summary: summary,
        stores: authorizedStores,
        exchangeConfig: exchangeConfig,
      );

      if (hasDebtAlert) {
        final debtFormatted = PriceFormatter.formatDualInline(
          summary.totalCommissionDebt,
          exchangeConfig,
        );
        final String debtLabel;
        if (commissionOptions.length == 1) {
          debtLabel =
              'Comisión: $debtFormatted · ${storeShortLabel(commissionOptions.first.store)}';
        } else if (commissionOptions.length >= 2) {
          debtLabel =
              'Comisión: $debtFormatted (${commissionOptions.length} sedes)';
        } else {
          debtLabel = 'Comisión: $debtFormatted';
        }

        pills.add(
          _AttentionPill(
            icon: HugeIcons.strokeRoundedInvoice01,
            label: debtLabel,
            onTap: () => navigateOriginOrHub(
              context,
              selectedStoreId: selectedStoreId,
              fallbackStores: authorizedStores,
              options: commissionOptions,
              sheetTitle: 'Liquidar comisiones por sede',
              routeSuffix: 'debts',
              onPushRoute: (path) => context.push(path),
              onOpenStoresTab: openStoresTab,
            ),
          ),
        );
      } else {
        final count = summary.pendingCommissionReportsCount;
        final String reportsLabel;
        if (commissionOptions.length == 1) {
          final name = storeShortLabel(commissionOptions.first.store);
          reportsLabel = count == 1
              ? '1 pago en rev. · $name'
              : '$count pagos en rev. · $name';
        } else if (commissionOptions.length >= 2) {
          reportsLabel =
              '$count pagos en revisión (${commissionOptions.length} sedes)';
        } else {
          reportsLabel =
              count == 1 ? '1 pago en revisión' : '$count pagos en revisión';
        }

        pills.add(
          _AttentionPill(
            icon: HugeIcons.strokeRoundedInvoice01,
            label: reportsLabel,
            onTap: () => navigateOriginOrHub(
              context,
              selectedStoreId: selectedStoreId,
              fallbackStores: authorizedStores,
              options: commissionOptions,
              sheetTitle: 'Reportes de comisión por sede',
              routeSuffix: 'debts',
              onPushRoute: (path) => context.push(path),
              onOpenStoresTab: openStoresTab,
            ),
          ),
        );
      }
    }

    // 4. Sedes por eliminar con origen específico
    if (canAccessBranchAdmin && scheduledCount > 0) {
      final deletionOptions =
          buildScheduledDeletionOriginOptions(scheduledStores);
      final String deletionLabel;
      if (deletionOptions.length == 1) {
        deletionLabel =
            'Baja programada · ${storeShortLabel(deletionOptions.first.store)}';
      } else if (deletionOptions.length >= 2) {
        deletionLabel = '${deletionOptions.length} sedes por eliminar';
      } else {
        deletionLabel = scheduledCount == 1
            ? '1 sede por eliminar'
            : '$scheduledCount sedes por eliminar';
      }

      pills.add(
        _AttentionPill(
          icon: HugeIcons.strokeRoundedDelete02,
          label: deletionLabel,
          isCritical: true,
          onTap: () => navigateOriginOrHub(
            context,
            selectedStoreId: selectedStoreId,
            fallbackStores: authorizedStores,
            options: deletionOptions,
            sheetTitle: 'Revisar baja programada',
            routeSuffix: '',
            onPushRoute: (path) => context.push(path),
            onOpenStoresTab: openStoresTab,
          ),
        ),
      );
    }

    if (pills.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: margin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TuLojitaBrandColors.amber50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: TuLojitaBrandColors.amber400,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification01,
                  color: TuLojitaBrandColors.amber800,
                  size: 15,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Atención operativa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: TuLojitaBrandColors.amber800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pills,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionPill extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool isCritical;
  final VoidCallback onTap;

  const _AttentionPill({
    required this.icon,
    required this.label,
    this.isCritical = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCritical
        ? TuLojitaBrandColors.dangerBg
        : TuLojitaBrandColors.amber100;
    final fgColor = isCritical
        ? TuLojitaBrandColors.danger
        : TuLojitaBrandColors.amber800;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, color: fgColor, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: fgColor,
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

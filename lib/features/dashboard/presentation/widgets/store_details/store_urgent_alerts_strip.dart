import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_dashboard.dart';

/// Actionable urgent branch alerts displayed directly below store identity.
class StoreUrgentAlertsStrip extends StatelessWidget {
  final Store store;
  final StoreStats? stats;
  final User? user;
  final int unreadDisputesCount;
  final VoidCallback onOpenHealthSheet;
  final bool suppressCommissionPillsWhenSuspended;

  const StoreUrgentAlertsStrip({
    super.key,
    required this.store,
    this.stats,
    required this.user,
    this.unreadDisputesCount = 0,
    required this.onOpenHealthSheet,
    this.suppressCommissionPillsWhenSuspended = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCollab = user?.isCollaborator ?? false;
    final canViewFinancials =
        !isCollab || (user != null && user!.canViewFinancialMetrics);
    final canViewOrders = !isCollab ||
        (user != null && (user!.canViewOrders || user!.canProcessOrders));
    final canViewDisputes =
        !isCollab || (user != null && user!.canViewDisputes);
    final canViewStrikes =
        !isCollab || (user != null && (user!.canManageBranches || canViewOrders));
    final canViewMediations = !isCollab;

    final openDisputes = canViewDisputes
        ? (unreadDisputesCount > (stats?.openDisputesCount ?? 0)
            ? unreadDisputesCount
            : (stats?.openDisputesCount ?? 0))
        : 0;
    final pendingOrders = canViewOrders
        ? (stats?.pendingOrdersCount ?? store.pendingOrdersCount)
        : 0;
    final activeStrikes = canViewStrikes ? (stats?.activeStrikesCount ?? 0) : 0;
    final pendingMediations =
        canViewMediations ? (stats?.pendingMediationRequestsCount ?? 0) : 0;
    final commissionDebt = canViewFinancials
        ? (stats?.commissionDebt ?? store.commissionDebt)
        : 0.0;
    final pendingReports = canViewFinancials
        ? (stats?.pendingCommissionReportsCount ??
            store.pendingCommissionReportsCount)
        : 0;

    final isSuspended = store.status.toUpperCase() == 'SUSPENDED';
    final showCommissionPills =
        !(isSuspended && suppressCommissionPillsWhenSuspended);

    final pills = <_UrgentAlertPill>[
      if (openDisputes > 0)
        _UrgentAlertPill(
          icon: HugeIcons.strokeRoundedAlertCircle,
          label:
              '$openDisputes ${openDisputes == 1 ? 'reclamo abierto' : 'reclamos abiertos'}',
          tone: _AlertTone.critical,
          onTap: () => context.push('/dashboard/stores/${store.id}/orders'),
        ),
      if (pendingOrders > 0)
        _UrgentAlertPill(
          icon: HugeIcons.strokeRoundedShoppingBag01,
          label:
              '$pendingOrders ${pendingOrders == 1 ? 'orden pendiente' : 'órdenes pendientes'}',
          tone: _AlertTone.indigo,
          onTap: () => context.push('/dashboard/stores/${store.id}/orders'),
        ),
      if (activeStrikes > 0)
        _UrgentAlertPill(
          icon: HugeIcons.strokeRoundedShield01,
          label:
              '$activeStrikes ${activeStrikes == 1 ? 'strike activo' : 'strikes activos'}',
          tone: _AlertTone.critical,
          onTap: onOpenHealthSheet,
        ),
      if (pendingMediations > 0)
        _UrgentAlertPill(
          icon: HugeIcons.strokeRoundedMessage01,
          label:
              '$pendingMediations ${pendingMediations == 1 ? 'mediación pendiente' : 'mediaciones pendientes'}',
          tone: _AlertTone.amber,
          onTap: () =>
              context.push('/dashboard/stores/${store.id}/mediation-requests'),
        ),
      if (showCommissionPills && pendingReports > 0)
        _UrgentAlertPill(
          icon: HugeIcons.strokeRoundedClock01,
          label:
              '$pendingReports pago${pendingReports == 1 ? '' : 's'} en revisión',
          tone: _AlertTone.amber,
          onTap: () => context.push('/dashboard/stores/${store.id}/debts'),
        ),
      if (showCommissionPills && commissionDebt > 0)
        _UrgentAlertPill(
          icon: HugeIcons.strokeRoundedInvoice01,
          label: 'Deuda: ${PriceFormatter.formatNumeric(commissionDebt)}',
          tone: _AlertTone.critical,
          onTap: () => context.push('/dashboard/stores/${store.id}/debts'),
        ),
    ];

    if (pills.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TuLojitaBrandColors.borderSubtle, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                color: TuLojitaBrandColors.amber700,
                size: 16,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Atención Prioritaria',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pills.map((pill) => _AlertPillWidget(data: pill)).toList(),
          ),
        ],
      ),
    );
  }
}

enum _AlertTone { critical, amber, indigo }

class _UrgentAlertPill {
  final dynamic icon;
  final String label;
  final _AlertTone tone;
  final VoidCallback onTap;

  const _UrgentAlertPill({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });
}

class _AlertPillWidget extends StatelessWidget {
  final _UrgentAlertPill data;

  const _AlertPillWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final Color border;

    switch (data.tone) {
      case _AlertTone.critical:
        fg = TuLojitaBrandColors.danger;
        bg = TuLojitaBrandColors.dangerBg;
        border = const Color(0xFFFECACA);
      case _AlertTone.amber:
        fg = TuLojitaBrandColors.amber800;
        bg = TuLojitaBrandColors.amber50;
        border = TuLojitaBrandColors.amber400;
      case _AlertTone.indigo:
        fg = TuLojitaBrandColors.indigo700;
        bg = TuLojitaBrandColors.indigo50;
        border = TuLojitaBrandColors.indigo100;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: data.icon, color: fg, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 15, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

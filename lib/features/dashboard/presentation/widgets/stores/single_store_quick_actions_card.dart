import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/store_ai/presentation/providers/store_ai_providers.dart';

/// Direct Bento operational grid rendered beneath the sole store scorecard
/// when a user manages exactly one authorized store.
class SingleStoreQuickActionsCard extends ConsumerWidget {
  final Store store;
  final User? user;
  final int unreadDisputesCount;

  const SingleStoreQuickActionsCard({
    super.key,
    required this.store,
    required this.user,
    this.unreadDisputesCount = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGlobalAiEnabled =
        ref.watch(platformAiGlobalEnabledProvider).value ?? false;
    final isCollab = user?.isCollaborator ?? false;
    final canViewFinancials =
        !isCollab || (user != null && user!.canViewFinancialMetrics);
    final canUseAi = isGlobalAiEnabled &&
        (!isCollab
            ? (user != null && (user!.hasCompany || user!.company != null))
            : (user != null && user!.canUseStoreAi(store.id)));

    final orderUrgentTotal = store.pendingOrdersCount + unreadDisputesCount;

    final actions = <_DirectShortcut>[
      if (!isCollab ||
          (user != null && (user!.canViewOrders || user!.canProcessOrders)))
        _DirectShortcut(
          label: 'Órdenes',
          icon: HugeIcons.strokeRoundedShoppingBag01,
          badgeText: orderUrgentTotal > 0
              ? (orderUrgentTotal > 99 ? '99+' : '$orderUrgentTotal')
              : null,
          isCriticalBadge: unreadDisputesCount > 0,
          onTap: () => context.push('/dashboard/stores/${store.id}/orders'),
        ),
      if (!isCollab ||
          (user != null &&
              (user!.canEditProducts ||
                  user!.canChangePrices ||
                  user!.canManageStock)))
        _DirectShortcut(
          label: 'Artículos',
          icon: HugeIcons.strokeRoundedPackage,
          onTap: () => context.push('/dashboard/stores/${store.id}/items'),
        ),
      if (!isCollab || (user != null && user!.canViewInstallments))
        _DirectShortcut(
          label: 'Cuotas',
          icon: HugeIcons.strokeRoundedCalendar03,
          useAmberAccent: true,
          onTap: () =>
              context.push('/dashboard/stores/${store.id}/installments'),
        ),
      if (canUseAi)
        _DirectShortcut(
          label: 'Estudio IA',
          icon: HugeIcons.strokeRoundedSparkles,
          onTap: () => context.push(
            '/dashboard/stores/${store.id}/ai-settings',
            extra: store.displayName,
          ),
        ),
      _DirectShortcut(
        label: 'Mi Ranking',
        icon: HugeIcons.strokeRoundedAward01,
        useAmberAccent: true,
        onTap: () => context.push('/dashboard/stores/${store.id}/ranking'),
      ),
      if (canViewFinancials)
        _DirectShortcut(
          label: 'Comisiones',
          icon: HugeIcons.strokeRoundedInvoice01,
          badgeText: store.pendingCommissionReportsCount > 0
              ? '${store.pendingCommissionReportsCount} rev.'
              : (store.commissionDebt > 0 ? 'Deuda' : null),
          useAmberAccent: true,
          onTap: () => context.push('/dashboard/stores/${store.id}/debts'),
        ),
      if (!isCollab || (user != null && user!.canManageBranches))
        _DirectShortcut(
          label: 'Ajustes',
          icon: HugeIcons.strokeRoundedSettings03,
          onTap: () => context.push('/dashboard/stores/${store.id}/settings'),
        ),
    ];

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TuLojitaBrandColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión Directa',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: TuLojitaBrandColors.inkPrimary,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final columns = constraints.maxWidth >= 560 ? 3 : 2;
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: actions
                    .map(
                      (item) => SizedBox(
                        width: tileWidth,
                        child: _DirectShortcutTile(data: item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DirectShortcut {
  final String label;
  final dynamic icon;
  final bool useAmberAccent;
  final String? badgeText;
  final bool isCriticalBadge;
  final VoidCallback onTap;

  const _DirectShortcut({
    required this.label,
    required this.icon,
    this.useAmberAccent = false,
    this.badgeText,
    this.isCriticalBadge = false,
    required this.onTap,
  });
}

class _DirectShortcutTile extends StatelessWidget {
  final _DirectShortcut data;

  const _DirectShortcutTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final bgTint = data.useAmberAccent
        ? TuLojitaBrandColors.amber50
        : TuLojitaBrandColors.indigo50;
    final iconColor = data.useAmberAccent
        ? TuLojitaBrandColors.amber700
        : TuLojitaBrandColors.indigo600;

    return Material(
      color: TuLojitaBrandColors.canvas,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: bgTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: data.icon,
                      color: iconColor,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: (data.badgeText != null &&
                              data.badgeText!.isNotEmpty)
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: data.isCriticalBadge
                                    ? TuLojitaBrandColors.danger
                                    : TuLojitaBrandColors.amber400,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                data.badgeText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: data.isCriticalBadge
                                      ? Colors.white
                                      : TuLojitaBrandColors.inkPrimary,
                                ),
                              ),
                            )
                          : const HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              color: TuLojitaBrandColors.inkSecondary,
                              size: 13,
                            ),
                    ),
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
                    data.label,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: TuLojitaBrandColors.inkPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_dashboard.dart';

/// Categorized Bento modal bottom sheet triggered by the header gear icon on
/// [StoreDetailsScreen], surfacing all permission-scoped branch operations,
/// financial tools, readiness/compliance actions, and store settings.
class StoreDetailsManagementSheet extends StatelessWidget {
  final BuildContext parentContext;
  final Store store;
  final StoreStats? stats;
  final User? user;
  final int unreadDisputesCount;
  final bool isGlobalAiEnabled;
  final VoidCallback onOpenHealthSheet;

  const StoreDetailsManagementSheet({
    super.key,
    required this.parentContext,
    required this.store,
    this.stats,
    required this.user,
    this.unreadDisputesCount = 0,
    this.isGlobalAiEnabled = false,
    required this.onOpenHealthSheet,
  });

  /// Returns `true` when there is at least one urgent alert relevant to the
  /// current actor's role and permissions.
  static bool hasAttentionAlerts({
    required Store store,
    StoreStats? stats,
    required User? user,
    int unreadDisputesCount = 0,
  }) {
    final isCollab = user?.isCollaborator ?? false;
    final canViewOrders = !isCollab ||
        (user != null && (user.canViewOrders || user.canProcessOrders));
    final canViewDisputes =
        !isCollab || (user != null && user.canViewDisputes);
    final canViewFinancials =
        !isCollab || (user != null && user.canViewFinancialMetrics);
    final canManageBranches =
        !isCollab || (user != null && user.canManageBranches);
    final canViewStrikes = canManageBranches || canViewOrders;
    final canViewMediations = !isCollab;

    final openDisputesCount = stats?.openDisputesCount ?? 0;
    final totalDisputes = unreadDisputesCount > openDisputesCount
        ? unreadDisputesCount
        : openDisputesCount;
    final pendingOrdersCount =
        stats?.pendingOrdersCount ?? store.pendingOrdersCount;
    final commissionDebt = stats?.commissionDebt ?? store.commissionDebt;
    final pendingReports = stats?.pendingCommissionReportsCount ??
        store.pendingCommissionReportsCount;
    final activeStrikes = stats?.activeStrikesCount ?? 0;
    final pendingMediations = stats?.pendingMediationRequestsCount ?? 0;
    final missingPaymentMethods =
        stats != null && stats.paymentMethodsCount == 0;

    return (canViewDisputes && totalDisputes > 0) ||
        (canViewOrders && pendingOrdersCount > 0) ||
        (canViewFinancials && (commissionDebt > 0 || pendingReports > 0)) ||
        (canViewStrikes && activeStrikes > 0) ||
        (canViewMediations && pendingMediations > 0) ||
        (canManageBranches && missingPaymentMethods);
  }

  /// Opens [StoreDetailsManagementSheet] safely anchored to [context].
  static Future<void> show(
    BuildContext context, {
    required Store store,
    StoreStats? stats,
    required User? user,
    int unreadDisputesCount = 0,
    bool isGlobalAiEnabled = false,
    required VoidCallback onOpenHealthSheet,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StoreDetailsManagementSheet(
        parentContext: context,
        store: store,
        stats: stats,
        user: user,
        unreadDisputesCount: unreadDisputesCount,
        isGlobalAiEnabled: isGlobalAiEnabled,
        onOpenHealthSheet: onOpenHealthSheet,
      ),
    );
  }

  void _navigateRoute(
    BuildContext sheetContext,
    String location, {
    Object? extra,
  }) {
    final router = GoRouter.maybeOf(parentContext);
    Navigator.of(sheetContext).pop();
    if (router != null) {
      router.push(location, extra: extra);
    } else if (parentContext.mounted) {
      parentContext.push(location, extra: extra);
    }
  }

  void _openHealth(BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    onOpenHealthSheet();
  }

  @override
  Widget build(BuildContext context) {
    final isCollab = user?.isCollaborator ?? false;
    final canViewOrders = !isCollab ||
        (user != null && (user!.canViewOrders || user!.canProcessOrders));
    final canViewDisputes =
        !isCollab || (user != null && user!.canViewDisputes);
    final canViewInstallments =
        !isCollab || (user != null && user!.canViewInstallments);
    final canViewProducts = !isCollab ||
        (user != null &&
            (user!.canManageStock ||
                user!.canChangePrices ||
                user!.canEditProducts));
    final canManageCategories = !isCollab ||
        (user != null && (user!.canEditProducts || user!.canManageBranches));
    final canViewFinancials =
        !isCollab || (user != null && user!.canViewFinancialMetrics);
    final canManageBranches =
        !isCollab || (user != null && user!.canManageBranches);
    final canUseAi = isGlobalAiEnabled &&
        (!isCollab
            ? (user == null || user!.hasCompany || user!.company != null)
            : (user != null && user!.canUseStoreAi(store.id)));
    final canViewStrikes = canManageBranches || canViewOrders;
    final canViewMediations = !isCollab;
    final canViewBlocked = !isCollab;

    final pendingOrdersCount =
        stats?.pendingOrdersCount ?? store.pendingOrdersCount;
    final openDisputesCount = stats?.openDisputesCount ?? 0;
    final totalDisputes = unreadDisputesCount > openDisputesCount
        ? unreadDisputesCount
        : openDisputesCount;

    final String? ordersBadgeText;
    final bool isOrdersCritical;
    if (canViewDisputes && totalDisputes > 0) {
      ordersBadgeText = 'Reclamos';
      isOrdersCritical = true;
    } else if (pendingOrdersCount > 0) {
      ordersBadgeText = pendingOrdersCount > 99 ? '99+' : '$pendingOrdersCount';
      isOrdersCritical = false;
    } else {
      ordersBadgeText = null;
      isOrdersCritical = false;
    }

    final pendingReports = stats?.pendingCommissionReportsCount ??
        store.pendingCommissionReportsCount;
    final commissionDebt = stats?.commissionDebt ?? store.commissionDebt;
    final String? commissionBadge = pendingReports > 0
        ? '$pendingReports rev.'
        : (commissionDebt > 0 ? 'Deuda' : null);

    final activeStrikes = stats?.activeStrikesCount ?? 0;
    final pendingMediations = stats?.pendingMediationRequestsCount ?? 0;
    final aiActive = stats?.aiEnabled ?? store.aiEnabled;
    final missingPaymentMethods =
        stats != null && stats!.paymentMethodsCount == 0;

    final dailyItems = <_GearActionItem>[
      if (canViewOrders)
        _GearActionItem(
          label: 'Órdenes',
          icon: HugeIcons.strokeRoundedShoppingBag01,
          badgeText: ordersBadgeText,
          isCriticalBadge: isOrdersCritical,
          onTap: () =>
              _navigateRoute(context, '/dashboard/stores/${store.id}/orders'),
        ),
      if (canViewProducts)
        _GearActionItem(
          label: 'Artículos',
          icon: HugeIcons.strokeRoundedPackage,
          badgeText: stats != null && stats!.totalItems > 0
              ? '${stats!.totalItems}'
              : null,
          onTap: () =>
              _navigateRoute(context, '/dashboard/stores/${store.id}/items'),
        ),
      if (canViewInstallments)
        _GearActionItem(
          label: 'Cuotas y Deudas',
          icon: HugeIcons.strokeRoundedCalendar03,
          useAmberAccent: true,
          onTap: () => _navigateRoute(
            context,
            '/dashboard/stores/${store.id}/installments',
          ),
        ),
      if (canManageCategories)
        _GearActionItem(
          label: 'Categorías',
          icon: HugeIcons.strokeRoundedFolder01,
          onTap: () => _navigateRoute(
            context,
            '/dashboard/stores/${store.id}/categories',
          ),
        ),
      _GearActionItem(
        label: 'Mi Ranking',
        icon: HugeIcons.strokeRoundedAward01,
        useAmberAccent: true,
        onTap: () =>
            _navigateRoute(context, '/dashboard/stores/${store.id}/ranking'),
      ),
    ];

    final growthItems = <_GearActionItem>[
      if (canUseAi)
        _GearActionItem(
          label: 'Estudio IA',
          icon: HugeIcons.strokeRoundedSparkles,
          badgeText: aiActive ? 'Activa' : 'BYOK',
          useAmberAccent: !aiActive,
          isPositiveBadge: aiActive,
          onTap: () => _navigateRoute(
            context,
            '/dashboard/stores/${store.id}/ai-settings',
            extra: store.displayName,
          ),
        ),
      if (canViewFinancials)
        _GearActionItem(
          label: 'Comisiones',
          icon: HugeIcons.strokeRoundedInvoice01,
          badgeText: commissionBadge,
          useAmberAccent: true,
          isCriticalBadge: commissionDebt > 0 && pendingReports == 0,
          onTap: () =>
              _navigateRoute(context, '/dashboard/stores/${store.id}/debts'),
        ),
      if (canManageBranches)
        _GearActionItem(
          label: 'Métodos de Pago',
          icon: HugeIcons.strokeRoundedCreditCard,
          badgeText: missingPaymentMethods ? 'Falta' : null,
          useAmberAccent: missingPaymentMethods,
          isCriticalBadge: missingPaymentMethods,
          onTap: () => _navigateRoute(
            context,
            '/dashboard/stores/${store.id}/payment-methods',
          ),
        ),
    ];

    final securityItems = <_GearActionItem>[
      if (canViewStrikes)
        _GearActionItem(
          label: 'Salud',
          icon: HugeIcons.strokeRoundedShield01,
          badgeText: activeStrikes > 0 ? '$activeStrikes str.' : null,
          isCriticalBadge: activeStrikes > 0,
          onTap: () => _openHealth(context),
        ),
      if (canViewMediations)
        _GearActionItem(
          label: 'Mediaciones',
          icon: HugeIcons.strokeRoundedMessage01,
          badgeText: pendingMediations > 0 ? '$pendingMediations' : null,
          useAmberAccent: pendingMediations > 0,
          onTap: () => _navigateRoute(
            context,
            '/dashboard/stores/${store.id}/mediation-requests',
          ),
        ),
      if (canViewBlocked)
        _GearActionItem(
          label: 'Clientes Bloqueados',
          icon: HugeIcons.strokeRoundedUserBlock01,
          onTap: () => _navigateRoute(
            context,
            '/dashboard/stores/${store.id}/blocked-customers',
          ),
        ),
      if (canManageBranches)
        _GearActionItem(
          label: 'Configuración de Tienda',
          icon: HugeIcons.strokeRoundedSettings03,
          onTap: () =>
              _navigateRoute(context, '/dashboard/stores/${store.id}/settings'),
        ),
    ];

    final sections = <_ManagementSection>[
      if (dailyItems.isNotEmpty)
        _ManagementSection(title: 'Operación Diaria', items: dailyItems),
      if (growthItems.isNotEmpty)
        _ManagementSection(title: 'Crecimiento y Finanzas', items: growthItems),
      if (securityItems.isNotEmpty)
        _ManagementSection(title: 'Seguridad y Ajustes', items: securityItems),
    ];

    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.indigo50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSettings01,
                    color: TuLojitaBrandColors.indigo600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gestión de Sucursal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: TuLojitaBrandColors.inkPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        store.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TuLojitaBrandColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar menú',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TuLojitaBrandColors.borderSubtle),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var sIdx = 0; sIdx < sections.length; sIdx++) ...[
                    if (sIdx > 0) const SizedBox(height: 18),
                    Text(
                      sections[sIdx].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: TuLojitaBrandColors.inkSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 10.0;
                        final columns = constraints.maxWidth >= 560 ? 3 : 2;
                        final tileWidth = (constraints.maxWidth -
                                spacing * (columns - 1)) /
                            columns;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: sections[sIdx]
                              .items
                              .map(
                                (item) => SizedBox(
                                  width: tileWidth,
                                  child: _GearSheetTile(data: item),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementSection {
  final String title;
  final List<_GearActionItem> items;

  const _ManagementSection({
    required this.title,
    required this.items,
  });
}

class _GearActionItem {
  final String label;
  final dynamic icon;
  final bool useAmberAccent;
  final String? badgeText;
  final bool isCriticalBadge;
  final bool isPositiveBadge;
  final VoidCallback onTap;

  const _GearActionItem({
    required this.label,
    required this.icon,
    this.useAmberAccent = false,
    this.badgeText,
    this.isCriticalBadge = false,
    this.isPositiveBadge = false,
    required this.onTap,
  });
}

class _GearSheetTile extends StatelessWidget {
  final _GearActionItem data;

  const _GearSheetTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final bgTint = data.useAmberAccent
        ? TuLojitaBrandColors.amber50
        : TuLojitaBrandColors.indigo50;
    final iconColor = data.useAmberAccent
        ? TuLojitaBrandColors.amber700
        : TuLojitaBrandColors.indigo600;

    final Color badgeBg = data.isCriticalBadge
        ? TuLojitaBrandColors.dangerBg
        : data.isPositiveBadge
            ? TuLojitaBrandColors.positiveBg
            : data.useAmberAccent
                ? TuLojitaBrandColors.amber100
                : TuLojitaBrandColors.indigo100;
    final Color badgeFg = data.isCriticalBadge
        ? TuLojitaBrandColors.danger
        : data.isPositiveBadge
            ? TuLojitaBrandColors.positive
            : data.useAmberAccent
                ? TuLojitaBrandColors.amber800
                : TuLojitaBrandColors.indigo700;

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
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  data.badgeText!,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: badgeFg,
                                  ),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: TuLojitaBrandColors.inkSecondary,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                      fontSize: 13,
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

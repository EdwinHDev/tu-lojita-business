import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_dashboard.dart';

/// Interactive setup readiness card shown only for active branches missing
/// catalog, category, or active payment method prerequisites.
class StoreReadinessChecklistCard extends StatelessWidget {
  final Store store;
  final StoreDashboard? dashboard;
  final User? user;

  const StoreReadinessChecklistCard({
    super.key,
    required this.store,
    required this.dashboard,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final loadedDashboard = dashboard;
    if (loadedDashboard == null ||
        store.isDeleted ||
        store.status.toUpperCase() != 'ACTIVE') {
      return const SizedBox.shrink();
    }

    final stats = loadedDashboard.stats;
    final hasCoreMissing = stats.totalItems == 0 ||
        stats.totalCategories == 0 ||
        stats.paymentMethodsCount == 0;
    if (!hasCoreMissing) {
      return const SizedBox.shrink();
    }

    final isCollab = user?.isCollaborator ?? false;
    final canManageCatalog = !isCollab ||
        (user != null &&
            (user!.canEditProducts ||
                user!.canManageStock ||
                user!.canChangePrices));
    final canManageCategories = !isCollab ||
        (user != null && (user!.canEditProducts || user!.canManageBranches));
    final canManageBranch =
        !isCollab || (user != null && user!.canManageBranches);

    final steps = <_ChecklistStep>[
      if (stats.totalCategories == 0 && canManageCategories)
        _ChecklistStep(
          title: 'Crea tu primera categoría',
          subtitle: 'Organiza el catálogo de la sucursal',
          icon: HugeIcons.strokeRoundedFolder01,
          onTap: () =>
              context.push('/dashboard/stores/${store.id}/categories/new'),
        ),
      if (stats.totalItems == 0 && canManageCatalog)
        _ChecklistStep(
          title: 'Publica tu primer artículo',
          subtitle: 'Activa tu vitrina para recibir pedidos',
          icon: HugeIcons.strokeRoundedPackage,
          onTap: () => context.push('/dashboard/stores/${store.id}/items/new'),
        ),
      if (stats.paymentMethodsCount == 0 && canManageBranch)
        _ChecklistStep(
          title: 'Configura un método de pago',
          subtitle: 'Requerido para recibir pagos de clientes',
          icon: HugeIcons.strokeRoundedCreditCard,
          onTap: () =>
              context.push('/dashboard/stores/${store.id}/payment-methods'),
        ),
      if ((store.coverImage == null || store.coverImage!.trim().isEmpty) &&
          canManageBranch)
        _ChecklistStep(
          title: 'Agrega una portada de tienda',
          subtitle: 'Destaca tu sucursal en el marketplace',
          icon: HugeIcons.strokeRoundedImage01,
          onTap: () => context.push('/dashboard/stores/${store.id}/settings'),
        ),
    ];

    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TuLojitaBrandColors.indigo100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: TuLojitaBrandColors.indigo50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckList,
                  color: TuLojitaBrandColors.indigo600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prepara tu sucursal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: TuLojitaBrandColors.inkPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Completa estos pasos para empezar a vender',
                      style: TextStyle(
                        fontSize: 12,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ChecklistTile(step: steps[i]),
          ],
        ],
      ),
    );
  }
}

class _ChecklistStep {
  final String title;
  final String subtitle;
  final dynamic icon;
  final VoidCallback onTap;

  const _ChecklistStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _ChecklistTile extends StatelessWidget {
  final _ChecklistStep step;

  const _ChecklistTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TuLojitaBrandColors.canvas,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: step.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              HugeIcon(
                icon: step.icon,
                color: TuLojitaBrandColors.indigo600,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TuLojitaBrandColors.inkPrimary,
                      ),
                    ),
                    Text(
                      step.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: TuLojitaBrandColors.indigo600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

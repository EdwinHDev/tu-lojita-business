import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_branch_resolver.dart';

/// Bento operational summary card shown to collaborators without financial metrics permission.
/// Never renders monetary totals, debt balances, or financial charts.
class HomeOperationalCard extends StatelessWidget {
  final User? user;
  final List<Store> stores;
  final int unreadDisputesCount;
  final VoidCallback onViewStores;

  const HomeOperationalCard({
    super.key,
    required this.user,
    required this.stores,
    required this.unreadDisputesCount,
    required this.onViewStores,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCollab = user != null && user!.isCollaborator;
    final bool canAccessOrders =
        !isCollab || user!.canViewOrders || user!.canProcessOrders;
    final bool canAccessDisputes = !isCollab || user!.canViewDisputes;
    final bool canAccessBranchAdmin = !isCollab ||
        user!.canManageBranches ||
        user!.hasPermission('branches:view');

    final authorizedStores = (isCollab && !user!.hasFullBranchAccess)
        ? stores.where((s) => user!.canAccessBranch(s.id)).toList()
        : stores;
    final scheduledDeletionStores = canAccessBranchAdmin
        ? authorizedStores.where((s) => s.isScheduledForDeletion).toList()
        : const <Store>[];

    final alertChips = <Widget>[
      if (canAccessDisputes && unreadDisputesCount > 0)
        _OperationalAlertChip(
          label: unreadDisputesCount == 1
              ? '1 reclamo sin leer'
              : '$unreadDisputesCount reclamos sin leer',
          icon: HugeIcons.strokeRoundedAlertCircle,
          onTap: () {
            if (authorizedStores.length == 1 && canAccessOrders) {
              context.push('/dashboard/stores/${authorizedStores.first.id}/orders');
            } else {
              context.push('/dashboard/notifications');
            }
          },
        ),
      if (canAccessBranchAdmin && scheduledDeletionStores.isNotEmpty)
        _OperationalAlertChip(
          label: scheduledDeletionStores.length == 1
              ? 'Baja · ${storeShortLabel(scheduledDeletionStores.first)}'
              : '${scheduledDeletionStores.length} sedes por eliminar',
          icon: HugeIcons.strokeRoundedDelete02,
          onTap: () async {
            final deletionOptions =
                buildScheduledDeletionOriginOptions(scheduledDeletionStores);
            final storeId = await resolveOriginStoreId(
              context,
              selectedStoreId: 'all',
              options: deletionOptions,
              title: 'Revisar baja programada',
            );
            if (storeId != null && context.mounted) {
              context.push('/dashboard/stores/$storeId');
            }
          },
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: TuLojitaBrandColors.indigo50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedStore01,
                  color: TuLojitaBrandColors.indigo600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Panel Operativo de Sucursales',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: TuLojitaBrandColors.inkPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${authorizedStores.length} sucursal(es) autorizada(s) para operar',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TuLojitaBrandColors.inkSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (alertChips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: TuLojitaBrandColors.amber50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: TuLojitaBrandColors.amber400,
                  width: 1,
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: alertChips,
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewStores,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedStore01,
                    color: TuLojitaBrandColors.indigo600,
                    size: 18,
                  ),
                  label: const Text(
                    'Ver Tiendas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TuLojitaBrandColors.indigo600,
                    side: const BorderSide(color: TuLojitaBrandColors.indigo600),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/dashboard/notifications'),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification01,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Alertas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TuLojitaBrandColors.indigo600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationalAlertChip extends StatelessWidget {
  final String label;
  final dynamic icon;
  final VoidCallback onTap;

  const _OperationalAlertChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TuLojitaBrandColors.amber100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                color: TuLojitaBrandColors.amber800,
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: TuLojitaBrandColors.amber800,
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

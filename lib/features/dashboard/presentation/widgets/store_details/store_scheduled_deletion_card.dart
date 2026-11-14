import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';

/// Prominent recovery banner when a branch is queued for scheduled deletion.
class StoreScheduledDeletionCard extends ConsumerWidget {
  final Store store;
  final bool canManageLifecycle;

  const StoreScheduledDeletionCard({
    super.key,
    required this.store,
    this.canManageLifecycle = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graceDays = store.remainingGraceDays;
    final isSuspended = store.status.toUpperCase() == 'SUSPENDED';
    final hasDebtOrPendingReports =
        store.commissionDebt > 0 || store.pendingCommissionReportsCount > 0;
    final remainsSuspendedOnCancel = isSuspended || hasDebtOrPendingReports;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.dangerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF87171), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: TuLojitaBrandColors.danger.withValues(alpha: 0.08),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TuLojitaBrandColors.danger.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: TuLojitaBrandColors.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Baja Programada Activa',
                      style: TextStyle(
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Eliminación definitiva en $graceDays día${graceDays == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: TuLojitaBrandColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            remainsSuspendedOnCancel
                ? 'Esta sucursal tiene una suspensión o deuda pendiente. Cancelar la eliminación NO la reactivará: permanecerá Suspendida hasta regularizar el pago o sanción con administración.'
                : 'Esta sucursal está oculta a los clientes. Si no cancelas la solicitud antes de que expire el plazo, la tienda se dará de baja automáticamente.',
            style: const TextStyle(
              color: Color(0xFF7F1D1D),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (canManageLifecycle) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleCancelDeletion(
                  context,
                  ref,
                  remainsSuspendedOnCancel: remainsSuspendedOnCancel,
                ),
                icon: Icon(
                  remainsSuspendedOnCancel
                      ? Icons.cancel_outlined
                      : Icons.restore_rounded,
                  size: 18,
                ),
                label: Text(
                  remainsSuspendedOnCancel
                      ? 'Cancelar Eliminación'
                      : 'Cancelar Eliminación y Reactivar',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: remainsSuspendedOnCancel
                      ? const Color(0xFF475569)
                      : const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleCancelDeletion(
    BuildContext context,
    WidgetRef ref, {
    required bool remainsSuspendedOnCancel,
  }) async {
    final targetName = store.branchName ?? store.name;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cancelar eliminación?'),
        content: Text(
          remainsSuspendedOnCancel
              ? '¿Deseas cancelar la eliminación programada de "$targetName"? Al mantener una suspensión o deuda pendiente, la sucursal permanecerá Suspendida y no se reactivará hasta regularizar el pago o sanción.'
              : '¿Deseas cancelar la eliminación de "$targetName" y reactivarla inmediatamente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: remainsSuspendedOnCancel
                  ? const Color(0xFF475569)
                  : const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text(
              remainsSuspendedOnCancel
                  ? 'Sí, cancelar eliminación'
                  : 'Sí, reactivar',
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final repo = ref.read(storesRepositoryProvider);
        final updated = await repo.cancelScheduledDeletion(store.id);
        if (context.mounted) {
          if (updated.status.toUpperCase() == 'SUSPENDED' ||
              remainsSuspendedOnCancel) {
            NotificationService.showWarning(
              context,
              'Eliminación cancelada. La sucursal permanece suspendida hasta regularizar pagos o sanciones.',
            );
          } else {
            NotificationService.showSuccess(
              context,
              'Eliminación programada cancelada con éxito.',
            );
          }
          ref.read(storeDetailsProvider.notifier).refresh(store.id);
          ref.read(storesProvider.notifier).loadData();
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(
            context,
            e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    }
  }
}

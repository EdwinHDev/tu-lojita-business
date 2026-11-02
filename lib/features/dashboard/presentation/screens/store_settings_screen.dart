import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/store_settings_notifier.dart';
import '../providers/dashboard_providers.dart';
import '../providers/stores_notifier.dart';
import '../widgets/branch_lifecycle_dialogs.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import '../../../payment_methods/presentation/screens/payment_methods_list_screen.dart';
import 'settings/appearance_settings_screen.dart';
import 'settings/partial_payments_settings_screen.dart';
import 'settings/chat_settings_screen.dart';
import 'settings/timezone_settings_screen.dart';
import 'settings/blocked_customers_screen.dart';
import 'settings/mediation_requests_screen.dart';
import 'settings/store_health_sheet.dart';
import 'package:tu_lojita_business/features/subscription/presentation/screens/store_debts_screen.dart';
import '../../domain/entities/store.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  final String storeId;
  const StoreSettingsScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeSettingsProvider.notifier).loadStore(widget.storeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);
    final authState = ref.watch(authProvider);
    final currentUser = authState is Authenticated ? authState.user : null;
    final canManageLifecycle =
        currentUser == null || !currentUser.isCollaborator || currentUser.canManageBranches;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Color(0xFF111827),
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Configuración de Tienda',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedImageAdd02,
                  title: 'Identidad Visual',
                  subtitle: 'Banner y nombre de la sucursal',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AppearanceSettingsScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedCreditCard,
                  title: 'Pagos Parciales',
                  subtitle: 'Cuotas, recargos y frecuencias',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PartialPaymentsSettingsScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedChat01,
                  title: 'Configuración de Chat',
                  subtitle: 'Habilitar o deshabilitar chat de órdenes',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatSettingsScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedWallet01,
                  title: 'Métodos de Pago',
                  subtitle: 'Cuentas bancarias y pagos móviles',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PaymentMethodsListScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedCoins01,
                  title: 'Comisiones y Deudas',
                  subtitle: 'Estado de deuda semanal y reporte de pagos',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StoreDebtsScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedCalendar03,
                  title: 'Zona Horaria',
                  subtitle: 'Huso horario para estadísticas y fechas',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TimezoneSettingsScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedUserBlock01,
                  title: 'Clientes Bloqueados',
                  subtitle: 'Gestión y desbloqueo de clientes restringidos',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BlockedCustomersScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedMail01,
                  title: 'Solicitudes de Mediación',
                  subtitle: 'Buzón de apelaciones de clientes para reactivación',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MediationRequestsScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  title: 'Salud del Comercio y Sanciones',
                  subtitle: 'Estado de la cuenta, strikes y cumplimiento de políticas',
                  onTap: () => StoreHealthSheet.show(context, widget.storeId),
                ),
                const SizedBox(height: 24),
                // Tarjeta de Restricción de Edad (+18)
                Builder(
                  builder: (context) {
                    final isLockedByRubro = state.store?.isCategoryOrSubcategoryRestricted == true;
                    final isAgeRestrictedValue = isLockedByRubro || state.isAgeRestricted;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLockedByRubro ? const Color(0xFFEF4444).withValues(alpha: 0.3) : Colors.grey.shade100,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedAlertCircle,
                                  color: Color(0xFFEF4444),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Restricción de Edad (+18)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Oculta tu tienda y productos para menores de edad',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: isAgeRestrictedValue,
                                activeTrackColor: const Color(0xFFEF4444),
                                onChanged: isLockedByRubro
                                    ? null
                                    : (val) {
                                        ref.read(storeSettingsProvider.notifier).updateAgeRestricted(val);
                                        ref.read(storeSettingsProvider.notifier).saveSettings(
                                          widget.storeId,
                                          specificData: {'isAgeRestricted': val},
                                        );
                                      },
                              ),
                            ],
                          ),
                          if (isLockedByRubro) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.lock_outline, size: 14, color: Color(0xFFEF4444)),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Bloqueado en activado (+18): la categoría o subcategoría asignada a esta tienda es exclusivamente para adultos.',
                                      style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                if (canManageLifecycle && state.store != null) ...[
                  const SizedBox(height: 24),
                  _buildLifecycleCard(context, state.store!),
                ],
              ],
            ),
    );
  }

  Widget _buildMenuTile({
    required dynamic icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: HugeIcon(
            icon: icon,
            color: const Color(0xFF4F46E5),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827), fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 20),
      ),
    );
  }

  Widget _buildLifecycleCard(BuildContext context, Store store) {
    final isDeleting = store.isScheduledForDeletion;
    final isInactive = store.status == 'INACTIVE' && !isDeleting;
    final isActive = store.status == 'ACTIVE' && !isDeleting;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData badgeIcon;

    if (isDeleting) {
      badgeBg = const Color(0xFFFEF2F2);
      badgeText = const Color(0xFFDC2626);
      badgeLabel = 'Baja programada (${store.remainingGraceDays}d)';
      badgeIcon = Icons.delete_forever_rounded;
    } else if (isInactive) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFF92400E);
      badgeLabel = 'Pausada';
      badgeIcon = Icons.pause_circle_outline_rounded;
    } else {
      badgeBg = const Color(0xFFECFDF5);
      badgeText = const Color(0xFF047857);
      badgeLabel = 'Activa';
      badgeIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDeleting ? const Color(0xFFFEF2F2).withValues(alpha: 0.5) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDeleting ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDeleting
                          ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                          : const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: isDeleting
                          ? HugeIcons.strokeRoundedAlertCircle
                          : HugeIcons.strokeRoundedStore01,
                      color: isDeleting ? const Color(0xFFDC2626) : const Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Estado de la Sucursal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeText.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: badgeText),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isDeleting) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFE11D48)),
                      const SizedBox(width: 6),
                      Text(
                        'Baja definitiva en ${store.remainingGraceDays} días',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9F1239),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Esta sucursal está oculta para compras. Si cambias de opinión, puedes cancelar la eliminación ahora y restaurar sus operaciones sin perder ningún dato.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleCancelDeletion(store),
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('Cancelar Eliminación y Reactivar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              isActive
                  ? 'La sucursal está activa y visible para tus clientes en la app de compras.'
                  : 'La sucursal está pausada y oculta para compras. Puedes reactivarla cuando desees.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.35),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => isActive
                        ? _handleDeactivateFlow(store)
                        : _handleReactivateFlow(store),
                    icon: Icon(
                      isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(isActive ? 'Pausar Sucursal' : 'Reactivar Sucursal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive ? const Color(0xFFD97706) : const Color(0xFF10B981),
                      side: BorderSide(
                        color: isActive ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDeleteFlow(store),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleDeactivateFlow(Store store) async {
    final repo = ref.read(storesRepositoryProvider);
    try {
      final preflight = await repo.validateLifecyclePreflight(store.id);
      if (!mounted) return;

      if (!preflight.canProceed) {
        BranchPreflightBlockersDialog.show(
          context,
          branchName: store.branchName ?? store.name,
          actionTitle: 'pausar',
          blockers: preflight.blockers,
        );
        return;
      }

      final otpRes = await repo.requestLifecycleOtp(store.id, 'DEACTIVATE');
      if (!mounted) return;

      final updated = await BranchLifecycleOtpDialog.show(
        context,
        storeId: store.id,
        branchName: store.branchName ?? store.name,
        actionType: 'DEACTIVATE',
        initialEmail: otpRes.email,
      );

      if (updated != null && mounted) {
        NotificationService.showSuccess(
          context,
          'Sucursal pausada exitosamente',
        );
        ref.read(storeSettingsProvider.notifier).loadStore(widget.storeId);
        ref.read(storesProvider.notifier).loadData();
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _handleReactivateFlow(Store store) async {
    final repo = ref.read(storesRepositoryProvider);
    try {
      await repo.reactivateBranch(store.id);
      if (!mounted) return;

      NotificationService.showSuccess(
        context,
        'Sucursal reactivada exitosamente',
      );
      ref.read(storeSettingsProvider.notifier).loadStore(widget.storeId);
      ref.read(storesProvider.notifier).loadData();
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _handleDeleteFlow(Store store) async {
    final repo = ref.read(storesRepositoryProvider);
    try {
      final preflight = await repo.validateLifecyclePreflight(store.id);
      if (!mounted) return;

      if (!preflight.canProceed) {
        BranchPreflightBlockersDialog.show(
          context,
          branchName: store.branchName ?? store.name,
          actionTitle: 'eliminar',
          blockers: preflight.blockers,
        );
        return;
      }

      final otpRes = await repo.requestLifecycleOtp(store.id, 'SCHEDULE_DELETION');
      if (!mounted) return;

      final updated = await BranchLifecycleOtpDialog.show(
        context,
        storeId: store.id,
        branchName: store.branchName ?? store.name,
        actionType: 'SCHEDULE_DELETION',
        initialEmail: otpRes.email,
      );

      if (updated != null && mounted) {
        NotificationService.showSuccess(
          context,
          'Eliminación programada iniciada (7 días de gracia)',
        );
        ref.read(storeSettingsProvider.notifier).loadStore(widget.storeId);
        ref.read(storesProvider.notifier).loadData();
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _handleCancelDeletion(Store store) async {
    final repo = ref.read(storesRepositoryProvider);
    try {
      await repo.cancelScheduledDeletion(store.id);
      if (!mounted) return;

      NotificationService.showSuccess(
        context,
        'Eliminación cancelada. Sucursal reactivada.',
      );
      ref.read(storeSettingsProvider.notifier).loadStore(widget.storeId);
      ref.read(storesProvider.notifier).loadData();
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

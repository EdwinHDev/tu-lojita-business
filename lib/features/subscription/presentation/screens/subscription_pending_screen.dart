import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../providers/subscription_provider.dart';
import '../../domain/entities/company_subscription.dart';

class SubscriptionPendingScreen extends ConsumerStatefulWidget {
  const SubscriptionPendingScreen({super.key});

  @override
  ConsumerState<SubscriptionPendingScreen> createState() =>
      _SubscriptionPendingScreenState();
}

class _SubscriptionPendingScreenState
    extends ConsumerState<SubscriptionPendingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkStatus(isInitial: true));
  }

  Future<void> _checkStatus({bool isInitial = false}) async {
    await ref.read(subscriptionProvider.notifier).loadSubscriptionAndMethods();
    if (!mounted) return;
    final updated = ref.read(subscriptionProvider).subscription;
    if (updated != null &&
        (updated.status == SubscriptionStatus.active ||
            updated.status == SubscriptionStatus.gracePeriod)) {
      context.go('/dashboard');
    } else if (!isInitial) {
      NotificationService.showInfo(
        context,
        'Tu comprobante continúa en revisión administrativa.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Verificación en Curso'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              color: Colors.redAccent,
              size: 22,
            ),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono con círculo animado / estético
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC7D2FE), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedHourglass,
                    color: Color(0xFF4F46E5),
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Chip de Estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'VERIFICACIÓN EN CURSO (24 a 72h)',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Comprobante Recibido con Éxito',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Hemos recibido tu pago de la membresía mensual de \$20.00 USD. Nuestro equipo administrativo está validando la transferencia en un lapso estimado de 24 a 72 horas hábiles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

              const SizedBox(height: 28),

              // Beneficio Destacado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'En cuanto sea aprobado, todas tus tiendas se activarán automáticamente para comenzar a vender.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Te notificaremos por correo electrónico una vez se verifique la transferencia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.indigo[300] : Colors.indigo[700],
                ),
              ),

              const SizedBox(height: 36),

              // Botón Refrescar Estado
              ElevatedButton.icon(
                onPressed: subState.isLoading ? null : () => _checkStatus(),
                icon: subState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const HugeIcon(
                        icon: HugeIcons.strokeRoundedRefresh,
                        color: Colors.white,
                        size: 18,
                      ),
                label: const Text(
                  'Comprobar Estado Ahora',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botón Cerrar Sesión Secundario
              TextButton.icon(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedLogout01,
                  color: Colors.grey,
                  size: 16,
                ),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
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

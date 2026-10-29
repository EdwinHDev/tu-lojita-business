import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import '../providers/subscription_provider.dart';

class SubscriptionRejectedScreen extends ConsumerWidget {
  const SubscriptionRejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rejectionReason = (subState.lastRejectionReason != null &&
            subState.lastRejectionReason!.trim().isNotEmpty)
        ? subState.lastRejectionReason!
        : 'El comprobante o los datos suministrados no concuerdan con los registros bancarios.';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Comprobante Rechazado'),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
              // Icono de alerta / rechazo estético
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: Color(0xFFDC2626),
                    size: 46,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Chip de Estado Rechazado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PAGO NO APROBADO',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Tu Comprobante Fue Rechazado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'El equipo de administración revisó tu reporte de pago de membresía (\$20.00 USD) pero no pudo ser validado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

              const SizedBox(height: 24),

              // Card: Motivo del Rechazo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFFECDD3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedAlertCircle,
                          color: Color(0xFFE11D48),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Motivo del rechazo:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.red[300] : const Color(0xFFBE123C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      rejectionReason,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        color: isDark ? Colors.grey[200] : const Color(0xFF881337),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Card: Reassurance / Tus datos están a salvo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14291F) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E4D38) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Tus datos comerciales están a salvo!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'La información de tu empresa, logo, rubro y tiendas registradas sigue intacta. Solo necesitas subir un comprobante bancario corregido.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[300] : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // CTA: Intentar Nuevo Pago
              ElevatedButton.icon(
                onPressed: () => context.go('/subscription/paywall'),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCreditCard,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Intentar Nuevo Pago',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Botón Secundario: Cerrar Sesión
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

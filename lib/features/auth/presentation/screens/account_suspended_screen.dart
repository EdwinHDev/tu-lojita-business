import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';

/// Pantalla dedicada de aviso para comercios con cuenta suspendida temporal o permanentemente.
/// Bloquea el acceso a todas las funciones de administración, sucursales y finanzas,
/// mostrando de forma transparente el motivo, la vigencia y las vías de contacto con soporte.
class AccountSuspendedScreen extends ConsumerStatefulWidget {
  final String? suspendedUntil;
  final String? reason;

  const AccountSuspendedScreen({
    super.key,
    this.suspendedUntil,
    this.reason,
  });

  @override
  ConsumerState<AccountSuspendedScreen> createState() =>
      _AccountSuspendedScreenState();
}

class _AccountSuspendedScreenState extends ConsumerState<AccountSuspendedScreen> {
  String? _currentSuspendedUntil;
  String? _currentReason;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      _currentSuspendedUntil =
          widget.suspendedUntil ?? authState.user.accountSuspendedUntil?.toIso8601String();
      _currentReason = widget.reason ?? authState.user.accountSuspensionReason;
    } else {
      _currentSuspendedUntil = widget.suspendedUntil;
      _currentReason = widget.reason;
    }
  }

  String _formatSuspensionDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return 'Suspensión Permanente';
    }
    try {
      final date = DateTime.parse(rawDate).toLocal();
      return DateFormat("d 'de' MMMM 'de' y, hh:mm a", 'es').format(date);
    } catch (_) {
      try {
        final date = DateTime.parse(rawDate);
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      } catch (_) {
        return rawDate;
      }
    }
  }

  Future<void> _checkAccountStatus() async {
    if (_isCheckingStatus) return;
    setState(() => _isCheckingStatus = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.checkStatus();

      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState is Authenticated) {
        final user = authState.user;
        if (!user.isAccountSuspended) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Tu cuenta comercial ha sido reactivada!',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF059669),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          context.go('/splash');
          return;
        }

        setState(() {
          _currentSuspendedUntil =
              user.accountSuspendedUntil?.toIso8601String() ?? widget.suspendedUntil;
          _currentReason = user.accountSuspensionReason ?? widget.reason;
        });
      }

      final isPermanent =
          _currentSuspendedUntil == null || _currentSuspendedUntil!.trim().isEmpty;
      final formattedUntil = _formatSuspensionDate(_currentSuspendedUntil);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPermanent
                ? 'Tu cuenta comercial continúa suspendida de manera permanente.'
                : 'Tu cuenta comercial continúa suspendida hasta el $formattedUntil.',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudo verificar el estado en este momento. Revisa tu conexión a internet.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _contactSupport() async {
    const supportPhone = '584120000000'; // Soporte oficial centralizado
    final message = Uri.encodeComponent(
      'Hola, me comunico respecto a la suspensión de mi cuenta comercial en Tu Lojita Business para solicitar información o aclaratoria.',
    );
    final uri = Uri.parse('https://wa.me/$supportPhone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp en este dispositivo.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final isPermanent =
        _currentSuspendedUntil == null || _currentSuspendedUntil!.trim().isEmpty;
    final formattedDate =
        isPermanent ? 'Suspensión Permanente' : _formatSuspensionDate(_currentSuspendedUntil);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // Icono de advertencia / candado institucional
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_rounded,
                      color: Color(0xFFDC2626),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Cuenta Comercial Suspendida',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  isPermanent
                      ? 'El acceso a tu empresa y operaciones ha sido restringido de manera permanente por incumplimiento grave de las políticas de la plataforma.'
                      : 'El acceso a tu empresa y operaciones ha sido temporalmente restringido por medidas de cumplimiento o prevención de disputas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: secondaryTextColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),

                // Tarjeta de Estado / Vigencia
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPermanent
                          ? const Color(0xFFFECDD3)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPermanent
                                ? Icons.block_rounded
                                : Icons.event_available_rounded,
                            color: isPermanent
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF4F46E5),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPermanent
                                ? 'Estado de la Suspensión'
                                : 'Vigencia de la Suspensión',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isPermanent
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFF4338CA),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPermanent
                            ? 'Suspensión Permanente / Definitiva'
                            : formattedDate,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isPermanent
                              ? const Color(0xFFDC2626)
                              : primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tarjeta de Motivo de la Sanción
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFDC2626), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Motivo Registrado',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentReason ??
                            'Infracción reiterada de políticas de ventas, demoras o disputas no resueltas.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Actualizar Estado de Cuenta
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingStatus ? null : _checkAccountStatus,
                    icon: _isCheckingStatus
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    label: Text(
                      _isCheckingStatus
                          ? 'Comprobando estado...'
                          : 'Actualizar Estado de Cuenta',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón Contactar Soporte
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _contactSupport,
                    icon: const Icon(Icons.chat_bubble_rounded,
                        color: Colors.white, size: 18),
                    label: const Text(
                      'Contactar a Soporte Oficial',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón Cerrar Sesión
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/onboarding');
                      }
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECDD3), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: isDark ? Colors.transparent : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

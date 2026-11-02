import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/services/session_purge_service.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';

class BusinessAccountDeletionDialog extends ConsumerStatefulWidget {
  const BusinessAccountDeletionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BusinessAccountDeletionDialog(),
    );
  }

  @override
  ConsumerState<BusinessAccountDeletionDialog> createState() =>
      _BusinessAccountDeletionDialogState();
}

class _BusinessAccountDeletionDialogState
    extends ConsumerState<BusinessAccountDeletionDialog> {
  int _step = 1; // 1 = Warning & Request OTP, 2 = Verify OTP
  bool _isLoading = false;
  String? _deletionToken;

  final _reasonController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestOtp() async {
    setState(() => _isLoading = true);
    final reason = _reasonController.text.trim();

    try {
      final token = await ref
          .read(authProvider.notifier)
          .requestAccountDeletion(reason: reason.isNotEmpty ? reason : null);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (token != null) {
        setState(() {
          _deletionToken = token;
          _step = 2;
        });
        NotificationService.showSuccess(
          context,
          'Te enviamos un código de seguridad a tu correo.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      NotificationService.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _handleConfirmDeletion() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      NotificationService.showError(
        context,
        'El código OTP debe tener 6 dígitos numéricos.',
      );
      return;
    }

    if (_deletionToken == null) {
      NotificationService.showError(
        context,
        'Token de baja expirado. Inicia el proceso nuevamente.',
      );
      return;
    }

    setState(() => _isLoading = true);
    final reason = _reasonController.text.trim();

    try {
      final success = await ref
          .read(authProvider.notifier)
          .confirmAccountDeletion(
            deletionToken: _deletionToken!,
            otp: otp,
            reason: reason.isNotEmpty ? reason : null,
          );

      if (!mounted) return;

      if (success) {
        final navigator = Navigator.of(context, rootNavigator: true);
        final router = GoRouter.of(context);

        // Purgar sesión y caché completamente
        await ref.read(sessionPurgeServiceProvider).purge();

        navigator.pop();
        router.go('/onboarding');
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      NotificationService.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    color: Color(0xFFDC2626),
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _step == 1 ? '¿Dar de baja tu cuenta?' : 'Confirmar con código OTP',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            if (_step == 1) ...[
              const Text(
                'Esta acción desactivará tu acceso a Tu Lojita y cerrará todas tus sesiones. Tus datos de perfil y credenciales serán eliminados.\n\nPara proteger tu seguridad, te enviaremos un código OTP a tu correo.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Motivo opcional
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: '¿Por qué deseas darte de baja? (Opcional)',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRequestOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enviar Código',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'Ingresa el código de 6 dígitos que enviamos a tu correo electrónico:',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // OTP Input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade300,
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDC2626)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Color(0xFFDC2626), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _step = 1;
                                _otpController.clear();
                              });
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Atrás',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleConfirmDeletion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Eliminar Cuenta',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

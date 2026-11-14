import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../providers/dashboard_providers.dart';
import '../../domain/entities/store.dart';

/// Diálogo para mostrar bloqueadores de validación pre-vuelo (órdenes activas, disputas, cuotas)
class BranchPreflightBlockersDialog extends StatelessWidget {
  final String branchName;
  final String actionTitle;
  final List<String> blockers;

  const BranchPreflightBlockersDialog({
    super.key,
    required this.branchName,
    required this.actionTitle,
    required this.blockers,
  });

  static Future<void> show(
    BuildContext context, {
    required String branchName,
    required String actionTitle,
    required List<String> blockers,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BranchPreflightBlockersDialog(
        branchName: branchName,
        actionTitle: actionTitle,
        blockers: blockers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              color: Color(0xFFDC2626),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No es posible proceder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Sucursal: $branchName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para $actionTitle esta sucursal, primero debes resolver los siguientes requisitos y obligaciones pendientes:',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            ...blockers.map(
              (blocker) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFE11D48),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        blocker,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF881337),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Entendido'),
          ),
        ),
      ],
    );
  }
}

/// Diálogo de confirmación con código de seguridad OTP para Pausar o Eliminar Sucursal
class BranchLifecycleOtpDialog extends ConsumerStatefulWidget {
  final String storeId;
  final String branchName;
  final String actionType; // 'DEACTIVATE' | 'SCHEDULE_DELETION'
  final String initialEmail;

  const BranchLifecycleOtpDialog({
    super.key,
    required this.storeId,
    required this.branchName,
    required this.actionType,
    required this.initialEmail,
  });

  static Future<Store?> show(
    BuildContext context, {
    required String storeId,
    required String branchName,
    required String actionType,
    required String initialEmail,
  }) {
    return showDialog<Store>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BranchLifecycleOtpDialog(
        storeId: storeId,
        branchName: branchName,
        actionType: actionType,
        initialEmail: initialEmail,
      ),
    );
  }

  @override
  ConsumerState<BranchLifecycleOtpDialog> createState() =>
      _BranchLifecycleOtpDialogState();
}

class _BranchLifecycleOtpDialogState
    extends ConsumerState<BranchLifecycleOtpDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _secondsLeft = 60;
  Timer? _timer;

  bool get _isDeletion => widget.actionType == 'SCHEDULE_DELETION';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleResendOtp() async {
    if (_secondsLeft > 0) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(storesRepositoryProvider);
      await repo.requestLifecycleOtp(widget.storeId, widget.actionType);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _startTimer();
      NotificationService.showSuccess(
        context,
        'Nuevo código OTP enviado a tu correo.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      NotificationService.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _handleSubmit() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      NotificationService.showError(
        context,
        'Ingresa el código OTP de 6 dígitos numéricos.',
      );
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(storesRepositoryProvider);

    try {
      Store updatedStore;
      if (_isDeletion) {
        updatedStore = await repo.scheduleBranchDeletion(widget.storeId, otp);
      } else {
        updatedStore = await repo.deactivateBranch(widget.storeId, otp);
      }

      if (!mounted) return;
      Navigator.of(context).pop(updatedStore);
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
    final title = _isDeletion ? 'Eliminar Sucursal' : 'Desactivar Tienda';
    final themeColor = _isDeletion ? const Color(0xFFDC2626) : const Color(0xFFD97706);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(
              icon: _isDeletion
                  ? HugeIcons.strokeRoundedDelete02
                  : HugeIcons.strokeRoundedPauseCircle,
              color: themeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  widget.branchName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isDeletion) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Período de gracia: La sucursal se pausará por 7 días. Si no cancelas la solicitud dentro de ese lapso, se dará de baja definitivamente.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF991B1B),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.visibility_off_outlined,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Al desactivar tu tienda, esta y todos sus artículos quedarán ocultos al público en la app de compras. Los clientes no podrán ver tus productos ni hacer pedidos hasta que decidas reactivarla.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              'Ingresa el código OTP de 6 dígitos enviado a:',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 4),
            Text(
              widget.initialEmail,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: TextStyle(
                  color: Colors.grey.shade300,
                  letterSpacing: 10,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: themeColor, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _secondsLeft == 0 && !_isLoading ? _handleResendOtp : null,
                child: Text(
                  _secondsLeft > 0
                      ? 'Reenviar código en ${_secondsLeft}s'
                      : 'Reenviar código OTP',
                  style: TextStyle(
                    fontSize: 12,
                    color: _secondsLeft == 0 ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Color(0xFF475569)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isDeletion ? 'Eliminar' : 'Desactivar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


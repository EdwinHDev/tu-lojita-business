import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String registrationToken;
  final String email;

  const VerifyOtpScreen({
    super.key,
    required this.registrationToken,
    required this.email,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  late String _currentToken;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isVerifying = false;
  bool _isResending = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  final Color _primaryColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    _currentToken = widget.registrationToken;
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      NotificationService.showError(
        context,
        'Por favor ingresa los 6 dígitos del código de verificación.',
      );
      return;
    }

    setState(() => _isVerifying = true);

    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.verifyRegistrationOtp(
      registrationToken: _currentToken,
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (success) {
      NotificationService.showSuccess(context, '¡Cuenta verificada y creada con éxito!');
      // The router redirect will handle routing to /onboarding/company or /dashboard
    } else {
      final authState = ref.read(authProvider);
      final errorMsg = authState is AuthError
          ? authState.message
          : 'El código de verificación es incorrecto o ha expirado.';
      NotificationService.showError(context, errorMsg);
    }
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() => _isResending = true);

    final authNotifier = ref.read(authProvider.notifier);
    final newToken = await authNotifier.resendRegistrationOtp(
      registrationToken: _currentToken,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (newToken != null) {
      _currentToken = newToken;
      _otpController.clear();
      _startTimer();
      NotificationService.showSuccess(
        context,
        'Hemos reenviado un nuevo código de verificación a tu correo.',
      );
    } else {
      final authState = ref.read(authProvider);
      final errorMsg = authState is AuthError
          ? authState.message
          : 'No pudimos reenviar el código. Intenta de nuevo.';
      NotificationService.showError(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verifica tu correo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Ingresa el código de 6 dígitos que enviamos a tu correo corporativo:\n',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // PIN Display & Input
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Invisible TextFormField handling focus, digits, paste
                    Opacity(
                      opacity: 0.0,
                      child: TextField(
                        controller: _otpController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (val) {
                          setState(() {});
                          if (val.length == 6) {
                            _handleVerify();
                          }
                        },
                      ),
                    ),
                    // 6 Visual Pin Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final text = _otpController.text;
                        final isFilled = index < text.length;
                        final isFocused = _focusNode.hasFocus &&
                            (index == text.length || (index == 5 && text.length == 6));
                        final char = isFilled ? text[index] : '';

                        return Container(
                          width: 48,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isFilled
                                ? const Color(0xFFF8FAFC)
                                : isFocused
                                    ? Colors.white
                                    : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFocused
                                  ? _primaryColor
                                  : isFilled
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFFE5E7EB),
                              width: isFocused ? 2.0 : 1.2,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: _primaryColor.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            char,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verificar cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Resend code countdown / action
              Center(
                child: _secondsRemaining > 0
                    ? Text(
                        'Reenviar código en 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : TextButton(
                        onPressed: _isResending ? null : _handleResend,
                        child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Reenviar código',
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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

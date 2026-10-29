import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
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
  late String _currentEmail;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isVerifying = false;
  bool _isResending = false;

  late DateTime _expiresAt;
  late DateTime _resendAvailableAt;
  int _validitySecondsRemaining = 600;
  int _resendCooldownRemaining = 60;
  Timer? _timer;

  final Color _primaryColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    _currentToken = widget.registrationToken;
    _currentEmail = widget.email;
    _expiresAt = DateTime.now().add(const Duration(minutes: 10));
    _resendAvailableAt = DateTime.now().add(const Duration(seconds: 60));
    _initSessionAndTimer();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _handlePasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final rawText = data?.text?.trim() ?? '';
      if (rawText.isEmpty) {
        if (!mounted) return;
        NotificationService.showError(
          context,
          'El portapapeles está vacío. Copia el código desde tu correo.',
        );
        return;
      }

      // Check for 6 isolated consecutive digits \b\d{6}\b
      final regexMatch = RegExp(r'\b\d{6}\b').firstMatch(rawText);
      String? cleanOtp;
      if (regexMatch != null) {
        cleanOtp = regexMatch.group(0);
      } else {
        final onlyDigits = rawText.replaceAll(RegExp(r'\D'), '');
        if (onlyDigits.length >= 6) {
          cleanOtp = onlyDigits.substring(0, 6);
        }
      }

      if (cleanOtp != null && cleanOtp.length == 6) {
        HapticFeedback.mediumImpact();
        _otpController.text = cleanOtp;
        setState(() {});
        if (!mounted) return;
        NotificationService.showSuccess(
          context,
          'Código $cleanOtp pegado con éxito.',
        );
        _handleVerify();
      } else {
        if (!mounted) return;
        NotificationService.showError(
          context,
          'No se encontró un código de 6 dígitos en el portapapeles.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        'No se pudo acceder al portapapeles. Intenta ingresarlo manualmente.',
      );
    }
  }

  Future<void> _initSessionAndTimer() async {
    final localAuth = ref.read(localAuthDataSourceProvider);
    final pending = await localAuth.getPendingRegistration();

    if (_currentToken.isEmpty && pending != null) {
      _currentToken = pending['registrationToken'] as String? ?? '';
      _currentEmail = pending['email'] as String? ?? '';
    }

    if (pending != null && pending['expiresAt'] != null) {
      _expiresAt = pending['expiresAt'] as DateTime;
    } else {
      _expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await localAuth.savePendingRegistration(
        registrationToken: _currentToken,
        email: _currentEmail,
        expiresAt: _expiresAt,
      );
    }

    _resendAvailableAt = DateTime.now().add(const Duration(seconds: 60));
    _startTimer();
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
    _updateRemainingSeconds();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRemainingSeconds();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateRemainingSeconds() {
    final now = DateTime.now();
    final validityDiff = _expiresAt.difference(now).inSeconds;
    final resendDiff = _resendAvailableAt.difference(now).inSeconds;

    setState(() {
      _validitySecondsRemaining = validityDiff > 0 ? validityDiff : 0;
      _resendCooldownRemaining = resendDiff > 0 ? resendDiff : 0;
    });

    if (_validitySecondsRemaining <= 0 && _resendCooldownRemaining <= 0) {
      _timer?.cancel();
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handleBack() async {
    final localAuth = ref.read(localAuthDataSourceProvider);
    await localAuth.clearPendingRegistration();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/register');
    }
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
      final localAuth = ref.read(localAuthDataSourceProvider);
      await localAuth.clearPendingRegistration();
      if (!mounted) return;

      NotificationService.showSuccess(context, '¡Cuenta verificada y creada con éxito!');
      // Router redirect automatically navigates to /onboarding/company or /dashboard
    } else {
      final authState = ref.read(authProvider);
      final errorMsg = authState is AuthError
          ? authState.message
          : 'El código de verificación es incorrecto o ha expirado.';
      NotificationService.showError(context, errorMsg);
    }
  }

  Future<void> _handleResend() async {
    if (_resendCooldownRemaining > 0 || _isResending) return;

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
      _expiresAt = DateTime.now().add(const Duration(minutes: 10));
      _resendAvailableAt = DateTime.now().add(const Duration(seconds: 60));

      final localAuth = ref.read(localAuthDataSourceProvider);
      await localAuth.savePendingRegistration(
        registrationToken: newToken,
        email: _currentEmail,
        expiresAt: _expiresAt,
      );
      if (!mounted) return;

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
          onPressed: _handleBack,
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
                      text: 'Ingresa el código de 6 dígitos que enviamos a tu correo electrónico:\n',
                    ),
                    TextSpan(
                      text: _currentEmail.isNotEmpty ? _currentEmail : widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Colors.indigo),
                    const SizedBox(width: 6),
                    Text(
                      _validitySecondsRemaining > 0
                          ? 'Código válido por 10 min (vence en ${_formatTime(_validitySecondsRemaining)})'
                          : 'El código ha vencido. Solicita uno nuevo.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3730A3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // PIN Display & Input (Interactive top TextField with non-blocking visual boxes)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _otpController.selection = TextSelection.collapsed(
                    offset: _otpController.text.length,
                  );
                  if (!_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  }
                  SystemChannels.textInput.invokeMethod('TextInput.show');
                  setState(() {});
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Interactive TextField underneath to receive software keyboard events
                    Positioned.fill(
                      child: TextField(
                        controller: _otpController,
                        focusNode: _focusNode,
                        selectAllOnFocus: false,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        enableInteractiveSelection: true,
                        showCursor: false,
                        cursorColor: Colors.transparent,
                        style: const TextStyle(
                          color: Colors.transparent,
                          fontSize: 22,
                          letterSpacing: 0,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        contextMenuBuilder: (context, editableTextState) {
                          return AdaptiveTextSelectionToolbar.editableText(
                            editableTextState: editableTextState,
                          );
                        },
                        onTap: () {
                          SystemChannels.textInput.invokeMethod('TextInput.show');
                        },
                        onChanged: (val) {
                          setState(() {});
                          if (val.length == 6) {
                            _handleVerify();
                          }
                        },
                      ),
                    ),

                    // 2. Visual & Tappable PIN Boxes on top
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final text = _otpController.text;
                        final isFilled = index < text.length;
                        final currentOffset = _otpController.selection.isValid
                            ? _otpController.selection.extentOffset
                            : text.length;
                        final isFocused = _focusNode.hasFocus &&
                            (currentOffset == index ||
                                (index == 5 && currentOffset >= 6) ||
                                (text.isEmpty && index == 0));
                        final char = isFilled ? text[index] : '';

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final targetOffset = index.clamp(0, text.length);
                            _otpController.selection = TextSelection.collapsed(offset: targetOffset);
                            if (!_focusNode.hasFocus) {
                              _focusNode.requestFocus();
                            }
                            SystemChannels.textInput.invokeMethod('TextInput.show');
                            setState(() {});
                          },
                          child: Container(
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
                                        color: _primaryColor.withValues(alpha: 0.20),
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
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // One-Touch "Pegar código" Quick Action Button
              Center(
                child: OutlinedButton.icon(
                  onPressed: _isVerifying ? null : _handlePasteFromClipboard,
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: const Text(
                    'Pegar código del portapapeles',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: BorderSide(
                      color: _primaryColor.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: const Color(0xFFEEF2FF),
                  ),
                ),
              ),

              const SizedBox(height: 24),

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
                child: _resendCooldownRemaining > 0
                    ? Text(
                        '¿No recibiste el código? Podrás solicitar otro en 00:${_resendCooldownRemaining.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: _isResending ? null : _handleResend,
                        icon: _isResending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(
                          'Reenviar código a mi correo',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryColor,
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

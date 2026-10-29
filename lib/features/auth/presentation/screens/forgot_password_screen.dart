import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/utils/safe_text_controller.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';

/// Pantalla para solicitar y verificar el código OTP de recuperación de contraseña en Tu Lojita Empresa.
/// Paso 1 del flujo de recuperación en dos pasos.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail,
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _codeSent = false;
  bool _isLoading = false;
  bool _isResending = false;
  String? _recoveryToken;

  late DateTime _expiresAt;
  late DateTime _resendAvailableAt;
  int _validitySecondsRemaining = 600;
  int _resendCooldownRemaining = 60;
  Timer? _timer;

  final Color _primaryColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.safeSetText(widget.initialEmail!);
    }
    _expiresAt = DateTime.now().add(const Duration(minutes: 10));
    _resendAvailableAt = DateTime.now().add(const Duration(seconds: 60));
    _otpFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
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

  Future<void> _handleRequestOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      final token = await ref
          .read(authProvider.notifier)
          .requestForgotPasswordOtp(email);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (token != null && token.isNotEmpty) {
        _recoveryToken = token;
        _codeSent = true;
        _expiresAt = DateTime.now().add(const Duration(minutes: 10));
        _resendAvailableAt = DateTime.now().add(const Duration(seconds: 60));
        _startTimer();
        NotificationService.showSuccess(
          context,
          'Código enviado. Revisa tu bandeja de entrada o spam.',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _otpFocusNode.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.show');
        });
      } else {
        NotificationService.showInfo(
          context,
          'Si el correo está registrado, recibirás un código de recuperación.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      NotificationService.showError(
        context,
        'No se pudo enviar el código. Intenta de nuevo.',
      );
    }
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
        _otpController.selection = TextSelection.collapsed(offset: cleanOtp.length);
        setState(() {});
        if (!mounted) return;
        NotificationService.showSuccess(
          context,
          'Código $cleanOtp pegado con éxito.',
        );
        _handleVerifyOtp();
      } else {
        if (!mounted) return;
        NotificationService.showError(
          context,
          'No se encontró un código de 6 dígitos en el portapapeles.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        'No se pudo acceder al portapapeles.',
      );
    }
  }

  Future<void> _handleResendOtp() async {
    if (_recoveryToken == null || _resendCooldownRemaining > 0) return;

    setState(() => _isResending = true);
    try {
      final newToken = await ref
          .read(authProvider.notifier)
          .resendForgotPasswordOtp(_recoveryToken!);

      if (!mounted) return;
      setState(() => _isResending = false);

      if (newToken != null && newToken.isNotEmpty) {
        _recoveryToken = newToken;
        _expiresAt = DateTime.now().add(const Duration(minutes: 10));
        _resendAvailableAt = DateTime.now().add(const Duration(seconds: 60));
        _startTimer();
        NotificationService.showSuccess(
          context,
          'Nuevo código enviado a tu correo.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);
      NotificationService.showError(
        context,
        'No se pudo reenviar el código.',
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      NotificationService.showError(
        context,
        'Por favor ingresa los 6 dígitos del código.',
      );
      return;
    }

    if (_recoveryToken == null) {
      NotificationService.showError(
        context,
        'Sesión no válida. Por favor solicita el código nuevamente.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resetSessionToken = await ref
          .read(authProvider.notifier)
          .verifyForgotPasswordOtp(
            recoveryToken: _recoveryToken!,
            otp: otp,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (resetSessionToken != null && resetSessionToken.isNotEmpty) {
        context.push(
          '/reset-password',
          extra: {
            'resetSessionToken': resetSessionToken,
            'email': _emailController.text.trim(),
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      NotificationService.showError(
        context,
        'El código es incorrecto o ha expirado.',
      );
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            if (_codeSent) {
              setState(() {
                _codeSent = false;
                _timer?.cancel();
                _otpController.clear();
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: _codeSent ? _buildOtpVerificationView() : _buildEmailRequestView(),
        ),
      ),
    );
  }

  Widget _buildEmailRequestView() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedLockPassword,
                color: _primaryColor,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recuperar Contraseña',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa el correo electrónico comercial asociado a tu cuenta para recibir un código de recuperación de 6 dígitos.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Correo electrónico',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            selectAllOnFocus: false,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'comercio@ejemplo.com',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedMail01,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa tu correo electrónico';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Ingresa un correo electrónico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRequestOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Enviar Código de Recuperación',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationView() {
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedMail01,
              color: Color(0xFFD97706),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Introduce el Código',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Hemos enviado un código de 6 dígitos a ',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            children: [
              TextSpan(
                text: email,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const TextSpan(text: '. Ingresa el código a continuación:'),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ─── Temporizador y Estado ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _validitySecondsRemaining > 0
                ? const Color(0xFFF8FAFC)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _validitySecondsRemaining > 0
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFFCA5A5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 20,
                color: _validitySecondsRemaining > 0
                    ? const Color(0xFF64748B)
                    : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _validitySecondsRemaining > 0
                      ? 'Código válido durante: ${_formatTime(_validitySecondsRemaining)}'
                      : 'El código ha expirado. Solicita uno nuevo.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _validitySecondsRemaining > 0
                        ? const Color(0xFF334155)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ─── Input Visual e Interactivo de 6 Dígitos ───
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _otpController.selection = TextSelection.collapsed(
              offset: _otpController.text.length,
            );
            if (!_otpFocusNode.hasFocus) {
              _otpFocusNode.requestFocus();
            }
            SystemChannels.textInput.invokeMethod('TextInput.show');
            setState(() {});
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. TextField Interactivo superpuesto para recibir eventos de teclado
              Positioned.fill(
                child: TextField(
                  controller: _otpController,
                  focusNode: _otpFocusNode,
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
                      _handleVerifyOtp();
                    }
                  },
                ),
              ),

              // 2. Cajas Visuales Táctiles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final text = _otpController.text;
                  final isFilled = index < text.length;
                  final currentOffset = _otpController.selection.isValid
                      ? _otpController.selection.extentOffset
                      : text.length;
                  final isFocused = _otpFocusNode.hasFocus &&
                      (currentOffset == index ||
                          (index == 5 && currentOffset >= 6) ||
                          (text.isEmpty && index == 0));
                  final char = isFilled ? text[index] : '';

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final targetOffset = index.clamp(0, text.length);
                      _otpController.selection = TextSelection.collapsed(offset: targetOffset);
                      if (!_otpFocusNode.hasFocus) {
                        _otpFocusNode.requestFocus();
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

        // Botón Acción Rápida: Pegar desde portapapeles
        Center(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handlePasteFromClipboard,
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

        // Botón Verificar
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Verificar Código',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // Botón Reenviar
        Center(
          child: TextButton(
            onPressed: (_resendCooldownRemaining > 0 || _isResending)
                ? null
                : _handleResendOtp,
            child: _isResending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _resendCooldownRemaining > 0
                        ? 'Reenviar código en ${_resendCooldownRemaining}s'
                        : '¿No recibiste el código? Reenviar',
                    style: TextStyle(
                      color: _resendCooldownRemaining > 0
                          ? Colors.grey.shade500
                          : _primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

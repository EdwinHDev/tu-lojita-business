import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const LoginScreen({
    super.key,
    this.initialEmail,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _accessIdController = TextEditingController();
  final _collabPasswordController = TextEditingController();

  bool _isCollaborator = false;
  bool _obscurePassword = true;
  bool _obscureCollabPassword = true;
  bool _isLoading = false;

  final Color _primaryColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _accessIdController.dispose();
    _collabPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isCollaborator) {
      await _submitCollaborator();
    } else {
      await _submitOwner();
    }
  }

  Future<void> _submitCollaborator() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final accessId = _accessIdController.text.trim();
    final password = _collabPasswordController.text;

    final authNotifier = ref.read(authProvider.notifier);
    final success =
        await authNotifier.loginWithCollaborator(accessId, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      final authState = ref.read(authProvider);
      final errorMsg = authState is AuthError
          ? authState.message
          : 'Credenciales inválidas. Revisa tu ID de 8 dígitos y contraseña.';
      NotificationService.showError(context, errorMsg);
    }
  }

  Future<void> _submitOwner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.loginWithCredentials(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final authState = ref.read(authProvider);
      if (authState is Authenticated && authState.user.isAccountSuspended) {
        context.go(
          '/account-suspended',
          extra: {
            'suspendedUntil': authState.user.accountSuspendedUntil?.toIso8601String(),
            'reason': authState.user.accountSuspensionReason,
          },
        );
      }
    } else {
      final authState = ref.read(authProvider);
      if (authState is AuthError &&
          (authState.code == 'ACCOUNT_SUSPENDED' ||
              authState.code == 'ACCOUNT_BANNED' ||
              authState.message.toLowerCase().contains('suspendida'))) {
        context.go(
          '/account-suspended',
          extra: {
            'reason': authState.message,
          },
        );
        return;
      }
      final errorMsg = authState is AuthError
          ? authState.message
          : 'Las credenciales ingresadas no son válidas.';
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa a tu cuenta para administrar tu empresa y tiendas.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Segmented Selector (Empresa / Colaborador)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (_isCollaborator) {
                              setState(() => _isCollaborator = false);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isCollaborator
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !_isCollaborator
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business_outlined,
                                  size: 16,
                                  color: !_isCollaborator
                                      ? _primaryColor
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Empresa',
                                  style: TextStyle(
                                    fontWeight: !_isCollaborator
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: !_isCollaborator
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF64748B),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (!_isCollaborator) {
                              setState(() => _isCollaborator = true);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isCollaborator
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _isCollaborator
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.badge_outlined,
                                  size: 16,
                                  color: _isCollaborator
                                      ? _primaryColor
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Colaborador',
                                  style: TextStyle(
                                    fontWeight: _isCollaborator
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: _isCollaborator
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF64748B),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (!_isCollaborator) ...[
                  // Email Field
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
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'empresa@correo.com',
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
                      if (_isCollaborator) return null;
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
                  const SizedBox(height: 20),

                  // Password Field
                  const Text(
                    'Contraseña',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedLockPassword,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF6B7280),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                      if (_isCollaborator) return null;
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Olvidé mi contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.push(
                          '/forgot-password',
                          extra: {'initialEmail': _emailController.text.trim()},
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Collaborator Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ingresa con el ID de 8 dígitos y la contraseña asignada por tu empleador.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E40AF),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ID de Acceso Field
                  const Text(
                    'ID de Acceso (8 dígitos)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _accessIdController,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Ej. 82345678',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(
                          Icons.badge_outlined,
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
                      if (!_isCollaborator) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu ID de acceso';
                      }
                      final trimmed = value.trim();
                      if (trimmed.length != 8 || int.tryParse(trimmed) == null) {
                        return 'El ID debe tener exactamente 8 dígitos numéricos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Collaborator Password Field
                  const Text(
                    'Contraseña',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _collabPasswordController,
                    obscureText: _obscureCollabPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Contraseña de 8 caracteres',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedLockPassword,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCollabPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF6B7280),
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscureCollabPassword = !_obscureCollabPassword),
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
                      if (!_isCollaborator) return null;
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (value.length < 8) {
                        return 'La contraseña debe tener al menos 8 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Si no recuerdas tu ID o contraseña, contacta al propietario de tu empresa.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
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
                        : Text(
                            _isCollaborator
                                ? 'Ingresar como Colaborador'
                                : 'Iniciar Sesión',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                if (!_isCollaborator)
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Deseas afiliar tu empresa? ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.pushReplacement('/register');
                        },
                        child: Text(
                          'Crear cuenta',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

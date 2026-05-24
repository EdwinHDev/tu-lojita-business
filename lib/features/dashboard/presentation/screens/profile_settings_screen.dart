import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/profile_settings_notifier.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _identificationController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _initialIdentification = '';
  String _initialPhone = '';
  bool _isDirty = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      _initialIdentification = authState.user.identification ?? '';
      _initialPhone = authState.user.phone ?? '';
      
      _identificationController.text = _initialIdentification;
      _phoneController.text = _initialPhone;
    }

    _identificationController.addListener(_onFormChange);
    _phoneController.addListener(_onFormChange);
  }

  @override
  void dispose() {
    _identificationController.removeListener(_onFormChange);
    _phoneController.removeListener(_onFormChange);
    _identificationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFormChange() {
    final identification = _identificationController.text.trim();
    final phone = _phoneController.text.trim();
    
    // Check if the form is dirty
    final dirty = identification != _initialIdentification || phone != _initialPhone;
    
    // Validate inputs
    String? validationMsg;
    if (identification.isNotEmpty && identification.length < 6) {
      validationMsg = 'La identificación debe tener al menos 6 caracteres';
    } else if (phone.isNotEmpty && phone.length < 10) {
      validationMsg = 'El teléfono debe tener al menos 10 caracteres';
    }

    setState(() {
      _isDirty = dirty;
      _validationError = validationMsg;
    });
  }

  Future<void> _save() async {
    // Prevent double submission or invalid forms
    if (_validationError != null || !_isDirty) return;

    final success = await ref.read(profileSettingsProvider.notifier).updateProfile(
          identification: _identificationController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      _initialIdentification = _identificationController.text.trim();
      _initialPhone = _phoneController.text.trim();
      _onFormChange(); // recalculate dirty and validation states
      NotificationService.showSuccess(context, 'Perfil actualizado correctamente');
    } else {
      final errorMsg = ref.read(profileSettingsProvider).error ?? 'Error al actualizar el perfil';
      NotificationService.showError(context, errorMsg);
    }
  }

  String _translateRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'COMPANY':
        return 'Empresa';
      case 'VENDOR':
        return 'Vendedor';
      case 'DELIVERY':
        return 'Repartidor';
      case 'USER':
        return 'Cliente';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileSettingsProvider);

    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Color(0xFF111827),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Account Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // User Avatar
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                    ),
                    child: ClipOval(
                      child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? Image.network(
                              user.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(user.firstName),
                            )
                          : _buildInitialsAvatar(user.firstName),
                    ),
                  ),
                  const SizedBox(width: 18),
                  // User Details Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _translateRole(user.role),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Profile Input Card
            Card(
              elevation: 0,
              color: Colors.indigo.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedIdentityCard,
                          color: Colors.indigo,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Detalles de Contacto',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Identification Field
                    TextField(
                      controller: _identificationController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Identificación (DNI / Cédula)',
                        hintText: 'Ej. V12345678',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedIdentityCard,
                            color: Colors.indigo,
                            size: 20,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    
                    // Phone Field
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Teléfono de Contacto',
                        hintText: 'Ej. 04125556677',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSmartPhone01,
                            color: Colors.indigo,
                            size: 20,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Validation Warning Message
            if (_validationError != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
                ),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedAlertCircle,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // Submit Button
            ElevatedButton(
              onPressed: (_isDirty && _validationError == null && !profileState.isLoading)
                  ? _save
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: _isDirty ? 3 : 0,
              ),
              child: profileState.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Guardar Cambios',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Container(
      color: Colors.indigo.shade800,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

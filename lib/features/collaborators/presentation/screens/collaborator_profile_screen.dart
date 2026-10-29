import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';

class CollaboratorProfileScreen extends ConsumerWidget {
  const CollaboratorProfileScreen({super.key});

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cambiar Contraseña'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña Actual *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva Contraseña *',
                      hintText: 'Mínimo 8 caracteres alfanuméricos',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (v.length < 8) return 'Mínimo 8 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Contraseña *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v != newPasswordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isSaving = true);
                      try {
                        await ref
                            .read(authProvider.notifier)
                            .changeCollaboratorPassword(
                              currentPassword: currentPasswordController.text,
                              newPassword: newPasswordController.text,
                            );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          NotificationService.showSuccess(
                            context,
                            'Contraseña actualizada exitosamente',
                          );
                        }
                      } catch (e) {
                        setState(() => isSaving = false);
                        if (context.mounted) {
                          NotificationService.showError(
                            context,
                            e.toString().replaceAll('AuthException: ', ''),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mi Perfil de Colaborador'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tu identidad, rol y sucursales autorizadas son administrados directamente por la empresa. Solo puedes actualizar tu contraseña de acceso.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E40AF),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Identity card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      context,
                      label: 'ID de Acceso',
                      value: user.accessId ?? 'No asignado',
                      canCopy: user.accessId != null,
                      valueColor: const Color(0xFF4F46E5),
                      isBold: true,
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      context,
                      label: 'Nombre Completo',
                      value: user.fullName,
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      context,
                      label: 'Cédula / Documento',
                      value: user.identification ?? 'No registrado',
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      context,
                      label: 'Teléfono',
                      value: user.phone ?? 'No registrado',
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      context,
                      label: 'Rol Asignado',
                      value: user.collaboratorRole ?? 'Colaborador',
                      valueColor: const Color(0xFF0F172A),
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Branch access card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 20,
                          color: Color(0xFF4F46E5),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sucursales Autorizadas',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (user.hasFullBranchAccess)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Acceso completo a todas las sucursales de la empresa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      )
                    else if (user.allowedBranchIds.isEmpty)
                      const Text(
                        'Sin sucursales asignadas activas.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.allowedBranchIds.map((id) {
                          return Chip(
                            backgroundColor: const Color(0xFFEEF2FF),
                            label: Text(
                              'Sucursal ID: $id',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Change password button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _showChangePasswordDialog(context, ref),
                  icon: const Icon(Icons.lock_outline, size: 20),
                  label: const Text(
                    'Cambiar Mi Contraseña',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    bool canCopy = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? const Color(0xFF1E293B),
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  NotificationService.showSuccess(
                    context,
                    '$label copiado al portapapeles',
                  );
                },
                child: const Icon(
                  Icons.copy,
                  size: 16,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/business_change_password_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final isCredentialUser = user?.isCredentialUser ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Cuenta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const SizedBox(height: 16),
          if (user?.isCollaborator == true) ...[
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Colors.indigo),
              title: const Text('Mi Perfil de Colaborador'),
              subtitle: Text(user?.collaboratorRole ?? 'Datos de acceso y sucursales'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/dashboard/settings/collaborator-profile'),
            ),
            if (user?.hasPermission('collaborators:view') == true ||
                user?.hasPermission('roles:manage') == true)
              ListTile(
                leading: const HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, color: Colors.indigo),
                title: const Text('Equipo y Roles'),
                subtitle: const Text('Gestión de personal y permisos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/dashboard/settings/team'),
              ),
            if (user?.hasPermission('settings:manage') == true)
              ListTile(
                leading: const HugeIcon(icon: HugeIcons.strokeRoundedStore01, color: Colors.indigo),
                title: const Text('Mi Empresa'),
                subtitle: const Text('Gestionar identidad corporativa'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/dashboard/settings/company'),
              ),
          ] else ...[
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Colors.indigo),
              title: const Text('Mi Perfil'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/dashboard/settings/profile'),
            ),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedStore01, color: Colors.indigo),
              title: const Text('Mi Empresa'),
              subtitle: const Text('Gestionar identidad corporativa'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/dashboard/settings/company'),
            ),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, color: Colors.indigo),
              title: const Text('Equipo y Roles'),
              subtitle: const Text('Colaboradores, roles y permisos de sucursales'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/dashboard/settings/team'),
            ),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedTime04, color: Colors.indigo),
              title: const Text('Historial de Actividades'),
              subtitle: const Text('Auditoría de operaciones del equipo y sucursales'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/dashboard/settings/activity-log'),
            ),
          ],
          if (isCredentialUser && user?.isCollaborator != true)
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedLockPassword, color: Colors.indigo),
              title: const Text('Cambiar Contraseña'),
              subtitle: const Text('Actualiza tus credenciales de acceso'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => BusinessChangePasswordDialog.show(context),
            ),
          const Divider(),
          ListTile(
            leading: const HugeIcon(icon: HugeIcons.strokeRoundedLogout01, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

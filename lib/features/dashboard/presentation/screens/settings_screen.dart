import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Cuenta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const SizedBox(height: 16),
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

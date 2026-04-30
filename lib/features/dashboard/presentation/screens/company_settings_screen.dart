import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final _nameController = TextEditingController();
  String _initialName = '';
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    if (authState is Authenticated && authState.user.company != null) {
      _initialName = authState.user.company!.name;
      _nameController.text = _initialName;
    }

    _nameController.addListener(_checkDirty);
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkDirty);
    _nameController.dispose();
    super.dispose();
  }

  void _checkDirty() {
    setState(() {
      _isDirty = _nameController.text != _initialName;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) return;

    final authState = ref.read(authProvider);
    if (authState is! Authenticated || authState.user.company == null) return;

    final success = await ref.read(companyOnboardingProvider.notifier).updateCompanyName(
          companyId: authState.user.company!.id,
          newName: _nameController.text,
        );

    if (success) {
      _initialName = _nameController.text;
      _checkDirty();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empresa actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      // Actualizar el estado global del usuario de forma silenciosa para evitar redirecciones
      await ref.read(authProvider.notifier).silentRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyOnboardingProvider);
    final authState = ref.watch(authProvider);

    Company? company;
    if (authState is Authenticated) {
      company = authState.user.company;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Empresa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (company?.logo != null)
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.indigo.shade100, width: 4),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      company!.logo.startsWith('http') 
                        ? company.logo 
                        : '${Envs.apiBaseUrlImages}/${company.logo.startsWith('/') ? company.logo.substring(1) : company.logo}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedStore01,
                          size: 60,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              color: Colors.indigo.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, color: Colors.indigo, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Información de Identidad',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la Empresa',
                        hintText: 'Ej. Inversiones El Éxito',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: HugeIcon(icon: HugeIcons.strokeRoundedStore01, color: Colors.indigo, size: 20),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: TextEditingController(text: company?.rif ?? ''),
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'RIF (Lectura)',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, color: Colors.grey, size: 20),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Nota: El RIF y el Logo son parte de tu identidad fiscal y no pueden ser modificados desde aquí por seguridad.',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: (_isDirty && !state.isLoading) ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
              ),
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Guardar Cambios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

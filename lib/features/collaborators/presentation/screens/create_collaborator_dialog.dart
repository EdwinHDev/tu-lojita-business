import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import '../../domain/entities/collaborator.dart';
import '../providers/collaborators_providers.dart';

class CreateCollaboratorDialog extends ConsumerStatefulWidget {
  const CreateCollaboratorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateCollaboratorDialog(),
    );
  }

  @override
  ConsumerState<CreateCollaboratorDialog> createState() =>
      _CreateCollaboratorDialogState();
}

class _CreateCollaboratorDialogState
    extends ConsumerState<CreateCollaboratorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedRoleId;
  bool _hasFullBranchAccess = true;
  final Set<String> _selectedStoreIds = {};
  bool _isSubmitting = false;

  Collaborator? _createdCollaborator;
  String? _createdInitialPassword;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoleId == null) {
      NotificationService.showError(
        context,
        'Debes seleccionar un rol para el colaborador.',
      );
      return;
    }

    if (!_hasFullBranchAccess && _selectedStoreIds.isEmpty) {
      NotificationService.showError(
        context,
        'Debes asignar al menos una sucursal al colaborador.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await ref
          .read(collaboratorsNotifierProvider.notifier)
          .createCollaborator(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            identification: _idController.text.trim(),
            phone: _phoneController.text.trim(),
            roleId: _selectedRoleId!,
            hasFullBranchAccess: _hasFullBranchAccess,
            storeIds: _hasFullBranchAccess ? [] : _selectedStoreIds.toList(),
          );

      if (!mounted) return;
      setState(() {
        _createdCollaborator = result['collaborator'] as Collaborator;
        _createdInitialPassword =
            result['generatedInitialPassword']?.toString() ??
                _createdCollaborator?.initialPassword;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      NotificationService.showError(
        context,
        'Error al crear colaborador: ${e.toString()}',
      );
    }
  }

  void _copyCredentials() {
    if (_createdCollaborator == null) return;
    final authState = ref.read(authProvider);
    final companyName = (authState is Authenticated)
        ? (authState.user.company?.name ?? 'la empresa')
        : 'la empresa';

    final pass = _createdInitialPassword ??
        _createdCollaborator!.initialPassword ??
        '';

    final text = '''
¡Hola ${_createdCollaborator!.firstName}! Has sido registrado como colaborador en $companyName.

🔑 ID de Acceso (8 dígitos): ${_createdCollaborator!.accessId}
🔒 Contraseña Temporal: $pass

Para ingresar:
1. Abre la app Tu Lojita Empresa
2. Selecciona "Ingresar como Colaborador"
3. Coloca tu ID de 8 dígitos y tu contraseña.
''';

    Clipboard.setData(ClipboardData(text: text.trim()));
    NotificationService.showSuccess(
      context,
      'Credenciales copiadas al portapapeles',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
      ),
      child: _createdCollaborator != null
          ? _buildSuccessView()
          : _buildFormView(),
    );
  }

  Widget _buildSuccessView() {
    final collab = _createdCollaborator!;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF059669),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Colaborador Registrado!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${collab.fullName} ya puede iniciar sesión en la app.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Credentials card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ID de Acceso (8 dígitos):',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      collab.accessId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Contraseña Inicial:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _createdInitialPassword ??
                          collab.initialPassword ??
                          '********',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Copia estas credenciales y compártelas con el colaborador de forma segura por WhatsApp o SMS.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyCredentials,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar Credenciales'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFF4F46E5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Listo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    final rolesState = ref.watch(rolesNotifierProvider);
    final storesState = ref.watch(storesProvider);

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nuevo Colaborador',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nombres y Apellidos
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Requerido'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Requerido'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Cédula e Identificación
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cédula / ID *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().length < 6
                        ? 'Mínimo 6 dígitos'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Requerido'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Rol Selector
            if (rolesState.isLoading && rolesState.roles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (rolesState.roles.isEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'No hay roles disponibles',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Debes tener al menos un rol antes de registrar un colaborador.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F1D1D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 20,
                        color: Color(0xFFDC2626),
                      ),
                      tooltip: 'Recargar roles',
                      onPressed: () =>
                          ref.read(rolesNotifierProvider.notifier).loadRoles(),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedRoleId ??
                    (rolesState.roles.any((r) => r.isSystemDefault)
                        ? rolesState.roles.firstWhere((r) => r.isSystemDefault).id
                        : (rolesState.roles.isNotEmpty ? rolesState.roles.first.id : null)),
                decoration: const InputDecoration(
                  labelText: 'Rol Asignado *',
                  border: OutlineInputBorder(),
                ),
                items: rolesState.roles.map((r) {
                  return DropdownMenuItem(
                    value: r.id,
                    child: Text(
                      r.isSystemDefault ? '${r.name} (Predeterminado)' : r.name,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedRoleId = val);
                },
                validator: (v) => v == null ? 'Selecciona un rol' : null,
              ),
            const SizedBox(height: 16),

            // Sucursales
            const Text(
              'Acceso a Sucursales',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Acceso a todas las sucursales'),
              subtitle: const Text(
                'Permite al colaborador operar en cualquier sucursal actual o futura',
              ),
              value: _hasFullBranchAccess,
              activeThumbColor: const Color(0xFF4F46E5),
              onChanged: (val) {
                setState(() => _hasFullBranchAccess = val);
              },
            ),

            if (!_hasFullBranchAccess) ...[
              const SizedBox(height: 8),
              const Text(
                'Selecciona las sucursales autorizadas:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: storesState.stores.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final store = storesState.stores[i];
                    final isChecked = _selectedStoreIds.contains(store.id);

                    return CheckboxListTile(
                      dense: true,
                      value: isChecked,
                      activeColor: const Color(0xFF4F46E5),
                      title: Text(store.name),
                      subtitle: store.branchName != null &&
                              store.branchName!.isNotEmpty
                          ? Text('Sucursal: ${store.branchName}')
                          : null,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedStoreIds.add(store.id);
                          } else {
                            _selectedStoreIds.remove(store.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Generar Credenciales y Crear',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

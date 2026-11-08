import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/store_ai/presentation/providers/store_ai_providers.dart';
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
  final Set<String> _selectedAiStoreIds = {};
  bool _isSubmitting = false;

  Collaborator? _createdCollaborator;
  String? _createdInitialPassword;

  String? _resolveEffectiveRoleId(RolesState rolesState) {
    if (_selectedRoleId != null &&
        rolesState.roles.any((r) => r.id == _selectedRoleId)) {
      return _selectedRoleId;
    }
    if (rolesState.roles.any((r) => r.isSystemDefault)) {
      return rolesState.roles.firstWhere((r) => r.isSystemDefault).id;
    }
    return rolesState.roles.isNotEmpty ? rolesState.roles.first.id : null;
  }

  bool _roleHasInventoryEdit(RolesState rolesState, String? roleId) {
    if (roleId == null) return false;
    final role = rolesState.roles.where((r) => r.id == roleId).firstOrNull;
    return role?.permissions.contains('inventory:edit') == true;
  }

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

    final rolesState = ref.read(rolesNotifierProvider);
    final storesState = ref.read(storesProvider);
    final effectiveRoleId = _resolveEffectiveRoleId(rolesState);

    if (effectiveRoleId == null) {
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

    final isGlobalAiEnabled =
        ref.read(platformAiGlobalEnabledProvider).value ?? false;
    final hasInventoryEdit = _roleHasInventoryEdit(rolesState, effectiveRoleId);
    final effectiveAiStoreIds = (!isGlobalAiEnabled || !hasInventoryEdit)
        ? <String>[]
        : _selectedAiStoreIds
            .where((id) =>
                (_hasFullBranchAccess || _selectedStoreIds.contains(id)) &&
                storesState.stores.any((s) => s.id == id && s.aiEnabled))
            .toList();

    setState(() => _isSubmitting = true);

    try {
      final result = await ref
          .read(collaboratorsNotifierProvider.notifier)
          .createCollaborator(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            identification: _idController.text.trim(),
            phone: _phoneController.text.trim(),
            roleId: effectiveRoleId,
            hasFullBranchAccess: _hasFullBranchAccess,
            storeIds: _hasFullBranchAccess ? [] : _selectedStoreIds.toList(),
            aiAllowedStoreIds: effectiveAiStoreIds,
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
    final effectiveRoleId = _resolveEffectiveRoleId(rolesState);
    final isGlobalAiEnabled =
        ref.watch(platformAiGlobalEnabledProvider).value ?? false;
    final roleHasInventoryEdit =
        _roleHasInventoryEdit(rolesState, effectiveRoleId);

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
                initialValue: effectiveRoleId,
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

            if (_hasFullBranchAccess && roleHasInventoryEdit) ...[
              const SizedBox(height: 8),
              _buildFullAccessAiBranchesSection(storesState.stores,
                  isGlobalAiEnabled: isGlobalAiEnabled),
            ],

            if (!_hasFullBranchAccess) ...[
              const SizedBox(height: 8),
              const Text(
                'Selecciona las sucursales autorizadas:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
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

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckboxListTile(
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
                                _selectedAiStoreIds.remove(store.id);
                              }
                            });
                          },
                        ),
                        if (isChecked && roleHasInventoryEdit)
                          _buildAiSubBranchRow(store,
                              isGlobalAiEnabled: isGlobalAiEnabled),
                      ],
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

  Widget _buildFullAccessAiBranchesSection(
    List<Store> stores, {
    required bool isGlobalAiEnabled,
  }) {
    if (stores.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF7C3AED)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Permiso de Estudio IA por Sucursal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4C1D95),
                  ),
                ),
              ),
              if (!isGlobalAiEnabled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Text(
                    'No disponible',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            !isGlobalAiEnabled
                ? 'La funcionalidad de IA está temporalmente desactivada en la plataforma.'
                : 'El rol permite crear/editar artículos. Activa el uso de IA por sucursal:',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 190),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: stores.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final store = stores[index];
                final isAiActiveInStore = store.aiEnabled && isGlobalAiEnabled;
                final isAllowed =
                    isAiActiveInStore && _selectedAiStoreIds.contains(store.id);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isAiActiveInStore
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              !isGlobalAiEnabled
                                  ? 'Desactivado temporalmente en la plataforma'
                                  : (store.aiEnabled
                                      ? 'Puede mejorar fotos con IA'
                                      : 'IA no configurada o inactiva en esta sucursal'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isAiActiveInStore
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: !isGlobalAiEnabled
                            ? () => NotificationService.showError(
                                  context,
                                  'No puedes habilitar el Estudio IA en este momento porque la funcionalidad no está disponible actualmente en la plataforma.',
                                )
                            : null,
                        behavior: HitTestBehavior.opaque,
                        child: IgnorePointer(
                          ignoring: !isGlobalAiEnabled || !store.aiEnabled,
                          child: Switch.adaptive(
                            value: isAllowed,
                            activeTrackColor: const Color(0xFF7C3AED),
                            onChanged: (isAiActiveInStore && isGlobalAiEnabled)
                                ? (enabled) {
                                    setState(() {
                                      if (enabled) {
                                        _selectedAiStoreIds.add(store.id);
                                      } else {
                                        _selectedAiStoreIds.remove(store.id);
                                      }
                                    });
                                  }
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSubBranchRow(Store store, {required bool isGlobalAiEnabled}) {
    final isAiActiveInStore = store.aiEnabled && isGlobalAiEnabled;
    final isAllowed =
        isAiActiveInStore && _selectedAiStoreIds.contains(store.id);

    return Container(
      margin: const EdgeInsets.fromLTRB(36, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAiActiveInStore
            ? const Color(0xFFF5F3FF)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAiActiveInStore
              ? const Color(0xFFDDD6FE)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAiActiveInStore ? Icons.auto_awesome : Icons.lock_outline,
            size: 15,
            color: isAiActiveInStore
                ? const Color(0xFF7C3AED)
                : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usar Estudio IA en esta sucursal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAiActiveInStore
                        ? const Color(0xFF4C1D95)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  !isGlobalAiEnabled
                      ? 'No disponible: IA desactivada temporalmente'
                      : (store.aiEnabled
                          ? 'Mejorar fotos de catálogo con IA'
                          : 'IA inactiva en esta sucursal (bloqueado)'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: !isGlobalAiEnabled
                ? () => NotificationService.showError(
                      context,
                      'No puedes habilitar el Estudio IA en este momento porque la funcionalidad no está disponible actualmente en la plataforma.',
                    )
                : null,
            behavior: HitTestBehavior.opaque,
            child: IgnorePointer(
              ignoring: !isGlobalAiEnabled || !store.aiEnabled,
              child: Switch.adaptive(
                value: isAllowed,
                activeTrackColor: const Color(0xFF7C3AED),
                onChanged: (isAiActiveInStore && isGlobalAiEnabled)
                    ? (enabled) {
                        setState(() {
                          if (enabled) {
                            _selectedAiStoreIds.add(store.id);
                          } else {
                            _selectedAiStoreIds.remove(store.id);
                          }
                        });
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

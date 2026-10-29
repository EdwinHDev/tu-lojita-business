import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import '../../domain/entities/collaborator.dart';
import '../providers/collaborators_providers.dart';

class EditCollaboratorDialog extends ConsumerStatefulWidget {
  final Collaborator collaborator;

  const EditCollaboratorDialog({
    super.key,
    required this.collaborator,
  });

  static Future<void> show(BuildContext context, {required Collaborator collaborator}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditCollaboratorDialog(collaborator: collaborator),
    );
  }

  @override
  ConsumerState<EditCollaboratorDialog> createState() =>
      _EditCollaboratorDialogState();
}

class _EditCollaboratorDialogState
    extends ConsumerState<EditCollaboratorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _idController;
  late final TextEditingController _phoneController;

  late String? _selectedRoleId;
  late bool _hasFullBranchAccess;
  late final Set<String> _selectedStoreIds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.collaborator;
    _firstNameController = TextEditingController(text: c.firstName);
    _lastNameController = TextEditingController(text: c.lastName);
    _idController = TextEditingController(text: c.identification ?? '');
    _phoneController = TextEditingController(text: c.phone ?? '');
    _selectedRoleId = c.roleId.isNotEmpty ? c.roleId : null;
    _hasFullBranchAccess = c.hasFullBranchAccess;
    _selectedStoreIds = c.stores.map((s) => s.id).toSet();
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
      await ref
          .read(collaboratorsNotifierProvider.notifier)
          .updateCollaborator(
            collaboratorId: widget.collaborator.id,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            identification: _idController.text.trim(),
            phone: _phoneController.text.trim(),
            roleId: _selectedRoleId,
            hasFullBranchAccess: _hasFullBranchAccess,
            storeIds: _hasFullBranchAccess ? [] : _selectedStoreIds.toList(),
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();
      NotificationService.showSuccess(
        context,
        'Colaborador actualizado exitosamente',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      NotificationService.showError(
        context,
        'Error al actualizar colaborador: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final rolesState = ref.watch(rolesNotifierProvider);
    final storesState = ref.watch(storesProvider);

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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Editar Colaborador',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${widget.collaborator.accessId}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
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
              const SizedBox(height: 12),

              // Cédula y Teléfono
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Cédula / ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selección de Rol
              const Text(
                'Rol Asignado *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              if (rolesState.isLoading && rolesState.roles.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
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
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'No hay roles configurados. Debes crear un rol primero.',
                          style: TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          size: 18,
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
                  initialValue: rolesState.roles.any((r) => r.id == _selectedRoleId)
                      ? _selectedRoleId
                      : null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Selecciona un rol',
                  ),
                  items: rolesState.roles.map((role) {
                    return DropdownMenuItem<String>(
                      value: role.id,
                      child: Text(role.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedRoleId = val);
                  },
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
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Acceso a todas las sucursales'),
                subtitle: const Text(
                  'Podrá operar en todas las tiendas actuales y futuras de la empresa.',
                  style: TextStyle(fontSize: 12),
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
                  'Selecciona las sucursales permitidas:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                storesState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : storesState.stores.isEmpty
                        ? const Text('No tienes tiendas/sucursales creadas.')
                        : Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: storesState.stores.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final store = storesState.stores[index];
                                final isSelected =
                                    _selectedStoreIds.contains(store.id);

                                return CheckboxListTile(
                                  value: isSelected,
                                  title: Text(store.name),
                                  subtitle: (store.address != null &&
                                          store.address!.isNotEmpty)
                                      ? Text(
                                          store.address!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11),
                                        )
                                      : null,
                                  activeColor: const Color(0xFF4F46E5),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
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

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar Cambios',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

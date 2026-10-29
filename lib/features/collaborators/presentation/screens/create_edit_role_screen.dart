import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/permission_item.dart';
import '../providers/collaborators_providers.dart';

class CreateEditRoleScreen extends ConsumerStatefulWidget {
  final CompanyRole? role;

  const CreateEditRoleScreen({super.key, this.role});

  @override
  ConsumerState<CreateEditRoleScreen> createState() =>
      _CreateEditRoleScreenState();
}

class _CreateEditRoleScreenState extends ConsumerState<CreateEditRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final Set<String> _selectedPermissions = {};
  bool _isSaving = false;

  bool get _isEditing => widget.role != null;
  bool get _isDefaultRole => widget.role?.isSystemDefault == true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.role?.description ?? '');

    if (widget.role != null) {
      _selectedPermissions.addAll(widget.role!.permissions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  static const Map<String, ({String desc, List<String> permissions})> _presets = {
    'Encargado / Gerente': (
      desc: 'Gestión completa de operaciones, métricas de venta, inventario, precios y reclamos.',
      permissions: [
        'branches:view',
        'branches:manage',
        'customers:block',
        'orders:view',
        'orders:process',
        'orders:cancel',
        'orders:chat',
        'orders:view_customer_data',
        'inventory:view',
        'inventory:manage_stock',
        'inventory:change_price',
        'inventory:edit',
        'inventory:manage_slots',
        'metrics:view_financial',
        'metrics:view_sales_history',
        'finances:view_summary',
        'installments:view',
        'installments:approve_payment',
        'installments:reject_payment',
        'disputes:view',
        'disputes:respond',
        'disputes:resolve',
        'team:view',
      ],
    ),
    'Cajero / Ventas': (
      desc: 'Atención a clientes, despacho de pedidos y cobro de cuotas. Sin acceso a modificar precios ni ver ingresos totales.',
      permissions: [
        'branches:view',
        'orders:view',
        'orders:process',
        'orders:chat',
        'orders:view_customer_data',
        'inventory:view',
        'inventory:manage_stock',
        'finances:view_summary',
        'installments:view',
        'installments:approve_payment',
      ],
    ),
    'Almacén / Despacho': (
      desc: 'Control de existencias y preparación de paquetes sin acceso a cobros ni métricas monetarias.',
      permissions: [
        'branches:view',
        'orders:view',
        'orders:process',
        'inventory:view',
        'inventory:manage_stock',
      ],
    ),
  };

  void _applyPreset(String presetName) {
    final preset = _presets[presetName];
    if (preset == null) return;
    setState(() {
      _nameController.text = presetName;
      _descriptionController.text = preset.desc;
      _selectedPermissions.clear();
      _selectedPermissions.addAll(preset.permissions);
    });
  }

  String _getModuleTitle(String module) {
    switch (module.toLowerCase()) {
      case 'orders':
      case 'pedidos':
        return 'Ventas y Pedidos';
      case 'inventory':
      case 'inventario':
        return 'Inventario y Catálogo';
      case 'branches':
      case 'sucursales':
        return 'Sucursales y Clientes';
      case 'collaborators':
      case 'equipo':
        return 'Equipo y Colaboradores';
      case 'finances':
      case 'métricas':
      case 'metricas':
        return 'Métricas y Finanzas';
      case 'cuotas':
        return 'Cuotas y Cuentas por Cobrar';
      case 'reclamos':
        return 'Reclamos y Mediaciones';
      case 'settings':
      case 'configuración':
        return 'Configuración';
      default:
        return module;
    }
  }

  IconData _getModuleIcon(String module) {
    switch (module.toLowerCase()) {
      case 'orders':
      case 'pedidos':
        return Icons.shopping_bag_outlined;
      case 'inventory':
      case 'inventario':
        return Icons.inventory_2_outlined;
      case 'branches':
      case 'sucursales':
        return Icons.store_outlined;
      case 'collaborators':
      case 'equipo':
        return Icons.people_outline;
      case 'finances':
      case 'métricas':
      case 'metricas':
        return Icons.insights_outlined;
      case 'cuotas':
        return Icons.receipt_long_outlined;
      case 'reclamos':
        return Icons.gavel_outlined;
      case 'settings':
      case 'configuración':
        return Icons.settings_outlined;
      default:
        return Icons.security_outlined;
    }
  }

  Future<void> _submit() async {
    if (_isDefaultRole) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPermissions.isEmpty) {
      NotificationService.showError(
        context,
        'Debes seleccionar al menos un permiso para este rol.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await ref.read(rolesNotifierProvider.notifier).updateRole(
              roleId: widget.role!.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              permissions: _selectedPermissions.toList(),
            );
        if (!mounted) return;
        NotificationService.showSuccess(context, 'Rol actualizado con éxito');
      } else {
        await ref.read(rolesNotifierProvider.notifier).createRole(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              permissions: _selectedPermissions.toList(),
            );
        if (!mounted) return;
        NotificationService.showSuccess(context, 'Rol creado con éxito');
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        'Error al guardar el rol: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(permissionCatalogProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Rol' : 'Nuevo Rol'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isDefaultRole)
            TextButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isDefaultRole)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield, color: Color(0xFF2563EB), size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Este es el rol Administrador del sistema. Posee acceso total a todos los módulos y sus permisos no pueden ser modificados.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E40AF),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (!_isEditing) ...[
                  const Text(
                    'Plantillas Rápidas de Rol',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _presets.keys.map((presetName) {
                        final isSelected = _nameController.text == presetName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0, bottom: 16.0),
                          child: ActionChip(
                            avatar: Icon(
                              isSelected ? Icons.check_circle : Icons.auto_awesome,
                              size: 16,
                              color: isSelected ? Colors.white : const Color(0xFF4F46E5),
                            ),
                            label: Text(presetName),
                            backgroundColor: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            onPressed: () => _applyPreset(presetName),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Card de Información Básica
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Rol',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isDefaultRole,
                        decoration: InputDecoration(
                          labelText: 'Nombre del rol *',
                          hintText: 'Ej. Cajero, Encargado, Supervisor',
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                          filled: true,
                          fillColor: _isDefaultRole
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un nombre para el rol';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !_isDefaultRole,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Descripción (Opcional)',
                          hintText: 'Explica qué tareas desempeña este rol',
                          prefixIcon:
                              const Icon(Icons.description_outlined, size: 20),
                          filled: true,
                          fillColor: _isDefaultRole
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Lista de Permisos
                const Text(
                  'Permisos Asignados',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Elige las acciones específicas que los colaboradores con este rol podrán realizar.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                catalogAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Error al cargar catálogo de permisos: $err'),
                  ),
                  data: (items) {
                    // Group by module
                    final Map<String, List<PermissionItem>> grouped = {};
                    for (final item in items) {
                      grouped.putIfAbsent(item.module, () => []).add(item);
                    }

                    return Column(
                      children: grouped.entries.map((entry) {
                        final moduleName = entry.key;
                        final moduleItems = entry.value;
                        final allSelected = moduleItems
                            .every((i) => _selectedPermissions.contains(i.key));

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getModuleIcon(moduleName),
                                  color: const Color(0xFF4F46E5),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                _getModuleTitle(moduleName),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: Text(
                                '${moduleItems.where((i) => _selectedPermissions.contains(i.key)).length} de ${moduleItems.length} activos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: _isDefaultRole
                                  ? null
                                  : TextButton(
                                      onPressed: () {
                                        setState(() {
                                          if (allSelected) {
                                            for (final item in moduleItems) {
                                              _selectedPermissions
                                                  .remove(item.key);
                                            }
                                          } else {
                                            for (final item in moduleItems) {
                                              _selectedPermissions
                                                  .add(item.key);
                                            }
                                          }
                                        });
                                      },
                                      child: Text(
                                        allSelected
                                            ? 'Desmarcar'
                                            : 'Todos',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ),
                              children: [
                                const Divider(height: 1),
                                ...moduleItems.map((item) {
                                  final isChecked =
                                      _selectedPermissions.contains(item.key);
                                  return CheckboxListTile(
                                    value: isChecked,
                                    enabled: !_isDefaultRole,
                                    activeColor: const Color(0xFF4F46E5),
                                    title: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    subtitle: Text(
                                      item.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedPermissions.add(item.key);
                                        } else {
                                          _selectedPermissions.remove(item.key);
                                        }
                                      });
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                if (!_isDefaultRole)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isEditing ? 'Guardar Cambios' : 'Crear Rol',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../../domain/entities/collaborator.dart';
import '../../domain/entities/company_role.dart';
import '../providers/collaborators_providers.dart';
import 'create_collaborator_dialog.dart';
import 'edit_collaborator_dialog.dart';
import 'create_edit_role_screen.dart';

class TeamManagementScreen extends ConsumerStatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  ConsumerState<TeamManagementScreen> createState() =>
      _TeamManagementScreenState();
}

class _TeamManagementScreenState extends ConsumerState<TeamManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Equipo y Roles'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.people_alt_outlined, size: 20),
              text: 'Colaboradores',
            ),
            Tab(
              icon: Icon(Icons.admin_panel_settings_outlined, size: 20),
              text: 'Roles y Permisos',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CollaboratorsTab(),
          _RolesTab(),
        ],
      ),
    );
  }
}

class _CollaboratorsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collaboratorsNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateCollaboratorDialog.show(context),
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Nuevo Colaborador',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading && state.collaborators.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.collaborators.isEmpty
              ? _buildErrorView(context, ref, state.errorMessage!)
              : state.collaborators.isEmpty
                  ? _buildEmptyView(context)
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                          ref
                              .read(collaboratorsNotifierProvider.notifier)
                              .fetchNextPage();
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: () => ref
                            .read(collaboratorsNotifierProvider.notifier)
                            .loadCollaborators(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 80,
                          ),
                          itemCount: state.collaborators.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.collaborators.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final collab = state.collaborators[index];
                            return _CollaboratorCard(collaborator: collab);
                          },
                        ),
                      ),
                    ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 48,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tienes colaboradores aún',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega a tu equipo para delegar operaciones en tus sucursales con permisos específicos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => CreateCollaboratorDialog.show(context),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Registrar Colaborador'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    WidgetRef ref,
    String errorMessage,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Error al cargar colaboradores: $errorMessage',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(collaboratorsNotifierProvider.notifier)
                  .loadCollaborators(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollaboratorCard extends ConsumerWidget {
  final Collaborator collaborator;

  const _CollaboratorCard({required this.collaborator});

  void _copyAccessId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: collaborator.accessId));
    NotificationService.showSuccess(
      context,
      'ID de Acceso copiado: ${collaborator.accessId}',
    );
  }

  void _showEditDialog(BuildContext context) {
    EditCollaboratorDialog.show(context, collaborator: collaborator);
  }

  void _confirmToggleStatus(
    BuildContext context,
    WidgetRef ref,
    bool newStatus,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          newStatus ? '¿Reactivar Colaborador?' : '¿Dar de Baja / Suspender?',
          style: TextStyle(
            color: newStatus ? const Color(0xFF166534) : const Color(0xFF991B1B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          newStatus
              ? 'Se reactivará la cuenta de ${collaborator.fullName}. Podrá volver a iniciar sesión y acceder a las sucursales asignadas.'
              : 'Se suspenderá la cuenta de ${collaborator.fullName}. Sus sesiones activas se cerrarán de inmediato y no podrá acceder al sistema hasta que sea reactivado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(collaboratorsNotifierProvider.notifier)
                    .toggleCollaboratorStatus(collaborator.id, newStatus);
                if (context.mounted) {
                  NotificationService.showSuccess(
                    context,
                    newStatus
                        ? 'Colaborador reactivado'
                        : 'Colaborador suspendido / dado de baja',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  NotificationService.showError(
                    context,
                    'Error: $e',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
            child: Text(
              newStatus ? 'Reactivar' : 'Dar de Baja',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRegeneratePasswordDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Regenerar Contraseña?'),
        content: Text(
          'Se creará una nueva contraseña temporal para ${collaborator.fullName}. Su sesión actual finalizará inmediatamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final result = await ref
                    .read(collaboratorsNotifierProvider.notifier)
                    .regeneratePassword(collaborator.id);

                final newPassword = result;

                if (context.mounted) {
                  _showNewCredentialsDialog(context, newPassword);
                }
              } catch (e) {
                if (context.mounted) {
                  NotificationService.showError(
                    context,
                    'Error al regenerar: $e',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            child: const Text('Regenerar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNewCredentialsDialog(BuildContext context, String newPassword) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Contraseña Generada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID de Acceso: ${collaborator.accessId}'),
            const SizedBox(height: 8),
            Text(
              'Nueva Contraseña: $newPassword',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Comparte esta nueva contraseña con el colaborador.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'ID: ${collaborator.accessId} | Contraseña: $newPassword',
              ));
              NotificationService.showSuccess(
                context,
                'Credenciales copiadas',
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Colaborador?'),
        content: Text(
          '¿Estás seguro de eliminar a ${collaborator.fullName}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(collaboratorsNotifierProvider.notifier)
                    .deleteCollaborator(collaborator.id);
                if (context.mounted) {
                  NotificationService.showSuccess(
                    context,
                    'Colaborador eliminado',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  NotificationService.showError(
                    context,
                    'Error al eliminar: $e',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchScopeText = collaborator.hasFullBranchAccess
        ? 'Todas las sucursales'
        : '${collaborator.stores.length} sucursal(es)';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: collaborator.isActive ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: collaborator.isActive
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: collaborator.isActive
                    ? const Color(0xFFEEF2FF)
                    : const Color(0xFFF1F5F9),
                child: Text(
                  collaborator.firstName.isNotEmpty
                      ? collaborator.firstName[0].toUpperCase()
                      : 'C',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: collaborator.isActive
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            collaborator.fullName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: collaborator.isActive
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!collaborator.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: const Text(
                              'Inactivo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'ID: ${collaborator.accessId}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _copyAccessId(context),
                          child: const Icon(
                            Icons.copy,
                            size: 14,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showEditDialog(context);
                  } else if (val == 'toggle_status') {
                    _confirmToggleStatus(context, ref, !collaborator.isActive);
                  } else if (val == 'regenerate') {
                    _showRegeneratePasswordDialog(context, ref);
                  } else if (val == 'delete') {
                    _showDeleteDialog(context, ref);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF4F46E5)),
                        SizedBox(width: 8),
                        Text('Editar Colaborador'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          collaborator.isActive
                              ? Icons.block
                              : Icons.check_circle_outline,
                          size: 18,
                          color: collaborator.isActive
                              ? Colors.orange.shade800
                              : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          collaborator.isActive
                              ? 'Dar de Baja / Suspender'
                              : 'Reactivar Colaborador',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'regenerate',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset, size: 18),
                        SizedBox(width: 8),
                        Text('Regenerar Contraseña'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Eliminar',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      collaborator.roleName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          branchScopeText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Switch(
                value: collaborator.isActive,
                activeThumbColor: const Color(0xFF4F46E5),
                onChanged: (val) {
                  _confirmToggleStatus(context, ref, val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RolesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rolesNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateEditRoleScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.add_moderator, color: Colors.white),
        label: const Text(
          'Nuevo Rol',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading && state.roles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.roles.isEmpty
              ? _buildErrorView(context, ref, state.errorMessage!)
              : state.roles.isEmpty
                  ? _buildEmptyRolesView(context, ref)
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(rolesNotifierProvider.notifier).loadRoles(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 80,
                        ),
                        itemCount: state.roles.length,
                        itemBuilder: (context, index) {
                          final role = state.roles[index];
                          return _RoleCard(role: role);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyRolesView(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 48,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No existen roles personalizados aún',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El rol predeterminado de Administrador está activo por defecto. Puedes crear roles adicionales para cajeros, despachadores o encargados con permisos específicos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(rolesNotifierProvider.notifier).loadRoles(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Recargar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateEditRoleScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_moderator, size: 18),
                  label: const Text('Crear Rol'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    WidgetRef ref,
    String errorMessage,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Error al cargar roles: $errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(rolesNotifierProvider.notifier).loadRoles(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends ConsumerWidget {
  final CompanyRole role;

  const _RoleCard({required this.role});

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Rol?'),
        content: Text(
          '¿Estás seguro de eliminar el rol "${role.name}"? Los colaboradores que tengan este rol perderán sus permisos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(rolesNotifierProvider.notifier)
                    .deleteRole(role.id);
                if (context.mounted) {
                  NotificationService.showSuccess(context, 'Rol eliminado');
                }
              } catch (e) {
                if (context.mounted) {
                  NotificationService.showError(
                    context,
                    'Error al eliminar rol: $e',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: role.isSystemDefault
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  role.isSystemDefault
                      ? Icons.shield
                      : Icons.admin_panel_settings_outlined,
                  color: role.isSystemDefault
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          role.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (role.isSystemDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Predeterminado',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (role.description != null &&
                        role.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        role.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: const Color(0xFF64748B),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateEditRoleScreen(role: role),
                    ),
                  );
                },
              ),
              if (!role.isSystemDefault)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red,
                  onPressed: () => _showDeleteDialog(context, ref),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 15,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                '${role.permissions.length} permisos habilitados',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

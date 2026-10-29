import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import '../../domain/entities/activity_log.dart';
import '../providers/activity_log_provider.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activityLogProvider.notifier).loadLogs(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(activityLogProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;

    // Solo accesible por administradores y dueños de empresa
    if (user?.isCollaborator == true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial de Actividades')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Acceso Restringido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'El historial de auditoría de actividades solo está disponible para el administrador o dueño de la empresa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final state = ref.watch(activityLogProvider);
    final storesState = ref.watch(storesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Actividades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () =>
                ref.read(activityLogProvider.notifier).loadLogs(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros por Sucursal y Módulo
          _buildFilterBar(context, state, storesState),
          const Divider(height: 1),

          // Lista de Actividades
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(activityLogProvider.notifier)
                  .loadLogs(refresh: true),
              child: _buildBody(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    ActivityLogState state,
    dynamic storesState,
  ) {
    final stores = storesState.stores;

    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stores.length > 1) ...[
            Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: state.selectedStoreId,
                      isDense: true,
                      isExpanded: true,
                      hint: const Text('Todas las sucursales',
                          style: TextStyle(fontSize: 13)),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las sucursales',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        ...stores.map((s) => DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text(
                                (s.branchName != null &&
                                        s.branchName!.isNotEmpty)
                                    ? '${s.name} - ${s.branchName}'
                                    : s.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            )),
                      ],
                      onChanged: (val) {
                        ref
                            .read(activityLogProvider.notifier)
                            .setStoreFilter(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Chips de Módulo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModuleChip(
                  label: 'Todos',
                  moduleValue: null,
                  isSelected: state.selectedModule == null,
                ),
                const SizedBox(width: 6),
                _buildModuleChip(
                  label: 'Inventario',
                  moduleValue: 'INVENTORY',
                  isSelected: state.selectedModule == 'INVENTORY',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(width: 6),
                _buildModuleChip(
                  label: 'Pedidos',
                  moduleValue: 'ORDERS',
                  isSelected: state.selectedModule == 'ORDERS',
                  icon: Icons.shopping_bag_outlined,
                ),
                const SizedBox(width: 6),
                _buildModuleChip(
                  label: 'Cuotas',
                  moduleValue: 'INSTALLMENTS',
                  isSelected: state.selectedModule == 'INSTALLMENTS',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(width: 6),
                _buildModuleChip(
                  label: 'Equipo',
                  moduleValue: 'TEAM',
                  isSelected: state.selectedModule == 'TEAM',
                  icon: Icons.badge_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleChip({
    required String label,
    required String? moduleValue,
    required bool isSelected,
    IconData? icon,
  }) {
    return ChoiceChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.indigo,
            )
          : null,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.grey.shade800,
      ),
      selected: isSelected,
      selectedColor: Colors.indigo,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.indigo : Colors.grey.shade300,
        ),
      ),
      onSelected: (_) {
        ref.read(activityLogProvider.notifier).setModuleFilter(moduleValue);
      },
    );
  }

  Widget _buildBody(BuildContext context, ActivityLogState state) {
    if (state.isLoading && state.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(activityLogProvider.notifier)
                    .loadLogs(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off_outlined,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No hay actividades registradas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Las acciones que realicen tú y tu equipo en inventario, órdenes, cuotas y personal aparecerán aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.logs.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.logs.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final log = state.logs[index];
        final showDateHeader = index == 0 ||
            !_isSameDay(state.logs[index - 1].createdAt, log.createdAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateHeader) _buildDateHeader(log.createdAt),
            _buildLogTile(context, log),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final isToday = _isSameDay(now, date);
    final isYesterday =
        _isSameDay(now.subtract(const Duration(days: 1)), date);

    String label;
    if (isToday) {
      label = 'Hoy';
    } else if (isYesterday) {
      label = 'Ayer';
    } else {
      label = DateFormat('dd MMMM yyyy', 'es').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildLogTile(BuildContext context, ActivityLog log) {
    final moduleConfig = _getModuleConfig(log.module);
    final timeStr = DateFormat('hh:mm a').format(log.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono del módulo
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: moduleConfig.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(moduleConfig.icon,
                  size: 20, color: moduleConfig.color),
            ),
            const SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila de actor, rol y hora
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              log.actorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: log.isCollaborator
                                    ? Colors.amber.shade50
                                    : Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: log.isCollaborator
                                      ? Colors.amber.shade200
                                      : Colors.indigo.shade200,
                                ),
                              ),
                              child: Text(
                                log.actorRoleName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: log.isCollaborator
                                      ? Colors.amber.shade900
                                      : Colors.indigo.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Descripción de la acción
                  Text(
                    log.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),

                  // Información de la sucursal (si aplica)
                  if (log.store != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.storefront,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          log.store!.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ModuleConfig _getModuleConfig(String module) {
    switch (module.toUpperCase()) {
      case 'INVENTORY':
        return _ModuleConfig(
          icon: Icons.inventory_2_outlined,
          color: Colors.orange.shade700,
        );
      case 'ORDERS':
        return _ModuleConfig(
          icon: Icons.shopping_bag_outlined,
          color: Colors.blue.shade700,
        );
      case 'INSTALLMENTS':
        return _ModuleConfig(
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.green.shade700,
        );
      case 'TEAM':
      case 'COLLABORATORS':
        return _ModuleConfig(
          icon: Icons.badge_outlined,
          color: Colors.purple.shade700,
        );
      case 'STORE':
        return _ModuleConfig(
          icon: Icons.storefront_outlined,
          color: Colors.teal.shade700,
        );
      default:
        return _ModuleConfig(
          icon: Icons.history,
          color: Colors.indigo.shade700,
        );
    }
  }
}

class _ModuleConfig {
  final IconData icon;
  final Color color;

  const _ModuleConfig({required this.icon, required this.color});
}

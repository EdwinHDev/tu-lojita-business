import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import '../../data/datasources/collaborators_remote_datasource.dart';
import '../../data/datasources/roles_remote_datasource.dart';
import '../../data/repositories/collaborators_repository_impl.dart';
import '../../data/repositories/roles_repository_impl.dart';
import '../../domain/entities/collaborator.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/permission_item.dart';
import '../../domain/repositories/collaborators_repository.dart';
import '../../domain/repositories/roles_repository.dart';

// Repositories & DataSources
final rolesRemoteDataSourceProvider = Provider<RolesRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return RolesRemoteDataSourceImpl(dio);
});

final rolesRepositoryProvider = Provider<RolesRepository>((ref) {
  final remote = ref.watch(rolesRemoteDataSourceProvider);
  return RolesRepositoryImpl(remote);
});

final collaboratorsRemoteDataSourceProvider =
    Provider<CollaboratorsRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return CollaboratorsRemoteDataSourceImpl(dio);
});

final collaboratorsRepositoryProvider = Provider<CollaboratorsRepository>((ref) {
  final remote = ref.watch(collaboratorsRemoteDataSourceProvider);
  return CollaboratorsRepositoryImpl(remote);
});

// Permission catalog provider
final permissionCatalogProvider = FutureProvider<List<PermissionItem>>((ref) async {
  final repo = ref.watch(rolesRepositoryProvider);
  final authState = ref.watch(authProvider);
  final companyId = (authState is Authenticated) ? authState.user.company?.id ?? '' : '';
  return repo.getPermissionsCatalog(companyId);
});

// Roles State & Notifier
class RolesState {
  final List<CompanyRole> roles;
  final bool isLoading;
  final String? errorMessage;

  const RolesState({
    this.roles = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RolesState copyWith({
    List<CompanyRole>? roles,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RolesState(
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class RolesNotifier extends Notifier<RolesState> {
  @override
  RolesState build() {
    Future.microtask(() => loadRoles());
    return const RolesState(isLoading: true);
  }

  RolesRepository get _repository => ref.read(rolesRepositoryProvider);

  String? _getCompanyId() {
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      return authState.user.company?.id;
    }
    return null;
  }

  Future<void> loadRoles() async {
    final companyId = _getCompanyId();
    if (companyId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getRoles(companyId);
      state = state.copyWith(roles: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<CompanyRole> createRole({
    required String name,
    String? description,
    required List<String> permissions,
  }) async {
    final companyId = _getCompanyId();
    if (companyId == null) {
      throw Exception('No se encontró la empresa activa');
    }
    final created = await _repository.createRole(
      companyId,
      name: name,
      description: description,
      permissions: permissions,
    );
    await loadRoles();
    return created;
  }

  Future<CompanyRole> updateRole({
    required String roleId,
    required String name,
    String? description,
    required List<String> permissions,
  }) async {
    final companyId = _getCompanyId();
    if (companyId == null) {
      throw Exception('No se encontró la empresa activa');
    }
    final updated = await _repository.updateRole(
      companyId,
      roleId,
      name: name,
      description: description,
      permissions: permissions,
    );
    await loadRoles();
    return updated;
  }

  Future<void> deleteRole(String roleId) async {
    final companyId = _getCompanyId();
    if (companyId == null) {
      throw Exception('No se encontró la empresa activa');
    }
    await _repository.deleteRole(companyId, roleId);
    await loadRoles();
  }
}

final rolesNotifierProvider =
    NotifierProvider<RolesNotifier, RolesState>(() => RolesNotifier());

// Collaborators State & Notifier
class CollaboratorsState {
  final List<Collaborator> collaborators;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final int total;
  final String? errorMessage;

  const CollaboratorsState({
    this.collaborators = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.offset = 0,
    this.total = 0,
    this.errorMessage,
  });

  CollaboratorsState copyWith({
    List<Collaborator>? collaborators,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
    int? total,
    String? errorMessage,
  }) {
    return CollaboratorsState(
      collaborators: collaborators ?? this.collaborators,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      total: total ?? this.total,
      errorMessage: errorMessage,
    );
  }
}

class CollaboratorsNotifier extends Notifier<CollaboratorsState> {
  @override
  CollaboratorsState build() {
    Future.microtask(() => loadCollaborators());
    return const CollaboratorsState(isLoading: true);
  }

  CollaboratorsRepository get _repository =>
      ref.read(collaboratorsRepositoryProvider);

  String? _getCompanyId() {
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      return authState.user.company?.id;
    }
    return null;
  }

  Future<void> loadCollaborators({bool refresh = false}) async {
    final companyId = _getCompanyId();
    if (companyId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    if (refresh) {
      state = state.copyWith(isLoading: true, errorMessage: null, offset: 0);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final res = await _repository.getCollaborators(
        companyId,
        limit: 10,
        offset: 0,
      );
      state = state.copyWith(
        collaborators: res.items,
        isLoading: false,
        isLoadingMore: false,
        hasMore: res.hasMore,
        total: res.total,
        offset: res.items.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final companyId = _getCompanyId();
    if (companyId == null) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final res = await _repository.getCollaborators(
        companyId,
        limit: 10,
        offset: state.collaborators.length,
      );
      final updatedList = List<Collaborator>.from(state.collaborators)
        ..addAll(res.items);

      state = state.copyWith(
        collaborators: updatedList,
        isLoadingMore: false,
        hasMore: res.hasMore,
        total: res.total,
        offset: updatedList.length,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<Map<String, dynamic>> createCollaborator({
    required String firstName,
    required String lastName,
    required String identification,
    required String phone,
    required String roleId,
    required bool hasFullBranchAccess,
    required List<String> storeIds,
  }) async {
    final companyId = _getCompanyId();
    if (companyId == null) {
      throw Exception('No se encontró la empresa activa');
    }
    final res = await _repository.createCollaborator(
      companyId,
      firstName: firstName,
      lastName: lastName,
      identification: identification,
      phone: phone,
      roleId: roleId,
      hasFullBranchAccess: hasFullBranchAccess,
      storeIds: storeIds,
    );
    final newCollab = res['collaborator'] as Collaborator?;
    if (newCollab != null) {
      state = state.copyWith(
        collaborators: [newCollab, ...state.collaborators],
        total: state.total + 1,
      );
    } else {
      await loadCollaborators(refresh: true);
    }
    return res;
  }

  Future<Collaborator> updateCollaborator({
    required String collaboratorId,
    String? firstName,
    String? lastName,
    String? identification,
    String? phone,
    String? roleId,
    bool? hasFullBranchAccess,
    List<String>? storeIds,
    bool? isActive,
  }) async {
    final companyId = _getCompanyId();
    if (companyId == null) {
      throw Exception('No se encontró la empresa activa');
    }
    final updated = await _repository.updateCollaborator(
      companyId,
      collaboratorId,
      firstName: firstName,
      lastName: lastName,
      identification: identification,
      phone: phone,
      roleId: roleId,
      hasFullBranchAccess: hasFullBranchAccess,
      storeIds: storeIds,
      isActive: isActive,
    );
    state = state.copyWith(
      collaborators: state.collaborators
          .map((c) => c.id == collaboratorId ? updated : c)
          .toList(),
    );
    return updated;
  }

  Future<void> toggleCollaboratorStatus(
    String collaboratorId,
    bool isActive,
  ) async {
    final companyId = _getCompanyId();
    if (companyId == null) {
      throw Exception('No se encontró la empresa activa');
    }
    final updated = await _repository.updateCollaborator(
      companyId,
      collaboratorId,
      isActive: isActive,
    );
    state = state.copyWith(
      collaborators: state.collaborators
          .map((c) => c.id == collaboratorId ? updated : c)
          .toList(),
    );
  }

  Future<String> regeneratePassword(String collaboratorId) async {
    final companyId = _getCompanyId();
    if (companyId == null) {
      throw Exception('No se encontró la empresa activa');
    }
    final res = await _repository.regeneratePassword(
      companyId,
      collaboratorId,
    );
    return res;
  }

  Future<void> deleteCollaborator(String collaboratorId) async {
    final companyId = _getCompanyId();
    if (companyId == null) {
      throw Exception('No se encontró la empresa activa');
    }
    await _repository.deleteCollaborator(companyId, collaboratorId);
    state = state.copyWith(
      collaborators:
          state.collaborators.where((c) => c.id != collaboratorId).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
    );
  }
}

final collaboratorsNotifierProvider =
    NotifierProvider<CollaboratorsNotifier, CollaboratorsState>(
        () => CollaboratorsNotifier());


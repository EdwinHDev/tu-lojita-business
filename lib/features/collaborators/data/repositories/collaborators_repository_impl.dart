import '../../domain/entities/collaborator.dart';
import '../../domain/repositories/collaborators_repository.dart';
import '../datasources/collaborators_remote_datasource.dart';

class CollaboratorsRepositoryImpl implements CollaboratorsRepository {
  final CollaboratorsRemoteDataSource remoteDataSource;

  CollaboratorsRepositoryImpl(this.remoteDataSource);

  @override
  Future<PaginatedCollaborators> getCollaborators(
    String companyId, {
    int limit = 10,
    int offset = 0,
  }) {
    return remoteDataSource.getCollaborators(
      companyId,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<Collaborator> getCollaborator(
      String companyId, String collaboratorId) {
    return remoteDataSource.getCollaborator(companyId, collaboratorId);
  }

  @override
  Future<Map<String, dynamic>> createCollaborator(
    String companyId, {
    required String firstName,
    required String lastName,
    String? identification,
    String? phone,
    required String roleId,
    List<String>? storeIds,
    bool hasFullBranchAccess = false,
  }) {
    return remoteDataSource.createCollaborator(
      companyId,
      firstName: firstName,
      lastName: lastName,
      identification: identification,
      phone: phone,
      roleId: roleId,
      storeIds: storeIds,
      hasFullBranchAccess: hasFullBranchAccess,
    );
  }

  @override
  Future<Collaborator> updateCollaborator(
    String companyId,
    String collaboratorId, {
    String? firstName,
    String? lastName,
    String? identification,
    String? phone,
    String? roleId,
    List<String>? storeIds,
    bool? hasFullBranchAccess,
    bool? isActive,
  }) {
    return remoteDataSource.updateCollaborator(
      companyId,
      collaboratorId,
      firstName: firstName,
      lastName: lastName,
      identification: identification,
      phone: phone,
      roleId: roleId,
      storeIds: storeIds,
      hasFullBranchAccess: hasFullBranchAccess,
      isActive: isActive,
    );
  }

  @override
  Future<String> regeneratePassword(
      String companyId, String collaboratorId) {
    return remoteDataSource.regeneratePassword(companyId, collaboratorId);
  }

  @override
  Future<void> deleteCollaborator(
      String companyId, String collaboratorId) {
    return remoteDataSource.deleteCollaborator(companyId, collaboratorId);
  }

  @override
  Future<Map<String, dynamic>> loginCollaborator({
    required String accessId,
    required String password,
  }) {
    return remoteDataSource.loginCollaborator(
      accessId: accessId,
      password: password,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

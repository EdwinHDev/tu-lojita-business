import '../entities/collaborator.dart';

abstract class CollaboratorsRepository {
  Future<PaginatedCollaborators> getCollaborators(
    String companyId, {
    int limit = 10,
    int offset = 0,
  });
  Future<Collaborator> getCollaborator(String companyId, String collaboratorId);
  Future<Map<String, dynamic>> createCollaborator(
    String companyId, {
    required String firstName,
    required String lastName,
    String? identification,
    String? phone,
    required String roleId,
    List<String>? storeIds,
    bool hasFullBranchAccess = false,
  });
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
  });
  Future<String> regeneratePassword(String companyId, String collaboratorId);
  Future<void> deleteCollaborator(String companyId, String collaboratorId);
  Future<Map<String, dynamic>> loginCollaborator({
    required String accessId,
    required String password,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

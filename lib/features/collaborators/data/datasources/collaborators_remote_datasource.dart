import 'package:dio/dio.dart';
import '../../domain/entities/collaborator.dart';

abstract class CollaboratorsRemoteDataSource {
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

class CollaboratorsRemoteDataSourceImpl implements CollaboratorsRemoteDataSource {
  final Dio dio;

  CollaboratorsRemoteDataSourceImpl(this.dio);

  @override
  Future<PaginatedCollaborators> getCollaborators(
    String companyId, {
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await dio.get(
      '/companies/$companyId/collaborators',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return PaginatedCollaborators.fromJson(response.data);
  }

  @override
  Future<Collaborator> getCollaborator(
      String companyId, String collaboratorId) async {
    final response =
        await dio.get('/companies/$companyId/collaborators/$collaboratorId');
    return Collaborator.fromJson(response.data as Map<String, dynamic>);
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
  }) async {
    final payload = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'roleId': roleId,
      'hasFullBranchAccess': hasFullBranchAccess,
    };
    if (identification != null && identification.isNotEmpty) {
      payload['identification'] = identification;
    }
    if (phone != null && phone.isNotEmpty) {
      payload['phone'] = phone;
    }
    if (storeIds != null) {
      payload['storeIds'] = storeIds;
    }

    final response = await dio.post(
      '/companies/$companyId/collaborators',
      data: payload,
    );
    final data = response.data as Map<String, dynamic>;
    final collaborator =
        Collaborator.fromJson(data['collaborator'] as Map<String, dynamic>);
    return {
      'collaborator': collaborator,
      'generatedAccessId': data['generatedAccessId'] ?? collaborator.accessId,
      'generatedInitialPassword': data['generatedInitialPassword'] ?? '',
    };
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
  }) async {
    final payload = <String, dynamic>{};
    if (firstName != null) payload['firstName'] = firstName;
    if (lastName != null) payload['lastName'] = lastName;
    if (identification != null) payload['identification'] = identification;
    if (phone != null) payload['phone'] = phone;
    if (roleId != null) payload['roleId'] = roleId;
    if (storeIds != null) payload['storeIds'] = storeIds;
    if (hasFullBranchAccess != null) {
      payload['hasFullBranchAccess'] = hasFullBranchAccess;
    }
    if (isActive != null) payload['isActive'] = isActive;

    final response = await dio.patch(
      '/companies/$companyId/collaborators/$collaboratorId',
      data: payload,
    );
    return Collaborator.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<String> regeneratePassword(
      String companyId, String collaboratorId) async {
    final response = await dio.post(
      '/companies/$companyId/collaborators/$collaboratorId/regenerate-password',
    );
    final data = response.data as Map<String, dynamic>;
    return data['newTemporaryPassword'] as String? ?? '';
  }

  @override
  Future<void> deleteCollaborator(
      String companyId, String collaboratorId) async {
    await dio.delete('/companies/$companyId/collaborators/$collaboratorId');
  }

  @override
  Future<Map<String, dynamic>> loginCollaborator({
    required String accessId,
    required String password,
  }) async {
    final response = await dio.post(
      '/auth/collaborator-login',
      data: {
        'accessId': accessId,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await dio.post(
      '/auth/collaborator-change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}

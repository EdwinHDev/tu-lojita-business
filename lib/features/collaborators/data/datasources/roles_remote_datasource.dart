import 'package:dio/dio.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/permission_item.dart';

abstract class RolesRemoteDataSource {
  Future<List<PermissionItem>> getPermissionsCatalog(String companyId);
  Future<List<CompanyRole>> getRoles(String companyId);
  Future<CompanyRole> getRole(String companyId, String roleId);
  Future<CompanyRole> createRole(
    String companyId, {
    required String name,
    String? description,
    required List<String> permissions,
  });
  Future<CompanyRole> updateRole(
    String companyId,
    String roleId, {
    String? name,
    String? description,
    List<String>? permissions,
  });
  Future<void> deleteRole(String companyId, String roleId);
}

class RolesRemoteDataSourceImpl implements RolesRemoteDataSource {
  final Dio dio;

  RolesRemoteDataSourceImpl(this.dio);

  @override
  Future<List<PermissionItem>> getPermissionsCatalog(String companyId) async {
    final response = await dio.get('/companies/$companyId/roles/permissions-catalog');
    final list = response.data as List? ?? [];
    return list.map((item) => PermissionItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<CompanyRole>> getRoles(String companyId) async {
    final response = await dio.get('/companies/$companyId/roles');
    final list = response.data as List? ?? [];
    return list.map((item) => CompanyRole.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<CompanyRole> getRole(String companyId, String roleId) async {
    final response = await dio.get('/companies/$companyId/roles/$roleId');
    return CompanyRole.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CompanyRole> createRole(
    String companyId, {
    required String name,
    String? description,
    required List<String> permissions,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'permissions': permissions,
    };
    if (description != null) payload['description'] = description;

    final response = await dio.post(
      '/companies/$companyId/roles',
      data: payload,
    );
    return CompanyRole.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CompanyRole> updateRole(
    String companyId,
    String roleId, {
    String? name,
    String? description,
    List<String>? permissions,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (description != null) payload['description'] = description;
    if (permissions != null) payload['permissions'] = permissions;

    final response = await dio.patch(
      '/companies/$companyId/roles/$roleId',
      data: payload,
    );
    return CompanyRole.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteRole(String companyId, String roleId) async {
    await dio.delete('/companies/$companyId/roles/$roleId');
  }
}

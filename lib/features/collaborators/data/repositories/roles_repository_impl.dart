import '../../domain/entities/company_role.dart';
import '../../domain/entities/permission_item.dart';
import '../../domain/repositories/roles_repository.dart';
import '../datasources/roles_remote_datasource.dart';

class RolesRepositoryImpl implements RolesRepository {
  final RolesRemoteDataSource remoteDataSource;

  RolesRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<PermissionItem>> getPermissionsCatalog(String companyId) {
    return remoteDataSource.getPermissionsCatalog(companyId);
  }

  @override
  Future<List<CompanyRole>> getRoles(String companyId) {
    return remoteDataSource.getRoles(companyId);
  }

  @override
  Future<CompanyRole> getRole(String companyId, String roleId) {
    return remoteDataSource.getRole(companyId, roleId);
  }

  @override
  Future<CompanyRole> createRole(
    String companyId, {
    required String name,
    String? description,
    required List<String> permissions,
  }) {
    return remoteDataSource.createRole(
      companyId,
      name: name,
      description: description,
      permissions: permissions,
    );
  }

  @override
  Future<CompanyRole> updateRole(
    String companyId,
    String roleId, {
    String? name,
    String? description,
    List<String>? permissions,
  }) {
    return remoteDataSource.updateRole(
      companyId,
      roleId,
      name: name,
      description: description,
      permissions: permissions,
    );
  }

  @override
  Future<void> deleteRole(String companyId, String roleId) {
    return remoteDataSource.deleteRole(companyId, roleId);
  }
}

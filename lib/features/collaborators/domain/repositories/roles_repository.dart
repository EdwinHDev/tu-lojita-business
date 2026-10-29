import '../entities/company_role.dart';
import '../entities/permission_item.dart';

abstract class RolesRepository {
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

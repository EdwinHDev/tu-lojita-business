import 'dart:io';

abstract class CompanyRepository {
  Future<void> createCompany({
    required String name,
    required String rif,
    File? logoFile,
    String? existingLogoUrl,
  });
  Future<void> updateStoreBranchName({
    required String storeId,
    required String branchName,
  });
  Future<void> updateCompany({
    required String companyId,
    String? name,
    String? rif,
    String? logo,
  });
}

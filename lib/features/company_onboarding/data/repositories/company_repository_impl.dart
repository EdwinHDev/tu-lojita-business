import 'dart:io';
import 'package:tu_lojita_business/features/company_onboarding/data/datasources/company_remote_data_source.dart';
import 'package:tu_lojita_business/features/company_onboarding/data/datasources/image_remote_data_source.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/repositories/company_repository.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  final CompanyRemoteDataSource _companyDataSource;
  final ImageRemoteDataSource _imageDataSource;

  CompanyRepositoryImpl({
    required CompanyRemoteDataSource companyDataSource,
    required ImageRemoteDataSource imageDataSource,
  })  : _companyDataSource = companyDataSource,
        _imageDataSource = imageDataSource;

  @override
  Future<void> createCompany({
    required String name,
    required String rif,
    File? logoFile,
    String? existingLogoUrl,
  }) async {
    String? finalLogoUrl;
    bool isNewUpload = false;

    try {
      if (logoFile != null) {
        // 1. Upload Image
        finalLogoUrl = await _imageDataSource.uploadImage(logoFile);
        isNewUpload = true;
      } else if (existingLogoUrl != null) {
        finalLogoUrl = existingLogoUrl;
      } else {
        throw Exception('Se requiere un logo para la empresa');
      }

      // 2. Create Company
      await _companyDataSource.createCompany(
        name: name,
        rif: rif,
        logo: finalLogoUrl,
      );
      
    } catch (e) {
      // 3. Rollback if image was uploaded but company creation failed
      if (isNewUpload && finalLogoUrl != null) {
        await _imageDataSource.deleteImage(finalLogoUrl);
      }
      rethrow;
    }
  }
  @override
  Future<void> updateStoreBranchName({
    required String storeId,
    required String branchName,
  }) async {
    await _companyDataSource.updateStoreBranchName(storeId, branchName);
  }

  @override
  Future<void> updateCompany({
    required String companyId,
    String? name,
    String? rif,
    String? logo,
  }) async {
    await _companyDataSource.updateCompany(
      companyId: companyId,
      name: name,
      rif: rif,
      logo: logo,
    );
  }
}

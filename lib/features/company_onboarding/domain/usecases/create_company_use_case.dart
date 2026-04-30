import 'dart:io';
import '../repositories/company_repository.dart';

class CreateCompanyUseCase {
  final CompanyRepository _repository;

  CreateCompanyUseCase(this._repository);

  Future<void> execute({
    required String name,
    required String rif,
    File? logoFile,
    String? existingLogoUrl,
  }) async {
    return await _repository.createCompany(
      name: name,
      rif: rif,
      logoFile: logoFile,
      existingLogoUrl: existingLogoUrl,
    );
  }
}

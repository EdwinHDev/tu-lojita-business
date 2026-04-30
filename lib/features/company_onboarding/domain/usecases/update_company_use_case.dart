import 'package:tu_lojita_business/features/company_onboarding/domain/repositories/company_repository.dart';

class UpdateCompanyUseCase {
  final CompanyRepository _repository;

  UpdateCompanyUseCase(this._repository);

  Future<void> execute({
    required String companyId,
    String? name,
    String? rif,
    String? logo,
  }) async {
    await _repository.updateCompany(
      companyId: companyId,
      name: name,
      rif: rif,
      logo: logo,
    );
  }
}

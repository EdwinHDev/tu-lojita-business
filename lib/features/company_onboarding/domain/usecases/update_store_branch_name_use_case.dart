import '../repositories/company_repository.dart';

class UpdateStoreBranchNameUseCase {
  final CompanyRepository _repository;

  UpdateStoreBranchNameUseCase(this._repository);

  Future<void> execute({
    required String storeId,
    required String branchName,
  }) async {
    return await _repository.updateStoreBranchName(
      storeId: storeId,
      branchName: branchName,
    );
  }
}

import '../../../auth/domain/repositories/auth_repository.dart';

class CheckOnboardingStatusUseCase {
  final AuthRepository _authRepository;

  CheckOnboardingStatusUseCase(this._authRepository);

  Future<OnboardingStatus> execute() async {
    final companyStatus = await _authRepository.checkCompanyStatus();
    final storeStatus = await _authRepository.checkStoreStatus();

    return OnboardingStatus(
      hasCompany: companyStatus['hasCompany'] as bool,
      hasStore: storeStatus['hasStore'] as bool,
      storeName: storeStatus['storeName'] as String?,
      storeId: storeStatus['storeId'] as String?,
      storeRif: storeStatus['storeRif'] as String?,
      storeLogo: storeStatus['storeLogo'] as String?,
      subcategoryId: storeStatus['subcategoryId'] as String?,
      subcategoryName: storeStatus['subcategoryName'] as String?,
      categoryId: storeStatus['categoryId'] as String?,
      categoryName: storeStatus['categoryName'] as String?,
    );
  }
}

class OnboardingStatus {
  final bool hasCompany;
  final bool hasStore;
  final String? storeName;
  final String? storeId;
  final String? storeRif;
  final String? storeLogo;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? categoryId;
  final String? categoryName;

  OnboardingStatus({
    required this.hasCompany,
    required this.hasStore,
    this.storeName,
    this.storeId,
    this.storeRif,
    this.storeLogo,
    this.subcategoryId,
    this.subcategoryName,
    this.categoryId,
    this.categoryName,
  });
}

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

  OnboardingStatus({
    required this.hasCompany,
    required this.hasStore,
    this.storeName,
    this.storeId,
    this.storeRif,
    this.storeLogo,
  });
}

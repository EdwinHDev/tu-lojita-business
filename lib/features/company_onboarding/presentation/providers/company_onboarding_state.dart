class CompanyOnboardingState {
  final bool isLoading;
  final String? error;
  final bool hasStore;
  final String? detectedStoreName;
  final String? detectedStoreId;
  final String? detectedStoreRif;
  final String? detectedStoreLogo;
  final bool isNamingBranch;

  CompanyOnboardingState({
    required this.isLoading,
    this.error,
    required this.hasStore,
    this.detectedStoreName,
    this.detectedStoreId,
    this.detectedStoreRif,
    this.detectedStoreLogo,
    this.isNamingBranch = false,
  });

  factory CompanyOnboardingState.initial() {
    return CompanyOnboardingState(
      isLoading: false,
      hasStore: false,
    );
  }

  CompanyOnboardingState copyWith({
    bool? isLoading,
    String? error,
    bool? hasStore,
    String? detectedStoreName,
    String? detectedStoreId,
    String? detectedStoreRif,
    String? detectedStoreLogo,
    bool? isNamingBranch,
  }) {
    return CompanyOnboardingState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasStore: hasStore ?? this.hasStore,
      detectedStoreName: detectedStoreName ?? this.detectedStoreName,
      detectedStoreId: detectedStoreId ?? this.detectedStoreId,
      detectedStoreRif: detectedStoreRif ?? this.detectedStoreRif,
      detectedStoreLogo: detectedStoreLogo ?? this.detectedStoreLogo,
      isNamingBranch: isNamingBranch ?? this.isNamingBranch,
    );
  }
}

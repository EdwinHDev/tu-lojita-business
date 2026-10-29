class CompanyOnboardingState {
  final bool isLoading;
  final String? error;
  final bool hasStore;
  final String? detectedStoreName;
  final String? detectedStoreId;
  final String? detectedStoreRif;
  final String? detectedStoreLogo;
  final String? detectedSubcategoryId;
  final String? detectedSubcategoryName;
  final String? detectedCategoryId;
  final String? detectedCategoryName;
  final bool isNamingBranch;

  CompanyOnboardingState({
    required this.isLoading,
    this.error,
    required this.hasStore,
    this.detectedStoreName,
    this.detectedStoreId,
    this.detectedStoreRif,
    this.detectedStoreLogo,
    this.detectedSubcategoryId,
    this.detectedSubcategoryName,
    this.detectedCategoryId,
    this.detectedCategoryName,
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
    String? detectedSubcategoryId,
    String? detectedSubcategoryName,
    String? detectedCategoryId,
    String? detectedCategoryName,
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
      detectedSubcategoryId: detectedSubcategoryId ?? this.detectedSubcategoryId,
      detectedSubcategoryName: detectedSubcategoryName ?? this.detectedSubcategoryName,
      detectedCategoryId: detectedCategoryId ?? this.detectedCategoryId,
      detectedCategoryName: detectedCategoryName ?? this.detectedCategoryName,
      isNamingBranch: isNamingBranch ?? this.isNamingBranch,
    );
  }
}

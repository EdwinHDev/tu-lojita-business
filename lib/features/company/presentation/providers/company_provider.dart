import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/company_model.dart';
import '../../data/services/company_service.dart';

final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

class CompanyState {
  final bool isLoading;
  final Company? company;
  final String? error;
  final bool hasCompany;
  final bool hasStore;
  final String? storeRif;

  CompanyState({
    this.isLoading = false,
    this.company,
    this.error,
    this.hasCompany = false,
    this.hasStore = false,
    this.storeRif,
  });

  CompanyState copyWith({
    bool? isLoading,
    Company? company,
    String? error,
    bool? hasCompany,
    bool? hasStore,
    String? storeRif,
  }) {
    return CompanyState(
      isLoading: isLoading ?? this.isLoading,
      company: company ?? this.company,
      error: error,
      hasCompany: hasCompany ?? this.hasCompany,
      hasStore: hasStore ?? this.hasStore,
      storeRif: storeRif ?? this.storeRif,
    );
  }
}

class CompanyNotifier extends Notifier<CompanyState> {
  late final CompanyService _companyService;

  @override
  CompanyState build() {
    _companyService = ref.read(companyServiceProvider);
    return CompanyState();
  }

  Future<void> checkUserCompanyStatus(String token) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final companyCheck = await _companyService.checkHasCompany(token);
      
      if (companyCheck.hasCompany) {
        state = state.copyWith(
          isLoading: false,
          hasCompany: true,
        );
        return;
      }

      final storeCheck = await _companyService.checkHasStore(token);
      
      if (storeCheck.hasStore && storeCheck.storeId != null) {
        final storeDetails = await _companyService.getStoreDetails(
          storeCheck.storeId!,
          token,
        );
        
        state = state.copyWith(
          isLoading: false,
          hasCompany: false,
          hasStore: true,
          storeRif: storeDetails.rif,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          hasCompany: false,
          hasStore: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createCompany(CreateCompanyDto dto, String token) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final company = await _companyService.createCompany(dto, token);
      state = state.copyWith(
        isLoading: false,
        company: company,
        hasCompany: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = CompanyState();
  }
}

final companyProvider = NotifierProvider<CompanyNotifier, CompanyState>(
  () => CompanyNotifier(),
);

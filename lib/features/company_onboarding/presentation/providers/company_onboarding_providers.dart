import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/data/datasources/company_remote_data_source.dart';
import 'package:tu_lojita_business/features/company_onboarding/data/datasources/image_remote_data_source.dart';
import 'package:tu_lojita_business/features/company_onboarding/data/repositories/company_repository_impl.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/repositories/company_repository.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/usecases/check_onboarding_status_use_case.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/usecases/create_company_use_case.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/usecases/update_company_use_case.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/usecases/update_store_branch_name_use_case.dart';
import 'company_onboarding_state.dart';

// Data Sources
final companyRemoteDataSourceProvider = Provider<CompanyRemoteDataSource>((ref) {
  return CompanyRemoteDataSourceImpl(ref.watch(dioProvider));
});

final imageRemoteDataSourceProvider = Provider<ImageRemoteDataSource>((ref) {
  return ImageRemoteDataSourceImpl(ref.watch(dioProvider));
});

// Repository
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepositoryImpl(
    companyDataSource: ref.watch(companyRemoteDataSourceProvider),
    imageDataSource: ref.watch(imageRemoteDataSourceProvider),
  );
});

// Use Cases
final checkOnboardingStatusUseCaseProvider = Provider<CheckOnboardingStatusUseCase>((ref) {
  return CheckOnboardingStatusUseCase(ref.watch(authRepositoryProvider));
});

final createCompanyUseCaseProvider = Provider<CreateCompanyUseCase>((ref) {
  return CreateCompanyUseCase(ref.watch(companyRepositoryProvider));
});

final updateStoreBranchNameUseCaseProvider = Provider<UpdateStoreBranchNameUseCase>((ref) {
  return UpdateStoreBranchNameUseCase(ref.watch(companyRepositoryProvider));
});

final updateCompanyUseCaseProvider = Provider<UpdateCompanyUseCase>((ref) {
  return UpdateCompanyUseCase(ref.watch(companyRepositoryProvider));
});

// Notifier
class CompanyOnboardingNotifier extends Notifier<CompanyOnboardingState> {
  @override
  CompanyOnboardingState build() {
    return CompanyOnboardingState.initial();
  }

  CheckOnboardingStatusUseCase get _checkStatusUseCase => ref.read(checkOnboardingStatusUseCaseProvider);
  CreateCompanyUseCase get _createCompanyUseCase => ref.read(createCompanyUseCaseProvider);
  UpdateStoreBranchNameUseCase get _updateBranchNameUseCase => ref.read(updateStoreBranchNameUseCaseProvider);
  UpdateCompanyUseCase get _updateCompanyUseCase => ref.read(updateCompanyUseCaseProvider);

  Future<void> checkStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final status = await _checkStatusUseCase.execute();
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        hasStore: status.hasStore,
        detectedStoreName: status.storeName,
        detectedStoreId: status.storeId,
        detectedStoreRif: status.storeRif,
        detectedStoreLogo: status.storeLogo,
      );
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  Future<bool> createCompany({
    required String name,
    required String rif,
    File? logoFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _createCompanyUseCase.execute(
        name: name,
        rif: rif,
        logoFile: logoFile,
        existingLogoUrl: state.detectedStoreLogo,
      );
      
      if (!ref.mounted) return true;
      
      // Si había una tienda detectada, pasamos al paso de nombre de sucursal
      if (state.hasStore && state.detectedStoreId != null) {
        state = state.copyWith(isLoading: false, isNamingBranch: true);
        return false; // No terminamos aún
      }
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<bool> setBranchName(String branchName) async {
    if (state.detectedStoreId == null) return false;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _updateBranchNameUseCase.execute(
        storeId: state.detectedStoreId!,
        branchName: branchName,
      );
      if (!ref.mounted) return true;
      state = state.copyWith(isLoading: false, isNamingBranch: false);
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<bool> updateCompanyName({
    required String companyId,
    required String newName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _updateCompanyUseCase.execute(
        companyId: companyId,
        name: newName,
      );
      if (!ref.mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }
}

final companyOnboardingProvider = NotifierProvider<CompanyOnboardingNotifier, CompanyOnboardingState>(() {
  return CompanyOnboardingNotifier();
});

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/data/datasources/image_remote_data_source.dart';
import '../../domain/repositories/stores_repository.dart';
import 'dashboard_providers.dart';
import 'store_details_notifier.dart';
import 'store_settings_state.dart';

class StoreSettingsNotifier extends Notifier<StoreSettingsState> {
  @override
  StoreSettingsState build() {
    return StoreSettingsState.initial();
  }

  StoresRepository get _repository => ref.read(storesRepositoryProvider);
  
  // Reuse image source from company onboarding for now
  ImageRemoteDataSource get _imageDataSource => ImageRemoteDataSourceImpl(ref.read(dioProvider));

  Future<void> loadStore(String storeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final store = await _repository.getStoreById(storeId);
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        store: store,
        allowPartialPayments: store.allowPartialPayments,
        feePercentage: store.partialPaymentsFeePercentage,
        minInitialPercentage: store.minInitialPaymentPercentage,
        maxInstallments: store.maxInstallments,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updatePartialPayments(bool value) {
    state = state.copyWith(allowPartialPayments: value);
  }

  void updateFeePercentage(double value) {
    state = state.copyWith(feePercentage: value);
  }

  void updateMinInitialPercentage(double value) {
    state = state.copyWith(minInitialPercentage: value);
  }

  void updateMaxInstallments(int value) {
    state = state.copyWith(maxInstallments: value);
  }

  Future<void> pickBanner() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      state = state.copyWith(bannerFile: File(pickedFile.path));
    }
  }

  Future<bool> saveSettings(String storeId) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      String? coverImageUrl = state.store?.coverImage;

      // 1. Upload banner if changed
      if (state.bannerFile != null) {
        coverImageUrl = await _imageDataSource.uploadImage(state.bannerFile!);
        if (!ref.mounted) return true;
      }

      // 2. Update store in backend
      final updateData = {
        'coverImage': coverImageUrl,
        'allowPartialPayments': state.allowPartialPayments,
        'partialPaymentsFeePercentage': state.feePercentage,
        'minInitialPaymentPercentage': state.minInitialPercentage,
        'maxInstallments': state.maxInstallments,
      };

      final updatedStore = await _repository.updateStore(storeId, updateData);
      
      if (!ref.mounted) return true;
      
      // Sync with StoreDetails dashboard
      ref.read(storeDetailsProvider.notifier).refresh(storeId);
      
      state = state.copyWith(
        isSaving: false, 
        store: updatedStore,
        bannerFile: null, // Clear local file after success
        successMessage: 'Configuraciones guardadas correctamente',
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final storeSettingsProvider = NotifierProvider<StoreSettingsNotifier, StoreSettingsState>(() {
  return StoreSettingsNotifier();
});

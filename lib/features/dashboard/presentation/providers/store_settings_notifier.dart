import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/data/datasources/image_remote_data_source.dart';
import 'package:tu_lojita_business/core/utils/error_parser.dart';
import '../../domain/entities/store.dart';
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
        allowChat: store.allowChat,
        installmentIntervalValue: store.installmentIntervalValue,
        installmentIntervalUnit: store.installmentIntervalUnit,
        installmentFrequencyOptions: store.installmentFrequencyOptions,
        timezone: store.timezone,
        allowInstallmentExtensions: store.allowInstallmentExtensions,
        maxExtensionDays: store.maxExtensionDays,
        maxCreditLimit: store.maxCreditLimit,
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

  void updateAllowChat(bool value) {
    state = state.copyWith(allowChat: value);
  }

  void updateTimezone(String value) {
    state = state.copyWith(timezone: value);
  }

  void updateAllowInstallmentExtensions(bool value) {
    state = state.copyWith(allowInstallmentExtensions: value);
  }

  void updateMaxExtensionDays(int value) {
    state = state.copyWith(maxExtensionDays: value);
  }

  void updateMaxCreditLimit(double? value) {
    if (value == null) {
      state = state.copyWith(clearMaxCreditLimit: true);
    } else {
      state = state.copyWith(maxCreditLimit: value);
    }
  }

  void updateInstallmentInterval(int value, String unit) {
    state = state.copyWith(
      installmentIntervalValue: value,
      installmentIntervalUnit: unit,
    );
  }

  void toggleFrequencyOption(int value, String unit, String label) {
    final options = List<StoreInstallmentFrequency>.from(state.installmentFrequencyOptions);
    final existingIndex = options.indexWhere((opt) => opt.value == value && opt.unit == unit);

    if (existingIndex >= 0) {
      options.removeAt(existingIndex);
    } else {
      options.add(
          StoreInstallmentFrequency(value: value, unit: unit, label: label));
    }

    state = state.copyWith(installmentFrequencyOptions: options);
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

  Future<bool> saveSettings(String storeId, {Map<String, dynamic>? specificData}) async {
    final oldCoverImageUrl = state.store?.coverImage;
    final wasBannerChanged = state.bannerFile != null;

    state = state.copyWith(isSaving: true, error: null);
    try {
      Map<String, dynamic> updateData;

      if (specificData != null) {
        updateData = specificData;
      } else {
        String? coverImageUrl = state.store?.coverImage;

        // 1. Upload banner if changed
        if (state.bannerFile != null) {
          coverImageUrl = await _imageDataSource.uploadImage(state.bannerFile!);
          if (!ref.mounted) return true;
        }

        // 2. Default full update
        updateData = {
          'coverImage': coverImageUrl,
          'allowPartialPayments': state.allowPartialPayments,
          'partialPaymentsFeePercentage': state.feePercentage,
          'minInitialPaymentPercentage': state.minInitialPercentage,
          'maxInstallments': state.maxInstallments,
          'allowChat': state.allowChat,
          'installmentIntervalValue': state.installmentIntervalValue,
          'installmentIntervalUnit': state.installmentIntervalUnit,
          'installmentFrequencyOptions': state.installmentFrequencyOptions.map((e) => e.toJson()).toList(),
          'timezone': state.timezone,
          'allowInstallmentExtensions': state.allowInstallmentExtensions,
          'maxExtensionDays': state.maxExtensionDays,
          'maxCreditLimit': state.maxCreditLimit,
        };
      }

      final updatedStore = await _repository.updateStore(storeId, updateData);
      
      if (!ref.mounted) return true;
      
      // Sync with StoreDetails dashboard
      ref.read(storeDetailsProvider.notifier).refresh(storeId);
      
      state = state.copyWith(
        isSaving: false, 
        store: updatedStore,
        clearBannerFile: true, // Clear local file after success
        successMessage: 'Configuraciones guardadas correctamente',
      );

      // Clean up old cover image if it was replaced
      if (wasBannerChanged && oldCoverImageUrl != null && oldCoverImageUrl.isNotEmpty) {
        _imageDataSource.deleteImage(oldCoverImageUrl);
      }

      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(isSaving: false, error: ErrorParser.parse(e));
      return false;
    }
  }
}

final storeSettingsProvider = NotifierProvider<StoreSettingsNotifier, StoreSettingsState>(() {
  return StoreSettingsNotifier();
});

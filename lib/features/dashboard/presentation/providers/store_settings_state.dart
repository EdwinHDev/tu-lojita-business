import 'dart:io';
import '../../domain/entities/store.dart';

class StoreSettingsState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final Store? store;
  final File? bannerFile;
  final bool allowPartialPayments;
  final double feePercentage;
  final double minInitialPercentage;
  final int maxInstallments;

  const StoreSettingsState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.store,
    this.bannerFile,
    this.allowPartialPayments = false,
    this.feePercentage = 0.0,
    this.minInitialPercentage = 0.0,
    this.maxInstallments = 0,
  });

  factory StoreSettingsState.initial() => const StoreSettingsState();

  StoreSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    Store? store,
    File? bannerFile,
    bool? allowPartialPayments,
    double? feePercentage,
    double? minInitialPercentage,
    int? maxInstallments,
  }) {
    return StoreSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
      store: store ?? this.store,
      bannerFile: bannerFile ?? this.bannerFile,
      allowPartialPayments: allowPartialPayments ?? this.allowPartialPayments,
      feePercentage: feePercentage ?? this.feePercentage,
      minInitialPercentage: minInitialPercentage ?? this.minInitialPercentage,
      maxInstallments: maxInstallments ?? this.maxInstallments,
    );
  }
}

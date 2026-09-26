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
  final bool allowChat;
  final int installmentIntervalValue;
  final String installmentIntervalUnit;
  final List<StoreInstallmentFrequency> installmentFrequencyOptions;
  final String timezone;
  final bool allowInstallmentExtensions;
  final int maxExtensionDays;
  final double? maxCreditLimit;
  final bool isAgeRestricted;

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
    this.allowChat = true,
    this.installmentIntervalValue = 7,
    this.installmentIntervalUnit = 'DAYS',
    this.installmentFrequencyOptions = const [],
    this.timezone = 'America/Caracas',
    this.allowInstallmentExtensions = false,
    this.maxExtensionDays = 7,
    this.maxCreditLimit,
    this.isAgeRestricted = false,
  });

  factory StoreSettingsState.initial() => const StoreSettingsState();

  StoreSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    Store? store,
    File? bannerFile,
    bool clearBannerFile = false,
    bool? allowPartialPayments,
    double? feePercentage,
    double? minInitialPercentage,
    int? maxInstallments,
    bool? allowChat,
    int? installmentIntervalValue,
    String? installmentIntervalUnit,
    List<StoreInstallmentFrequency>? installmentFrequencyOptions,
    String? timezone,
    bool? allowInstallmentExtensions,
    int? maxExtensionDays,
    double? maxCreditLimit,
    bool clearMaxCreditLimit = false,
    bool? isAgeRestricted,
  }) {
    return StoreSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
      store: store ?? this.store,
      bannerFile: clearBannerFile ? null : (bannerFile ?? this.bannerFile),
      allowPartialPayments: allowPartialPayments ?? this.allowPartialPayments,
      feePercentage: feePercentage ?? this.feePercentage,
      minInitialPercentage: minInitialPercentage ?? this.minInitialPercentage,
      maxInstallments: maxInstallments ?? this.maxInstallments,
      allowChat: allowChat ?? this.allowChat,
      installmentIntervalValue: installmentIntervalValue ?? this.installmentIntervalValue,
      installmentIntervalUnit: installmentIntervalUnit ?? this.installmentIntervalUnit,
      installmentFrequencyOptions: installmentFrequencyOptions ?? this.installmentFrequencyOptions,
      timezone: timezone ?? this.timezone,
      allowInstallmentExtensions: allowInstallmentExtensions ?? this.allowInstallmentExtensions,
      maxExtensionDays: maxExtensionDays ?? this.maxExtensionDays,
      maxCreditLimit: clearMaxCreditLimit ? null : (maxCreditLimit ?? this.maxCreditLimit),
      isAgeRestricted: isAgeRestricted ?? this.isAgeRestricted,
    );
  }
}

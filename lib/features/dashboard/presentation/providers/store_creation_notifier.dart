import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StoreType { physical, virtual }

class StoreCreationState {
  final int currentStep;
  final String branchName;
  final String phone;
  final String description;
  final StoreType type;
  final String street;
  final String city;
  final String addressState;
  final String? categoryId;
  final String? subCategoryId;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final double latitude;
  final double longitude;
  final String timezone;

  StoreCreationState({
    this.currentStep = 0,
    this.branchName = '',
    this.phone = '',
    this.description = '',
    this.type = StoreType.physical,
    this.street = '',
    this.city = '',
    this.addressState = '',
    this.categoryId,
    this.subCategoryId,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.latitude = 10.4806,
    this.longitude = -66.9036,
    this.timezone = 'America/Caracas',
  });

  StoreCreationState copyWith({
    int? currentStep,
    String? branchName,
    String? phone,
    String? description,
    StoreType? type,
    String? street,
    String? city,
    String? addressState,
    String? Function()? categoryId,
    String? Function()? subCategoryId,
    String? searchQuery,
    bool? isLoading,
    String? Function()? errorMessage,
    double? latitude,
    double? longitude,
    String? timezone,
  }) {
    return StoreCreationState(
      currentStep: currentStep ?? this.currentStep,
      branchName: branchName ?? this.branchName,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      type: type ?? this.type,
      street: street ?? this.street,
      city: city ?? this.city,
      addressState: addressState ?? this.addressState,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      subCategoryId: subCategoryId != null ? subCategoryId() : this.subCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
    );
  }
}

class StoreCreationNotifier extends Notifier<StoreCreationState> {
  Timer? _debounceTimer;

  @override
  StoreCreationState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return StoreCreationState();
  }

  void setStep(int step) => state = state.copyWith(currentStep: step);
  
  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() => state = state.copyWith(currentStep: state.currentStep - 1);

  void updateBranchName(String value) => state = state.copyWith(branchName: value);
  void updatePhone(String value) => state = state.copyWith(phone: value);
  void updateDescription(String value) => state = state.copyWith(description: value);
  void updateType(StoreType value) => state = state.copyWith(type: value);
  void updateStreet(String value) => state = state.copyWith(street: value);
  void updateCity(String value) => state = state.copyWith(city: value);
  void updateState(String value) => state = state.copyWith(addressState: value);
  void updateCoordinates(double lat, double lng) => state = state.copyWith(latitude: lat, longitude: lng);
  void updateTimezone(String value) => state = state.copyWith(timezone: value);
  
  void updateCategory(String id) {
    if (state.categoryId == id) {
      clearCategory();
    } else {
      state = state.copyWith(
        categoryId: () => id,
        subCategoryId: () => null,
      );
    }
  }
  
  void updateSubCategory(String id) {
    if (state.subCategoryId == id) {
      clearSubCategory();
    } else {
      state = state.copyWith(subCategoryId: () => id);
    }
  }

  void clearCategory() => state = state.copyWith(
    categoryId: () => null,
    subCategoryId: () => null,
  );

  void clearSubCategory() => state = state.copyWith(subCategoryId: () => null);

  void updateSearchQuery(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      state = state.copyWith(searchQuery: value);
    });
  }

  bool get isFirstStepValid => state.branchName.isNotEmpty && state.phone.isNotEmpty && state.description.isNotEmpty;
  
  bool get isSecondStepValid {
    if (state.type == StoreType.virtual) return true;
    return state.street.isNotEmpty && state.city.isNotEmpty && state.addressState.isNotEmpty;
  }

  bool get isThirdStepValid => state.categoryId != null && state.subCategoryId != null;

  void setError(String? message) => state = state.copyWith(errorMessage: () => message, isLoading: false);
  void clearError() => state = state.copyWith(errorMessage: () => null);
  void setLoading(bool value) => state = state.copyWith(isLoading: value);
}

final storeCreationProvider = NotifierProvider.autoDispose<StoreCreationNotifier, StoreCreationState>(() {
  return StoreCreationNotifier();
});

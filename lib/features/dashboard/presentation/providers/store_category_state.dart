import '../../domain/entities/store_category.dart';

class StoreCategoryState {
  final List<StoreCategory> categories;
  final bool isLoading;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final String? errorMessage;
  final String? successMessage;

  const StoreCategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.errorMessage,
    this.successMessage,
  });

  StoreCategoryState copyWith({
    List<StoreCategory>? categories,
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    String? errorMessage,
    String? successMessage,
  }) {
    return StoreCategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

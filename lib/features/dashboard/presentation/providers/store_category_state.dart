import '../../domain/entities/store_category.dart';

class StoreCategoryState {
  final List<StoreCategory> categories;
  final bool isLoading;
  final bool isCreating;
  final String? errorMessage;
  final String? successMessage;

  const StoreCategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.errorMessage,
    this.successMessage,
  });

  StoreCategoryState copyWith({
    List<StoreCategory>? categories,
    bool? isLoading,
    bool? isCreating,
    String? errorMessage,
    String? successMessage,
  }) {
    return StoreCategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

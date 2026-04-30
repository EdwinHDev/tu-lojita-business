import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/store_category_repository.dart';
import 'store_category_state.dart';
import 'dashboard_providers.dart';

class StoreCategoryNotifier extends Notifier<StoreCategoryState> {
  @override
  StoreCategoryState build() {
    return const StoreCategoryState();
  }

  StoreCategoryRepository get _repository => ref.read(storeCategoryRepositoryProvider);

  Future<void> loadCategories(String storeId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final categories = await _repository.getCategoriesByStore(storeId);
      state = state.copyWith(categories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createCategory({
    required String storeId,
    required String name,
    required String description,
    List<Map<String, dynamic>>? propertyTemplates,
  }) async {
    state = state.copyWith(isCreating: true, errorMessage: null, successMessage: null);
    try {
      final newCategory = await _repository.createCategory({
        'storeId': storeId,
        'name': name,
        'description': description,
        if (propertyTemplates != null) 'propertyTemplates': propertyTemplates,
      });
      state = state.copyWith(
        categories: [...state.categories, newCategory],
        isCreating: false,
        successMessage: 'Categoría creada con éxito',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isCreating: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

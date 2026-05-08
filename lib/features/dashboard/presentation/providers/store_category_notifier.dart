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
      if (!ref.mounted) return;
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
        'propertyTemplates': ?propertyTemplates,
      });
      if (!ref.mounted) return true;
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

  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    required String description,
    List<Map<String, dynamic>>? propertyTemplates,
  }) async {
    state = state.copyWith(isUpdating: true, errorMessage: null, successMessage: null);
    try {
      final updatedCategory = await _repository.updateCategory(categoryId, {
        'name': name,
        'description': description,
        'propertyTemplates': ?propertyTemplates,
      });
      if (!ref.mounted) return true;
      final newCategories = state.categories.map((c) => c.id == categoryId ? updatedCategory : c).toList();
      state = state.copyWith(
        categories: newCategories,
        isUpdating: false,
        successMessage: 'Categoría actualizada con éxito',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    state = state.copyWith(isDeleting: true, errorMessage: null, successMessage: null);
    try {
      await _repository.deleteCategory(categoryId);
      if (!ref.mounted) return true;
      final newCategories = state.categories.where((c) => c.id != categoryId).toList();
      state = state.copyWith(
        categories: newCategories,
        isDeleting: false,
        successMessage: 'Categoría eliminada con éxito',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isDeleting: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

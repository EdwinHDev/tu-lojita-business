import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:tu_lojita_business/features/categories/data/datasources/subcategory_remote_data_source.dart';
import 'package:tu_lojita_business/features/categories/data/repositories/category_repository_impl.dart';
import 'package:tu_lojita_business/features/categories/data/repositories/subcategory_repository_impl.dart';
import 'package:tu_lojita_business/features/categories/domain/entities/category.dart';
import 'package:tu_lojita_business/features/categories/domain/entities/subcategory.dart';
import 'package:tu_lojita_business/features/categories/domain/repositories/category_repository.dart';
import 'package:tu_lojita_business/features/categories/domain/repositories/subcategory_repository.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_creation_notifier.dart';

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return CategoryRemoteDataSourceImpl(dio: dio);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final remoteDataSource = ref.watch(categoryRemoteDataSourceProvider);
  return CategoryRepositoryImpl(remoteDataSource: remoteDataSource);
});

final subcategoryRemoteDataSourceProvider = Provider<SubcategoryRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return SubcategoryRemoteDataSourceImpl(dio: dio);
});

final subcategoryRepositoryProvider = Provider<SubcategoryRepository>((ref) {
  final remoteDataSource = ref.watch(subcategoryRemoteDataSourceProvider);
  return SubcategoryRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Async Providers for fetching data
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return await repository.getCategories();
});

final subcategoriesProvider = FutureProvider.family<List<Subcategory>, String>((ref, categoryId) async {
  final repository = ref.watch(subcategoryRepositoryProvider);
  return await repository.getSubcategories(categoryId);
});

// Paginated Providers
class PaginatedCategoriesNotifier extends AsyncNotifier<List<Category>> {
  int _currentPage = 1;
  bool _hasMore = true;
  String _currentSearch = '';

  @override
  FutureOr<List<Category>> build() {
    _currentPage = 1;
    _hasMore = true;
    _currentSearch = '';
    return _fetch();
  }

  Future<List<Category>> _fetch() async {
    final repository = ref.read(categoryRepositoryProvider);
    return await repository.getCategories(
      search: _currentSearch.isEmpty ? null : _currentSearch,
      page: _currentPage,
      limit: 20,
    );
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !_hasMore) return;

    final previousData = state.value ?? [];
    
    try {
      _currentPage++;
      final nextItems = await _fetch();
      
      if (nextItems.length < 20) {
        _hasMore = false;
      }

      state = AsyncData([...previousData, ...nextItems]);
    } catch (e) {
      // Do nothing to keep previous data
    }
  }

  void updateSearch(String query) {
    if (_currentSearch == query) return;
    _currentSearch = query;
    _currentPage = 1;
    _hasMore = true;
    ref.invalidateSelf();
  }
}

final paginatedCategoriesProvider = AsyncNotifierProvider.autoDispose<PaginatedCategoriesNotifier, List<Category>>(() {
  return PaginatedCategoriesNotifier();
});

class PaginatedSubcategoriesNotifier extends AsyncNotifier<List<Subcategory>> {
  int _currentPage = 1;
  bool _hasMore = true;
  String _currentSearch = '';

  @override
  FutureOr<List<Subcategory>> build() {
    final categoryId = ref.watch(storeCreationProvider.select((s) => s.categoryId));
    _currentPage = 1;
    _hasMore = true;
    _currentSearch = '';
    
    if (categoryId == null) return [];
    return _fetch(categoryId);
  }

  Future<List<Subcategory>> _fetch(String categoryId) async {
    final repository = ref.read(subcategoryRepositoryProvider);
    return await repository.getSubcategories(
      categoryId,
      search: _currentSearch.isEmpty ? null : _currentSearch,
      page: _currentPage,
      limit: 20,
    );
  }

  Future<void> fetchNextPage() async {
    final categoryId = ref.read(storeCreationProvider).categoryId;
    if (categoryId == null || state.isLoading || !_hasMore) return;

    final previousData = state.value ?? [];
    
    try {
      _currentPage++;
      final nextItems = await _fetch(categoryId);
      
      if (nextItems.length < 20) {
        _hasMore = false;
      }

      state = AsyncData([...previousData, ...nextItems]);
    } catch (e) {
      // Do nothing to keep previous data
    }
  }

  void updateSearch(String query) {
    if (_currentSearch == query) return;
    _currentSearch = query;
    _currentPage = 1;
    _hasMore = true;
    ref.invalidateSelf();
  }
}

final paginatedSubcategoriesProvider = AsyncNotifierProvider.autoDispose<PaginatedSubcategoriesNotifier, List<Subcategory>>(() {
  return PaginatedSubcategoriesNotifier();
});

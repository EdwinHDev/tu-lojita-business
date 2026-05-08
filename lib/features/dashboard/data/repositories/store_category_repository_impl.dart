import 'package:dio/dio.dart';
import '../../domain/entities/store_category.dart';
import '../../domain/repositories/store_category_repository.dart';
import '../models/store_category_model.dart';

class StoreCategoryRepositoryImpl implements StoreCategoryRepository {
  final Dio _dio;

  StoreCategoryRepositoryImpl(this._dio);

  @override
  Future<List<StoreCategory>> getCategoriesByStore(String storeId) async {
    try {
      final response = await _dio.get('/store-categories/store/$storeId');
      return (response.data as List)
          .map((json) => StoreCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<({List<StoreCategory> categories, int total})> getCategoriesPaginated({
    required String storeId,
    int limit = 50,
    int offset = 0,
    String? q,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'limit': limit,
        'offset': offset,
      };
      if (q != null && q.isNotEmpty) {
        queryParameters['q'] = q;
      }
      final response = await _dio.get('/store-categories/store/$storeId/paginated', queryParameters: queryParameters);
      final data = response.data['data'] as List;
      final total = response.data['total'] as int;
      final categories = data.map((json) => StoreCategoryModel.fromJson(json)).toList();
      return (categories: categories, total: total);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<StoreCategory> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final response = await _dio.post('/store-categories', data: categoryData);
      return StoreCategoryModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<StoreCategory> updateCategory(String id, Map<String, dynamic> categoryData) async {
    try {
      final response = await _dio.patch('/store-categories/$id', data: categoryData);
      return StoreCategoryModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete('/store-categories/$id');
    } catch (e) {
      rethrow;
    }
  }
}

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

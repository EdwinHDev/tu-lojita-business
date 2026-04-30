import 'package:dio/dio.dart';
import 'package:tu_lojita_business/core/errors/exceptions.dart';
import 'package:tu_lojita_business/features/categories/data/models/subcategory_model.dart';

abstract class SubcategoryRemoteDataSource {
  Future<List<SubcategoryModel>> getSubcategories(
    String categoryId, {
    String? search,
    int? page,
    int? limit,
  });
}

class SubcategoryRemoteDataSourceImpl implements SubcategoryRemoteDataSource {
  final Dio dio;

  SubcategoryRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<SubcategoryModel>> getSubcategories(
    String categoryId, {
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await dio.get('/subcategories', queryParameters: {
        'categoryId': categoryId,
        'search': ?search,
        'page': ?page,
        'limit': ?limit,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SubcategoryModel.fromJson(json)).toList();
      } else {
        throw ServerException('Error al cargar las subcategorías');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

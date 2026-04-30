import 'package:dio/dio.dart';
import 'package:tu_lojita_business/core/errors/exceptions.dart';
import 'package:tu_lojita_business/features/categories/data/models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories({
    String? search,
    int? page,
    int? limit,
  });
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final Dio dio;

  CategoryRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CategoryModel>> getCategories({
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await dio.get(
        '/categories',
        queryParameters: {
          'search': ?search,
          'page': ?page,
          'limit': ?limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw ServerException('Error al cargar las categorías');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

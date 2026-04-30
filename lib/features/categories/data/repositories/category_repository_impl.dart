import 'package:tu_lojita_business/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:tu_lojita_business/features/categories/domain/entities/category.dart';
import 'package:tu_lojita_business/features/categories/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Category>> getCategories({
    String? search,
    int? page,
    int? limit,
  }) async {
    return await remoteDataSource.getCategories(
      search: search,
      page: page,
      limit: limit,
    );
  }
}

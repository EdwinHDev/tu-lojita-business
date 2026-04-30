import 'package:tu_lojita_business/features/categories/data/datasources/subcategory_remote_data_source.dart';
import 'package:tu_lojita_business/features/categories/domain/entities/subcategory.dart';
import 'package:tu_lojita_business/features/categories/domain/repositories/subcategory_repository.dart';

class SubcategoryRepositoryImpl implements SubcategoryRepository {
  final SubcategoryRemoteDataSource remoteDataSource;

  SubcategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Subcategory>> getSubcategories(
    String categoryId, {
    String? search,
    int? page,
    int? limit,
  }) async {
    return await remoteDataSource.getSubcategories(
      categoryId,
      search: search,
      page: page,
      limit: limit,
    );
  }
}

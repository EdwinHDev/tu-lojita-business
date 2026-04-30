import 'package:tu_lojita_business/features/categories/domain/entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories({
    String? search,
    int? page,
    int? limit,
  });
}

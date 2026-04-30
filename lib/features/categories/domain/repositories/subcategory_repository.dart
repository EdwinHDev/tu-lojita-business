import 'package:tu_lojita_business/features/categories/domain/entities/subcategory.dart';

abstract class SubcategoryRepository {
  Future<List<Subcategory>> getSubcategories(
    String categoryId, {
    String? search,
    int? page,
    int? limit,
  });
}

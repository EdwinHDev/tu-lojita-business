import '../entities/store_category.dart';

abstract class StoreCategoryRepository {
  Future<List<StoreCategory>> getCategoriesByStore(String storeId);
  Future<({List<StoreCategory> categories, int total})> getCategoriesPaginated({
    required String storeId,
    int limit,
    int offset,
    String? q,
  });
  Future<StoreCategory> createCategory(Map<String, dynamic> categoryData);
  Future<StoreCategory> updateCategory(String id, Map<String, dynamic> categoryData);
  Future<void> deleteCategory(String id);
}

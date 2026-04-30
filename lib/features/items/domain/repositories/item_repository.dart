import '../entities/item.dart';
import '../entities/property_template.dart';
import 'dart:io';

abstract class ItemRepository {
  Future<List<Item>> getItemsByStore(String storeId);
  
  Future<({List<Item> items, int total})> getItemsPaginated({
    required String storeId,
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String? categoryId,
    String? sortBy,
    String? order,
    bool? onlyInStock,
  });

  Future<Item> createItem(
    Map<String, dynamic> itemData, 
    List<File> images, {
    int mainImageIndex = 0,
  });
  Future<Item> updateItem(
    String id, 
    Map<String, dynamic> itemData, {
    List<File>? newImages,
    int mainImageIndex = 0,
  });
  Future<void> deleteItem(String id);
  Future<List<PropertyTemplate>> getCategoryTemplates(String categoryId);
}

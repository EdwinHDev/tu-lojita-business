import '../entities/item.dart';
import 'dart:io';

abstract class ItemRepository {
  Future<List<Item>> getItemsByStore(String storeId);
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
}

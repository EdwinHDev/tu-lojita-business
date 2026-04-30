import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/property_template.dart';
import '../../domain/repositories/item_repository.dart';
import '../models/item_model.dart';
import '../../../../core/config/envs.dart';

class ItemRepositoryImpl implements ItemRepository {
  final Dio _dio;

  ItemRepositoryImpl(this._dio);

  @override
  Future<List<Item>> getItemsByStore(String storeId) async {
    try {
      final response = await _dio.get('/items/store/$storeId');
      final data = response.data['data'] as List;
      return data.map((json) => ItemModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<({List<Item> items, int total})> getItemsPaginated({
    required String storeId,
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String? categoryId,
    String? sortBy,
    String? order,
    bool? onlyInStock,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'limit': limit,
        'offset': offset,
        'storeId': storeId,
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParameters['q'] = searchQuery;
      }
      if (categoryId != null) {
        queryParameters['storeCategoryId'] = categoryId;
      }
      if (sortBy != null) {
        queryParameters['sort'] = sortBy;
      }
      if (order != null) {
        queryParameters['order'] = order;
      }
      if (onlyInStock != null) {
        queryParameters['onlyInStock'] = onlyInStock;
      }

      final response = await _dio.get('/items', queryParameters: queryParameters);
      
      final List data = response.data['data'];
      final int total = response.data['total'];
      
      return (
        items: data.map((json) => ItemModel.fromJson(json)).toList(),
        total: total,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Item> createItem(
    Map<String, dynamic> itemData, 
    List<File> images, {
    int mainImageIndex = 0,
  }) async {
    List<String> uploadedIds = [];
    try {
      // 1. Upload images to images-processor in bulk
      final uploadResults = await _uploadImagesBulk(images, mainImageIndex);
      uploadedIds = uploadResults.map((e) => e['id'] as String).toList();
      final imageUrls = uploadResults.map((e) => e['url'] as String).toList();
      
      // 2. Add URLs and Main Image to itemData
      itemData['mainImage'] = imageUrls[mainImageIndex];
      itemData['images'] = imageUrls;

      // 3. Create item in backend
      final response = await _dio.post('/items', data: itemData);
      return ItemModel.fromJson(response.data);
    } catch (e) {
      // 4. ROLLBACK: Delete images if item creation failed
      if (uploadedIds.isNotEmpty) {
        await _deleteImagesBulk(uploadedIds);
      }
      rethrow;
    }
  }

  @override
  Future<Item> updateItem(
    String id, 
    Map<String, dynamic> itemData, {
    List<File>? newImages,
    int mainImageIndex = 0,
  }) async {
    try {
      if (newImages != null && newImages.isNotEmpty) {
        final uploadResults = await _uploadImagesBulk(newImages, mainImageIndex);
        final imageUrls = uploadResults.map((e) => e['url'] as String).toList();
        
        itemData['mainImage'] = imageUrls[mainImageIndex];
        itemData['images'] = imageUrls;
      }

      final response = await _dio.patch('/items/$id', data: itemData);
      return ItemModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    try {
      await _dio.delete('/items/$id');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PropertyTemplate>> getCategoryTemplates(String categoryId) async {
    try {
      final response = await _dio.get('/store-categories/$categoryId/templates');
      final data = response.data as List;
      return data.map((json) => PropertyTemplate.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _uploadImagesBulk(List<File> images, int primaryIndex) async {
    final dioImages = Dio(BaseOptions(
      baseUrl: Envs.apiBaseUrlImages,
      headers: {
        'x-api-key': Envs.apiKeyImages,
      },
    ));

    final formData = FormData();
    formData.fields.add(MapEntry('primaryIndex', primaryIndex.toString()));
    
    for (var file in images) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(file.path),
      ));
    }

    final response = await dioImages.post('/upload/bulk', data: formData);
    
    if (response.data['status'] == 'success') {
      final results = response.data['data'] as List;
      return results.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Error uploading images');
    }
  }

  Future<void> _deleteImagesBulk(List<String> ids) async {
    try {
      final dioImages = Dio(BaseOptions(
        baseUrl: Envs.apiBaseUrlImages,
        headers: {
          'x-api-key': Envs.apiKeyImages,
        },
      ));

      await dioImages.post('/img/bulk-delete', data: {'ids': ids});
    } catch (e) {
      // Image rollback failed - silent fail as the main error is already being propagated
    }
  }
}

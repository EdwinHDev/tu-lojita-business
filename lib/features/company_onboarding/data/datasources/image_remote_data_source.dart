import 'dart:io';
import 'package:dio/dio.dart';
import 'package:tu_lojita_business/core/config/envs.dart';

abstract class ImageRemoteDataSource {
  Future<String> uploadImage(File file);
  Future<void> deleteImage(String imageUrl);
}

class ImageRemoteDataSourceImpl implements ImageRemoteDataSource {
  final Dio _dio;

  ImageRemoteDataSourceImpl(this._dio);

  @override
  Future<String> uploadImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final response = await _dio.post(
        '${Envs.apiBaseUrlImages}/upload',
        data: formData,
        options: Options(
          headers: {
            'x-api-key': Envs.apiKeyImages,
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return data['data']['url'] as String;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to upload image',
      );
    }
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      // imageUrl is usually like /img/UUID
      final imageId = imageUrl.split('/').last;
      
      await _dio.delete(
        '${Envs.apiBaseUrlImages}/img/$imageId',
        options: Options(
          headers: {
            'x-api-key': Envs.apiKeyImages,
          },
        ),
      );
    } on DioException catch (_) {
      // We log but don't necessarily throw if deletion fails during rollback
    }
  }
}

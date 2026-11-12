import 'dart:io';
import 'package:dio/dio.dart';
import 'package:tu_lojita_business/core/config/envs.dart';

import 'package:http_parser/http_parser.dart';

abstract class ImageRemoteDataSource {
  Future<String> uploadImage(File file);
  Future<void> deleteImage(String imageUrl);
}

class ImageRemoteDataSourceImpl implements ImageRemoteDataSource {
  final Dio _dio;

  ImageRemoteDataSourceImpl(this._dio);

  @override
  Future<String> uploadImage(File file) async {
    final fileName = file.path.split('/').last.split('\\').last;
    final ext = fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';

    DioException? lastException;
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: MediaType('image', ext),
          ),
        });

        final response = await _dio.post(
          '${Envs.apiBaseUrlImages}/upload',
          data: formData,
          options: Options(
            headers: {
              'x-api-key': Envs.apiKeyImages,
            },
            sendTimeout: const Duration(seconds: 45),
            receiveTimeout: const Duration(seconds: 45),
          ),
        );

        final data = response.data as Map<String, dynamic>;
        return data['data']['url'] as String;
      } on DioException catch (e) {
        lastException = e;
        if (attempt == 1) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    }

    throw Exception(
      lastException?.response?.data?['message'] ??
          lastException?.message ??
          'Error al subir imagen al servidor. Verifica tu conexión a internet.',
    );
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      final trimmed = imageUrl.trim();
      if (trimmed.isEmpty) return;

      final uri = Uri.tryParse(trimmed);
      final segments =
          uri?.pathSegments.where((s) => s.isNotEmpty).toList() ?? [];
      final fallbackSegments = trimmed
          .split('?')
          .first
          .split('/')
          .where((s) => s.isNotEmpty)
          .toList();
      final lastSegment = segments.isNotEmpty
          ? segments.last
          : (fallbackSegments.isNotEmpty ? fallbackSegments.last : '');
      final imageId = lastSegment.split('.').first;
      if (imageId.isEmpty) return;

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

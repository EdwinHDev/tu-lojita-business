import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:tu_lojita_business/core/utils/error_parser.dart';
import '../../domain/entities/store_ai_models.dart';

class StoreAiRemoteDataSource {
  final Dio _dio;

  StoreAiRemoteDataSource(this._dio);

  StoreAiException _parseDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final code = data['code']?.toString();
      final rawMessage = data['message'];
      String? msg;
      if (rawMessage is List && rawMessage.isNotEmpty) {
        msg = rawMessage.first.toString();
      } else if (rawMessage != null) {
        msg = rawMessage.toString();
      }

      if (msg != null && msg.trim().isNotEmpty) {
        return StoreAiException(
          message: msg,
          code: code,
          statusCode: status,
        );
      }
    }

    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return const StoreAiException(
        message:
            'La generación con IA tardó más de lo esperado. Verifica tu conexión e inténtalo de nuevo.',
        code: 'GEMINI_TIMEOUT',
      );
    }

    return StoreAiException(
      message: ErrorParser.parse(e),
      statusCode: status,
    );
  }

  Future<StoreAiSettings> getSettings(String storeId) async {
    try {
      final response = await _dio.get('/stores/$storeId/ai-image/settings');
      return StoreAiSettings.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<StoreAiKeyTestResult> testKey(
    String storeId, {
    required String apiKey,
    bool saveIfValid = true,
  }) async {
    try {
      final response = await _dio.post(
        '/stores/$storeId/ai-image/test-key',
        data: {
          'apiKey': apiKey.trim(),
          'saveIfValid': saveIfValid,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return StoreAiKeyTestResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<StoreAiSettings> updateSettings(
    String storeId, {
    bool? isEnabled,
    int? dailyLimit,
    List<StoreSavedPrompt>? customPrompts,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (isEnabled != null) {
        payload['isEnabled'] = isEnabled;
      }
      if (dailyLimit != null) {
        payload['dailyLimit'] = dailyLimit;
      }
      if (customPrompts != null) {
        payload['customPrompts'] = customPrompts.map((p) => p.toJson()).toList();
      }
      final response = await _dio.patch(
        '/stores/$storeId/ai-image/settings',
        data: payload,
      );
      return StoreAiSettings.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<StoreAiSettings> deleteKey(String storeId) async {
    try {
      final response = await _dio.delete(
        '/stores/$storeId/ai-image/settings/key',
      );
      return StoreAiSettings.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<StoreAiCatalog> getCatalog(String storeId) async {
    try {
      final response = await _dio.get('/stores/$storeId/ai-image/catalog');
      return StoreAiCatalog.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<AiEnhancedImageResult> enhanceImage(
    String storeId, {
    required Uint8List imageBytes,
    required String fileName,
    required String mimeType,
    String? presetId,
    String? storePromptId,
    String? customPrompt,
  }) async {
    try {
      final parts = mimeType.split('/');
      final mediaType = parts.length == 2
          ? MediaType(parts[0], parts[1])
          : MediaType('image', 'jpeg');

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
          contentType: mediaType,
        ),
        if (presetId != null && presetId.isNotEmpty) 'presetId': presetId,
        if (storePromptId != null && storePromptId.isNotEmpty)
          'storePromptId': storePromptId,
        if (customPrompt != null && customPrompt.trim().isNotEmpty)
          'customPrompt': customPrompt.trim(),
      });

      final response = await _dio.post(
        '/stores/$storeId/ai-image/enhance',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      return AiEnhancedImageResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }
}

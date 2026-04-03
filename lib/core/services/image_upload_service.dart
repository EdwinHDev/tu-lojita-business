import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import '../config/env_config.dart';

class ImageUploadService {
  final String baseUrl = EnvConfig.apiBaseUrlImages;
  final String apiKey = EnvConfig.apiKeyImages;

  Future<String> uploadImage(File imageFile) async {
    try {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final uri = Uri.parse('$baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['x-api-key'] = apiKey;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(responseBody);
        final imageUrl = data['data']['url'] as String; // /img/id
        return imageUrl;
      } else {
        throw Exception('Error al subir imagen: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  Future<void> deleteImage(String imageId) async {
    try {
      final uri = Uri.parse('$baseUrl/img/bulk-delete');
      final response = await http.post(
        uri,
        headers: {
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'ids': [imageId],
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al eliminar imagen: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  String getImageUrl(String imageId, {int? width, int? height, String? format}) {
    final params = <String, String>{};
    if (width != null) params['w'] = width.toString();
    if (height != null) params['h'] = height.toString();
    if (format != null) params['fmt'] = format;

    final queryString = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    return '$baseUrl/img/$imageId$queryString';
  }
}

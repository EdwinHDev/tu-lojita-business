import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/auth_response_entity.dart';
import '../../domain/entities/backend_user_entity.dart';
import '../models/auth_response_model.dart';
import '../models/backend_user_model.dart';
import '../../../../core/config/env_config.dart';

abstract class BackendAuthDataSource {
  Future<AuthResponseEntity> authenticateWithBackend(String googleIdToken);
  Future<AuthResponseEntity> refreshTokens(String refreshToken);
  Future<BackendUserEntity?> checkAuthStatus(String accessToken);
}

class BackendAuthDataSourceImpl implements BackendAuthDataSource {
  final http.Client httpClient;

  BackendAuthDataSourceImpl({required this.httpClient});

  @override
  Future<AuthResponseEntity> authenticateWithBackend(String googleIdToken) async {
    try {
      final response = await httpClient.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/auth/google'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': googleIdToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AuthResponseModel.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Error al autenticar con el servidor',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión con el servidor: $e');
    }
  }

  @override
  Future<AuthResponseEntity> refreshTokens(String refreshToken) async {
    try {
      final response = await httpClient.get(
        Uri.parse('${EnvConfig.apiBaseUrl}/auth/refresh'),
        headers: {
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AuthResponseModel.fromJson(data);
      } else {
        throw Exception('Error al refrescar tokens');
      }
    } catch (e) {
      throw Exception('Error al refrescar tokens: $e');
    }
  }

  @override
  Future<BackendUserEntity?> checkAuthStatus(String accessToken) async {
    try {
      final response = await httpClient.get(
        Uri.parse('${EnvConfig.apiBaseUrl}/auth/check-status'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return BackendUserModel.fromJson(data['user']);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsis;
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/utils/error_parser.dart';
import 'package:tu_lojita_business/features/auth/domain/exceptions/auth_exceptions.dart';

abstract class RemoteAuthDataSource {
  Future<String> getGoogleIdToken();
  Future<Map<String, dynamic>> loginWithBackend(String idToken);
  Future<Map<String, dynamic>> refreshTokens(String refreshToken);
  Future<Map<String, dynamic>> checkHasCompany();
  Future<Map<String, dynamic>> checkHasStore();
  Future<Map<String, dynamic>> checkAuthStatus();
}

class RemoteAuthDataSourceImpl implements RemoteAuthDataSource {
  final Dio _dio;
  final gsis.GoogleSignIn _googleSignIn = gsis.GoogleSignIn.instance;

  RemoteAuthDataSourceImpl(this._dio);

  @override
  Future<String> getGoogleIdToken() async {
    try {
      await _googleSignIn.initialize(
        clientId: Envs.googleAndroidClientId,
        serverClientId: Envs.googleServerClientId,
      );
      final account = await _googleSignIn.authenticate();
      final authData = account.authentication;
      final idToken = authData.idToken;

      if (idToken == null) {
        throw AuthException('Could not retrieve Google ID Token');
      }

      return idToken;
    } catch (e) {
      if (e is GoogleSignInCancelledException) rethrow;
      throw AuthException('Google Sign-In failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> loginWithBackend(String idToken) async {
    try {
      final response = await _dio.post(
        '/auth/google',
        data: {'token': idToken},
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw BackendAuthenticationException(ErrorParser.parse(e));
    }
  }

  @override
  Future<Map<String, dynamic>> refreshTokens(String refreshToken) async {
    try {
      final response = await _dio.get(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw TokenExpiredException(ErrorParser.parse(e));
    }
  }

  @override
  Future<Map<String, dynamic>> checkHasCompany() async {
    try {
      final response = await _dio.get('/users/check/has-company');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AuthException(ErrorParser.parse(e));
    }
  }

  @override
  Future<Map<String, dynamic>> checkHasStore() async {
    try {
      final response = await _dio.get('/users/check/has-store');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AuthException(ErrorParser.parse(e));
    }
  }

  @override
  Future<Map<String, dynamic>> checkAuthStatus() async {
    try {
      final response = await _dio.get('/auth/check-status');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AuthException(ErrorParser.parse(e));
    }
  }
}

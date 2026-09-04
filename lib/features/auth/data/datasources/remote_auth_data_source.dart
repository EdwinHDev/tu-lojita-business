import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsis;
import 'package:tu_lojita_business/core/utils/error_parser.dart';
import 'package:tu_lojita_business/features/auth/domain/exceptions/auth_exceptions.dart';

abstract class RemoteAuthDataSource {
  Future<String> getGoogleIdToken();
  Future<Map<String, dynamic>> loginWithBackend(String idToken);
  Future<Map<String, dynamic>> refreshTokens(String refreshToken);
  Future<Map<String, dynamic>> checkHasCompany();
  Future<Map<String, dynamic>> checkHasStore();
  Future<Map<String, dynamic>> checkAuthStatus();
  Future<Map<String, dynamic>> updateProfile(String? identification, String? phone);
  Future<void> signOut();
}

class RemoteAuthDataSourceImpl implements RemoteAuthDataSource {
  final Dio _dio;
  final gsis.GoogleSignIn _googleSignIn = gsis.GoogleSignIn.instance;

  RemoteAuthDataSourceImpl(this._dio);

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  @override
  Future<String> getGoogleIdToken() async {
    try {
      gsis.GoogleSignInAccount account;
      try {
        account = await _googleSignIn.authenticate();
      } catch (e) {
        final errStr = e.toString();
        // Fallo de reautenticación en Android
        if (errStr.contains('16') || errStr.contains('reauth')) {
          await _googleSignIn.signOut();
          account = await _googleSignIn.authenticate();
        } else {
          rethrow;
        }
      }

      final authData = account.authentication;
      final idToken = authData.idToken;

      if (idToken == null) {
        throw AuthException('Could not retrieve Google ID Token');
      }

      return idToken;
    } catch (e) {
      if (e is GoogleSignInCancelledException) rethrow;
      final errStr = e.toString();
      if (errStr.contains('GoogleSignInExceptionCode.canceled')) {
        throw GoogleSignInCancelledException();
      }
      throw AuthException('Google Sign-In failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> loginWithBackend(String idToken) async {
    try {
      final response = await _dio.post(
        '/auth/google',
        data: {
          'token': idToken,
          'appOrigin': 'BUSINESS',
        },
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

  @override
  Future<Map<String, dynamic>> updateProfile(String? identification, String? phone) async {
    try {
      final response = await _dio.patch(
        '/users/profile',
        data: <String, dynamic>{
          'identification': identification,
          'phone': phone,
        }..removeWhere((key, value) => value == null),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AuthException(ErrorParser.parse(e));
    }
  }
}

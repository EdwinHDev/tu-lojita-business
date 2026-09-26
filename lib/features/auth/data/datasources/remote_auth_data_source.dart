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
  Future<Map<String, dynamic>> loginWithEmailPassword(String email, String password);
  Future<Map<String, dynamic>> registerWithEmailPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });
  Future<Map<String, dynamic>> requestRegistrationOtp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
    String? phone,
    String? identification,
    String appOrigin,
  });
  Future<Map<String, dynamic>> verifyRegistrationOtp({
    required String registrationToken,
    required String otp,
  });
  Future<Map<String, dynamic>> resendRegistrationOtp({
    required String registrationToken,
  });
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
      final account = await _googleSignIn.authenticate();
      final authData = account.authentication;
      final idToken = authData.idToken;

      if (idToken == null) {
        throw AuthException('No pudimos obtener las credenciales de tu cuenta de Google. Intenta de nuevo.');
      }

      return idToken;
    } catch (e) {
      if (e is GoogleSignInCancelledException) rethrow;
      if (e is AuthException) rethrow;

      final errStr = e.toString().toLowerCase();

      // Detect Play Services / OAuth configuration / developer errors:
      // Code 10: DEVELOPER_ERROR (SHA-1 / package name mismatch, unpropagated keys)
      // Code 16: CANCELLED / reauth failure from internal Play Services
      // Code 12500: SIGN_IN_FAILED
      final isConfigOrPlayServicesError = errStr.contains('10') ||
          errStr.contains('16') ||
          errStr.contains('12500') ||
          errStr.contains('developer_error') ||
          errStr.contains('sign_in_failed') ||
          errStr.contains('apiexception') ||
          errStr.contains('clientconfigurationerror');

      // Detect network and connection issues
      final isNetworkError = errStr.contains('network') ||
          errStr.contains('socket') ||
          errStr.contains('timeout') ||
          errStr.contains('connection');

      // Disambiguate voluntary user cancellation from Google Play Services failure
      final isVoluntaryCancellation = !isConfigOrPlayServicesError &&
          !isNetworkError &&
          (errStr.contains('canceled') ||
              errStr.contains('cancelled') ||
              (e is gsis.GoogleSignInException &&
                  e.code == gsis.GoogleSignInExceptionCode.canceled));

      if (isVoluntaryCancellation) {
        throw GoogleSignInCancelledException();
      }

      if (isNetworkError) {
        throw AuthException('Comprueba tu conexión a internet e inténtalo de nuevo.');
      }

      if (isConfigOrPlayServicesError) {
        throw AuthException(
          'No pudimos verificar tu cuenta de Google en este momento. Por favor, intenta de nuevo en unos minutos.',
        );
      }

      throw AuthException('No pudimos iniciar sesión con Google. Por favor, intenta de nuevo.');
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

  @override
  Future<Map<String, dynamic>> loginWithEmailPassword(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'appOrigin': 'BUSINESS',
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw BackendAuthenticationException('Las credenciales ingresadas no son válidas.');
      }
      throw BackendAuthenticationException(ErrorParser.parse(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> registerWithEmailPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _dio.post(
        '/users',
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'appOrigin': 'BUSINESS',
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw BackendAuthenticationException(ErrorParser.parse(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> requestRegistrationOtp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
    String? phone,
    String? identification,
    String appOrigin = 'BUSINESS',
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/request-otp',
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (identification != null && identification.isNotEmpty) 'identification': identification,
          'appOrigin': appOrigin,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw BackendAuthenticationException(ErrorParser.parse(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> verifyRegistrationOtp({
    required String registrationToken,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/verify-otp',
        data: {
          'registrationToken': registrationToken,
          'otp': otp,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw BackendAuthenticationException(ErrorParser.parse(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> resendRegistrationOtp({
    required String registrationToken,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/resend-otp',
        data: {
          'registrationToken': registrationToken,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw BackendAuthenticationException(ErrorParser.parse(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }
}

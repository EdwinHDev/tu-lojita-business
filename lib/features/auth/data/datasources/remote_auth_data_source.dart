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
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<Map<String, dynamic>> requestForgotPasswordOtp({
    required String email,
    String appOrigin = 'BUSINESS',
  });
  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String recoveryToken,
    required String otp,
  });
  Future<Map<String, dynamic>> resendForgotPasswordOtp({
    required String recoveryToken,
  });
  Future<void> resetPasswordWithToken({
    required String resetSessionToken,
    required String newPassword,
  });
  Future<Map<String, dynamic>> loginWithCollaboratorCredentials(
    String accessId,
    String password,
  );
  Future<void> changeCollaboratorPassword({
    required String currentPassword,
    required String newPassword,
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
      if (e.response?.statusCode == 403) {
        final data = e.response?.data;
        if (data is Map &&
            (data['code'] == 'ACCOUNT_SUSPENDED' ||
                data['code'] == 'ACCOUNT_BANNED' ||
                (data['message']?.toString().toLowerCase().contains('suspendida') ?? false))) {
          final isPermanent = data['isPermanent'] == true ||
              data['code'] == 'ACCOUNT_BANNED' ||
              data['suspendedUntil'] == null;
          throw AccountSuspendedException(
            message: data['message']?.toString() ??
                (isPermanent
                    ? 'Tu cuenta comercial ha sido suspendida permanentemente.'
                    : 'Tu cuenta comercial está suspendida temporalmente.'),
            suspendedUntil: data['suspendedUntil']?.toString(),
            reason: data['reason']?.toString(),
            isPermanent: isPermanent,
          );
        }
      }
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
      if (e.response?.statusCode == 403) {
        final data = e.response?.data;
        if (data is Map &&
            (data['code'] == 'ACCOUNT_SUSPENDED' ||
                data['code'] == 'ACCOUNT_BANNED' ||
                (data['message']?.toString().toLowerCase().contains('suspendida') ?? false))) {
          final isPermanent = data['isPermanent'] == true ||
              data['code'] == 'ACCOUNT_BANNED' ||
              data['suspendedUntil'] == null;
          throw AccountSuspendedException(
            message: data['message']?.toString() ??
                (isPermanent
                    ? 'Tu cuenta comercial ha sido suspendida permanentemente.'
                    : 'Tu cuenta comercial está suspendida temporalmente.'),
            suspendedUntil: data['suspendedUntil']?.toString(),
            reason: data['reason']?.toString(),
            isPermanent: isPermanent,
          );
        }
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

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.patch(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw BackendAuthenticationException(ErrorParser.parse(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> requestForgotPasswordOtp({
    required String email,
    String appOrigin = 'BUSINESS',
  }) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password/request-otp',
        data: {
          'email': email.trim(),
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
  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String recoveryToken,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password/verify-otp',
        data: {
          'recoveryToken': recoveryToken,
          'otp': otp.trim(),
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
  Future<Map<String, dynamic>> resendForgotPasswordOtp({
    required String recoveryToken,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password/resend-otp',
        data: {
          'recoveryToken': recoveryToken,
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
  Future<void> resetPasswordWithToken({
    required String resetSessionToken,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password/reset-password',
        data: {
          'resetSessionToken': resetSessionToken,
          'newPassword': newPassword,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw AuthException('Error al restablecer la contraseña.');
      }
    } on DioException catch (e) {
      throw BackendAuthenticationException(ErrorParser.parse(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> loginWithCollaboratorCredentials(
    String accessId,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/collaborator-login',
        data: {
          'accessId': accessId.trim(),
          'password': password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw BackendAuthenticationException('Credenciales inválidas. Revisa tu ID de 8 dígitos y contraseña.');
      }
      if (e.response?.statusCode == 403) {
        throw BackendAuthenticationException('Tu cuenta de colaborador ha sido desactivada por la empresa.');
      }
      if (e.response?.statusCode == 429) {
        throw BackendAuthenticationException(
          'Demasiados intentos fallidos. Tu acceso está temporalmente bloqueado por 15 minutos.',
        );
      }
      throw AuthException(ErrorParser.parse(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> changeCollaboratorPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/collaborator-change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw BackendAuthenticationException(ErrorParser.parse(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/auth/data/datasources/local_auth_data_source.dart';

class AuthInterceptor extends Interceptor {
  final LocalAuthDataSource _localDataSource;
  final Dio _dio; // To retry requests

  AuthInterceptor(this._localDataSource, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _localDataSource.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Avoid infinite loop if the 401 error is from the refresh endpoint itself
      if (err.requestOptions.path.contains('/auth/refresh')) {
        await _localDataSource.clearAll();
        return handler.next(err);
      }

      final refreshToken = await _localDataSource.getRefreshToken();

      if (refreshToken != null) {
        String? newAccessToken;
        String? newRefreshToken;

        try {
          // Attempt to refresh token
          // Using a separate Dio or avoiding this interceptor for the refresh call
          final response = await Dio(BaseOptions(baseUrl: Envs.apiBaseUrl)).get(
            '/auth/refresh',
            options: Options(
              headers: {'Authorization': 'Bearer $refreshToken'},
            ),
          );

          newAccessToken = response.data['accessToken'];
          newRefreshToken = response.data['refreshToken'];

          if (newAccessToken != null && newRefreshToken != null) {
            await _localDataSource.saveAccessToken(newAccessToken);
            await _localDataSource.saveRefreshToken(newRefreshToken);
          }
        } catch (e, stackTrace) {
          // If refresh fails, log error, clear everything and propagate error
          debugPrint('Token refresh failed: $e');
          debugPrint(stackTrace.toString());
          await _localDataSource.clearAll();
          return handler.next(err);
        }

        if (newAccessToken != null) {
          try {
            // Retry the original request
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await _dio.fetch(options);
            return handler.resolve(retryResponse);
          } catch (e) {
            // If the retry fails for non-auth reasons, do not clear storage, just propagate
            debugPrint('Retry request failed: $e');
            if (e is DioException) {
              return handler.next(e);
            }
            return handler.next(err);
          }
        }
      } else {
        await _localDataSource.clearAll();
      }
    }

    return handler.next(err);
  }
}

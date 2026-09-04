import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/auth/data/datasources/local_auth_data_source.dart';

class AuthInterceptor extends QueuedInterceptor {
  final LocalAuthDataSource _localDataSource;
  final Dio _dio; // To retry requests

  AuthInterceptor(this._localDataSource, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _localDataSource.getAccessToken();

    if (token != null && token.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${token.trim()}';
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
          final tempDio = Dio(
            BaseOptions(
              baseUrl: Envs.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

          final response = await tempDio.get(
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
        } on DioException catch (dioErr) {
          final statusCode = dioErr.response?.statusCode;
          if (statusCode == 401 || statusCode == 403) {
            debugPrint('Business AuthInterceptor: Refresh token rejected with HTTP $statusCode. Clearing session...');
            await _localDataSource.clearAll();
          } else {
            debugPrint('Business AuthInterceptor: Transient error during refresh ($statusCode / $dioErr). Preserving session.');
          }
          return handler.next(err);
        } catch (e, stackTrace) {
          debugPrint('Business AuthInterceptor: Unexpected error during refresh: $e');
          debugPrint(stackTrace.toString());
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
            debugPrint('Business Retry request failed: $e');
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

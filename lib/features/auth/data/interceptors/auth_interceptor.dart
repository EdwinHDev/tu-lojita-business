import 'package:dio/dio.dart';
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
      final refreshToken = await _localDataSource.getRefreshToken();

      if (refreshToken != null) {
        try {
          // Attempt to refresh token
          // Using a separate Dio or avoiding this interceptor for the refresh call
          final response = await Dio(BaseOptions(baseUrl: Envs.apiBaseUrl)).get(
            '/auth/refresh',
            options: Options(
              headers: {'Authorization': 'Bearer $refreshToken'},
            ),
          );

          final newAccessToken = response.data['accessToken'];
          final newRefreshToken = response.data['refreshToken'];

          await _localDataSource.saveAccessToken(newAccessToken);
          await _localDataSource.saveRefreshToken(newRefreshToken);

          // Retry the original request
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await _dio.fetch(options);
          return handler.resolve(retryResponse);
        } catch (e) {
          // If refresh fails, clear everything and propagate error
          await _localDataSource.clearAll();
          // Here we could trigger a global logout event
        }
      } else {
        await _localDataSource.clearAll();
      }
    }

    return handler.next(err);
  }
}

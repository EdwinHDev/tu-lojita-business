import '../../domain/entities/auth_response_entity.dart';
import '../../domain/repositories/backend_auth_repository.dart';
import '../datasources/backend_auth_datasource.dart';
import '../../../../core/services/token_storage_service.dart';

class BackendAuthRepositoryImpl implements BackendAuthRepository {
  final BackendAuthDataSource dataSource;
  final TokenStorageService tokenStorage;

  BackendAuthRepositoryImpl({
    required this.dataSource,
    required this.tokenStorage,
  });

  @override
  Future<AuthResponseEntity> authenticateWithBackend(String googleIdToken) async {
    final authResponse = await dataSource.authenticateWithBackend(googleIdToken);
    await saveTokens(
      authResponse.tokens.accessToken,
      authResponse.tokens.refreshToken,
    );
    return authResponse;
  }

  @override
  Future<AuthResponseEntity> refreshTokens(String refreshToken) async {
    final authResponse = await dataSource.refreshTokens(refreshToken);
    await saveTokens(
      authResponse.tokens.accessToken,
      authResponse.tokens.refreshToken,
    );
    return authResponse;
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<String?> getAccessToken() async {
    return await tokenStorage.getAccessToken();
  }

  @override
  Future<String?> getRefreshToken() async {
    return await tokenStorage.getRefreshToken();
  }

  @override
  Future<void> clearTokens() async {
    await tokenStorage.deleteTokens();
  }
}

import '../entities/auth_response_entity.dart';

abstract class BackendAuthRepository {
  Future<AuthResponseEntity> authenticateWithBackend(String googleIdToken);
  Future<AuthResponseEntity> refreshTokens(String refreshToken);
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
}

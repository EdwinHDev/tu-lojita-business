import '../entities/auth_response_entity.dart';
import '../entities/backend_user_entity.dart';

abstract class BackendAuthRepository {
  Future<AuthResponseEntity> authenticateWithBackend(String googleIdToken);
  Future<AuthResponseEntity> refreshTokens(String refreshToken);
  Future<BackendUserEntity?> checkAuthStatus();
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
}

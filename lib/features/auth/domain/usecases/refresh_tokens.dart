import '../repositories/backend_auth_repository.dart';
import '../entities/auth_response_entity.dart';

class RefreshTokens {
  final BackendAuthRepository repository;

  RefreshTokens({required this.repository});

  Future<AuthResponseEntity?> call() async {
    final refreshToken = await repository.getRefreshToken();
    if (refreshToken == null) {
      return null;
    }
    return await repository.refreshTokens(refreshToken);
  }
}

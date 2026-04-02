import '../entities/auth_response_entity.dart';
import '../repositories/backend_auth_repository.dart';

class AuthenticateWithBackend {
  final BackendAuthRepository repository;

  AuthenticateWithBackend({required this.repository});

  Future<AuthResponseEntity> call(String googleIdToken) async {
    return await repository.authenticateWithBackend(googleIdToken);
  }
}

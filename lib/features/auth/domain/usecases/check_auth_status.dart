import '../repositories/backend_auth_repository.dart';
import '../entities/backend_user_entity.dart';

class CheckAuthStatus {
  final BackendAuthRepository repository;

  CheckAuthStatus({required this.repository});

  Future<BackendUserEntity?> call() async {
    return await repository.checkAuthStatus();
  }
}

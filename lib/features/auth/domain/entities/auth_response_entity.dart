import 'backend_user_entity.dart';
import 'auth_tokens_entity.dart';

class AuthResponseEntity {
  final BackendUserEntity user;
  final AuthTokensEntity tokens;

  const AuthResponseEntity({
    required this.user,
    required this.tokens,
  });
}

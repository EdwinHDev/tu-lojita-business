import '../../domain/entities/auth_response_entity.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import 'backend_user_model.dart';

class AuthResponseModel extends AuthResponseEntity {
  const AuthResponseModel({
    required super.user,
    required super.tokens,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: BackendUserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokensEntity(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      ),
    );
  }
}

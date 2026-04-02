import '../../domain/entities/backend_user_entity.dart';

class BackendUserModel extends BackendUserEntity {
  const BackendUserModel({
    required super.id,
    required super.firstName,
    super.lastName,
    required super.email,
    super.avatarUrl,
  });

  factory BackendUserModel.fromJson(Map<String, dynamic> json) {
    return BackendUserModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }
}

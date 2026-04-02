class UserEntity {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? idToken;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.idToken,
  });
}

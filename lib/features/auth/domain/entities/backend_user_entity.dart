class BackendUserEntity {
  final String id;
  final String firstName;
  final String? lastName;
  final String email;
  final String? avatarUrl;

  const BackendUserEntity({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.email,
    this.avatarUrl,
  });

  String get fullName {
    if (lastName != null && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName;
  }
}

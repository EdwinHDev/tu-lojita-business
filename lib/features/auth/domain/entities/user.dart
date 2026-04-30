import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String role;
  final bool hasCompany;
  final Company? company;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.hasCompany = false,
    this.avatarUrl,
    this.company,
  });

  String get fullName => '$firstName $lastName';

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? role,
    bool? hasCompany,
    Company? company,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      hasCompany: hasCompany ?? this.hasCompany,
      company: company ?? this.company,
    );
  }
}

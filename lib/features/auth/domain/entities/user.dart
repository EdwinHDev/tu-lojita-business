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
  final String? identification;
  final String? phone;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.hasCompany = false,
    this.avatarUrl,
    this.company,
    this.identification,
    this.phone,
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
    String? identification,
    String? phone,
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
      identification: identification ?? this.identification,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'role': role,
      'hasCompany': hasCompany,
      'identification': identification,
      'phone': phone,
    };
  }
}

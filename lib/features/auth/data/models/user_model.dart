import 'package:tu_lojita_business/features/company_onboarding/data/models/company_model.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.role,
    super.hasCompany = false,
    super.avatarUrl,
    super.company,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String? ?? 'USER',
      hasCompany: json['hasCompany'] as bool? ?? (json['company'] != null),
      avatarUrl: json['avatarUrl'] as String?,
      company: json['company'] != null ? CompanyModel.fromJson(json['company'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'hasCompany': hasCompany,
      'avatarUrl': avatarUrl,
      'company': company != null ? (company as CompanyModel).toJson() : null,
    };
  }

  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? role,
    bool? hasCompany,
    Company? company,
  }) {
    return UserModel(
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

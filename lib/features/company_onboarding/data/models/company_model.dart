import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';

class CompanyModel extends Company {
  const CompanyModel({
    required super.id,
    required super.name,
    required super.rif,
    required super.logo,
    super.phone,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      rif: json['rif'] as String,
      logo: json['logo'] as String,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rif': rif,
      'logo': logo,
      'phone': phone,
    };
  }
}

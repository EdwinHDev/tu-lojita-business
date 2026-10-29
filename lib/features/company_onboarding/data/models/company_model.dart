import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';

class CompanyModel extends Company {
  const CompanyModel({
    required super.id,
    required super.name,
    required super.rif,
    required super.logo,
    super.phone,
    super.description,
    super.subcategoryId,
    super.subcategoryName,
    super.categoryName,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    final subcat = json['subcategory'] as Map<String, dynamic>?;
    final cat = subcat?['category'] as Map<String, dynamic>?;

    return CompanyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      rif: json['rif'] as String,
      logo: json['logo'] as String,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      subcategoryId: (json['subcategoryId'] ?? subcat?['id']) as String?,
      subcategoryName: (json['subcategoryName'] ?? subcat?['name']) as String?,
      categoryName: (json['categoryName'] ?? cat?['name']) as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rif': rif,
      'logo': logo,
      'phone': phone,
      'description': description,
      'subcategoryId': subcategoryId,
    };
  }
}

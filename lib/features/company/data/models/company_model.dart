class Company {
  final String id;
  final String name;
  final String rif;
  final String logo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    required this.rif,
    required this.logo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      rif: json['rif'] as String,
      logo: json['logo'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rif': rif,
      'logo': logo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CompanyCheckResponse {
  final bool hasCompany;
  final String? companyId;
  final String? companyName;

  CompanyCheckResponse({
    required this.hasCompany,
    this.companyId,
    this.companyName,
  });

  factory CompanyCheckResponse.fromJson(Map<String, dynamic> json) {
    return CompanyCheckResponse(
      hasCompany: json['hasCompany'] as bool,
      companyId: json['companyId'] as String?,
      companyName: json['companyName'] as String?,
    );
  }
}

class StoreCheckResponse {
  final bool hasStore;
  final String? storeId;
  final String? storeName;

  StoreCheckResponse({
    required this.hasStore,
    this.storeId,
    this.storeName,
  });

  factory StoreCheckResponse.fromJson(Map<String, dynamic> json) {
    return StoreCheckResponse(
      hasStore: json['hasStore'] as bool,
      storeId: json['storeId'] as String?,
      storeName: json['storeName'] as String?,
    );
  }
}

class StoreDetails {
  final String id;
  final String name;
  final String rif;
  final String phone;
  final String description;
  final String logo;

  StoreDetails({
    required this.id,
    required this.name,
    required this.rif,
    required this.phone,
    required this.description,
    required this.logo,
  });

  factory StoreDetails.fromJson(Map<String, dynamic> json) {
    return StoreDetails(
      id: json['id'] as String,
      name: json['name'] as String,
      rif: json['rif'] as String,
      phone: json['phone'] as String,
      description: json['description'] as String,
      logo: json['logo'] as String,
    );
  }
}

class CreateCompanyDto {
  final String name;
  final String rif;
  final String logo;

  CreateCompanyDto({
    required this.name,
    required this.rif,
    required this.logo,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rif': rif,
      'logo': logo,
    };
  }
}

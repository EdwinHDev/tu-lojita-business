class Company {
  final String id;
  final String name;
  final String rif;
  final String logo;
  final String? phone;
  final String? description;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? categoryName;

  const Company({
    required this.id,
    required this.name,
    required this.rif,
    required this.logo,
    this.phone,
    this.description,
    this.subcategoryId,
    this.subcategoryName,
    this.categoryName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rif': rif,
      'logo': logo,
      'phone': phone,
      'description': description,
      'subcategoryId': subcategoryId,
      'subcategoryName': subcategoryName,
      'categoryName': categoryName,
    };
  }
}

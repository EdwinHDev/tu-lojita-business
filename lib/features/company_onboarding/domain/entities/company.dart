class Company {
  final String id;
  final String name;
  final String rif;
  final String logo;
  final String? phone;

  const Company({
    required this.id,
    required this.name,
    required this.rif,
    required this.logo,
    this.phone,
  });
}

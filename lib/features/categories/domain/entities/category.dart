class Category {
  final String id;
  final String name;
  final String description;
  final String image;
  final bool isAgeRestricted;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.isAgeRestricted = false,
  });
}


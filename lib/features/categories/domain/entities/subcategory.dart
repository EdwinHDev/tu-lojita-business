import 'package:tu_lojita_business/features/categories/domain/entities/category.dart';

class Subcategory {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isActive;
  final Category? category;

  Subcategory({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isActive,
    this.category,
  });
}

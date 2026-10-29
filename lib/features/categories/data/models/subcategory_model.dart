import 'package:tu_lojita_business/features/categories/data/models/category_model.dart';
import 'package:tu_lojita_business/features/categories/domain/entities/subcategory.dart';

class SubcategoryModel extends Subcategory {
  SubcategoryModel({
    required super.id,
    required super.name,
    required super.description,
    required super.imageUrl,
    required super.isActive,
    super.isAgeRestricted = false,
    super.category,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] != null
        ? CategoryModel.fromJson(json['category'])
        : null;
    final isAgeRestricted = json['isAgeRestricted'] == true ||
        (category != null && category.isAgeRestricted);

    return SubcategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      isActive: json['isActive'] ?? true,
      isAgeRestricted: isAgeRestricted,
      category: category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'isAgeRestricted': isAgeRestricted,
      if (category != null) 'category': (category as CategoryModel).toJson(),
    };
  }
}

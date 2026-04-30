import 'package:tu_lojita_business/features/categories/data/models/category_model.dart';
import 'package:tu_lojita_business/features/categories/domain/entities/subcategory.dart';

class SubcategoryModel extends Subcategory {
  SubcategoryModel({
    required super.id,
    required super.name,
    required super.description,
    required super.imageUrl,
    required super.isActive,
    super.category,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      if (category != null) 'category': (category as CategoryModel).toJson(),
    };
  }
}

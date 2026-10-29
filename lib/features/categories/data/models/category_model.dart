import 'package:tu_lojita_business/features/categories/domain/entities/category.dart';

class CategoryModel extends Category {
  CategoryModel({
    required super.id,
    required super.name,
    required super.description,
    required super.image,
    super.isAgeRestricted = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      isAgeRestricted: json['isAgeRestricted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'isAgeRestricted': isAgeRestricted,
    };
  }
}

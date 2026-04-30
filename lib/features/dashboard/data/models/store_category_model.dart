import '../../domain/entities/store_category.dart';

class StoreCategoryModel extends StoreCategory {
  const StoreCategoryModel({
    required super.id,
    required super.name,
    required super.description,
  });

  factory StoreCategoryModel.fromJson(Map<String, dynamic> json) {
    return StoreCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

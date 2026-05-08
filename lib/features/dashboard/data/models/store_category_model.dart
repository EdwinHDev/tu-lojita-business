import '../../domain/entities/store_category.dart';
import '../../../../features/items/domain/entities/property_template.dart';

class StoreCategoryModel extends StoreCategory {
  const StoreCategoryModel({
    required super.id,
    required super.name,
    required super.description,
    super.propertyTemplates,
  });

  factory StoreCategoryModel.fromJson(Map<String, dynamic> json) {
    return StoreCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      propertyTemplates: json['propertyTemplates'] != null
          ? (json['propertyTemplates'] as List)
              .map((template) => PropertyTemplate.fromJson(template))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'propertyTemplates': propertyTemplates?.map((t) => {
        'id': t.id,
        'name': t.name,
        'type': t.type.name.toUpperCase(),
        'isRequired': t.isRequired,
        'config': t.config,
      }).toList(),
    };
  }
}

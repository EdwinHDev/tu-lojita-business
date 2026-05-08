import 'package:equatable/equatable.dart';
import '../../../../features/items/domain/entities/property_template.dart';

class StoreCategory extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<PropertyTemplate>? propertyTemplates;

  const StoreCategory({
    required this.id,
    required this.name,
    required this.description,
    this.propertyTemplates,
  });

  @override
  List<Object?> get props => [id, name, description, propertyTemplates];
}

import 'package:equatable/equatable.dart';

class StoreCategory extends Equatable {
  final String id;
  final String name;
  final String description;

  const StoreCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  @override
  List<Object?> get props => [id, name, description];
}

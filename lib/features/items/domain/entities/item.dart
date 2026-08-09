import 'package:equatable/equatable.dart';

enum ItemType { product, service }

enum PriceType { 
  fixed, 
  startingAt, 
  negotiable, 
  onDemand, 
  free 
}

class Item extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final PriceType priceType;
  final String mainImage;
  final List<String> images;
  final bool isFeatured;
  final double? discountPrice;
  final ItemType itemType;
  final bool trackInventory;
  final double? stockQuantity;
  final bool requiresBooking;
  final Map<String, dynamic>? attributes;
  final String? categoryId;
  final List<CustomizationGroup> customizationGroups;
  final bool allowInstallments;
  final double lateFeePercentage;
  final bool isActive;

  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.priceType = PriceType.fixed,
    required this.mainImage,
    required this.images,
    required this.isFeatured,
    this.discountPrice,
    required this.itemType,
    required this.trackInventory,
    this.stockQuantity,
    required this.requiresBooking,
    this.attributes,
    this.categoryId,
    this.customizationGroups = const [],
    this.allowInstallments = true,
    this.lateFeePercentage = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        price,
        priceType,
        mainImage,
        images,
        isFeatured,
        discountPrice,
        itemType,
        trackInventory,
        stockQuantity,
        requiresBooking,
        attributes,
        categoryId,
        customizationGroups,
        allowInstallments,
        lateFeePercentage,
        isActive,
      ];
}

class CustomizationGroup extends Equatable {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<CustomizationOption> options;

  const CustomizationGroup({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.options,
  });

  factory CustomizationGroup.fromJson(Map<String, dynamic> json) {
    return CustomizationGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      minSelect: json['minSelect'] ?? 0,
      maxSelect: json['maxSelect'] ?? 0,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => CustomizationOption.fromJson(o))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'minSelect': minSelect,
    'maxSelect': maxSelect,
    'options': options.map((o) => o.toJson()).toList(),
  };

  @override
  List<Object?> get props => [id, name, minSelect, maxSelect, options];
}

class CustomizationOption extends Equatable {
  final String id;
  final String name;
  final double price;
  final int minQuantity;
  final int maxQuantity;
  final int defaultQuantity;

  const CustomizationOption({
    required this.id,
    required this.name,
    required this.price,
    this.minQuantity = 0,
    this.maxQuantity = 1,
    this.defaultQuantity = 0,
  });

  factory CustomizationOption.fromJson(Map<String, dynamic> json) {
    return CustomizationOption(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      minQuantity: json['minQuantity'] ?? 0,
      maxQuantity: json['maxQuantity'] ?? 1,
      defaultQuantity: json['defaultQuantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'minQuantity': minQuantity,
    'maxQuantity': maxQuantity,
    'defaultQuantity': defaultQuantity,
  };

  @override
  List<Object?> get props => [id, name, price, minQuantity, maxQuantity, defaultQuantity];
}

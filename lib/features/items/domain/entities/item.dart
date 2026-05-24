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
      ];
}

class CustomizationGroup extends Equatable {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool allowOptionQuantity;
  final List<CustomizationOption> options;

  const CustomizationGroup({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    this.allowOptionQuantity = false,
    required this.options,
  });

  factory CustomizationGroup.fromJson(Map<String, dynamic> json) {
    return CustomizationGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      minSelect: json['minSelect'] ?? 0,
      maxSelect: json['maxSelect'] ?? 0,
      allowOptionQuantity: json['allowOptionQuantity'] == true ||
          json['allowoptionquantity'] == true ||
          json['allow_option_quantity'] == true ||
          json['allowOptionQuantity'] == 1 ||
          json['allowoptionquantity'] == 1 ||
          json['allow_option_quantity'] == 1 ||
          json['allowOptionQuantity'] == 'true' ||
          json['allowoptionquantity'] == 'true' ||
          json['allow_option_quantity'] == 'true' ||
          json['allowOptionQuantity'] == '1' ||
          json['allowoptionquantity'] == '1' ||
          json['allow_option_quantity'] == '1',
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
    'allowOptionQuantity': allowOptionQuantity,
    'options': options.map((o) => o.toJson()).toList(),
  };

  @override
  List<Object?> get props => [id, name, minSelect, maxSelect, allowOptionQuantity, options];
}

class CustomizationOption extends Equatable {
  final String id;
  final String name;
  final double price;

  const CustomizationOption({
    required this.id,
    required this.name,
    required this.price,
  });

  factory CustomizationOption.fromJson(Map<String, dynamic> json) {
    return CustomizationOption(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };

  @override
  List<Object?> get props => [id, name, price];
}

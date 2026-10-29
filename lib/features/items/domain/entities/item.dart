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
  final bool isAgeRestricted;
  final bool hasVariants;
  final String? bookingType;
  final Map<String, dynamic>? slotConfig;
  final Map<String, dynamic>? preorderConfig;
  final int favoritesCount;
  final List<VariantAxis> variantAxes;
  final List<ItemVariant> variants;

  bool get isServiceWithSlots =>
      itemType == ItemType.service && (bookingType == 'TIME_SLOT' || requiresBooking);
  String get serviceLocationType =>
      slotConfig?['serviceLocationType']?.toString() ?? 'ON_SITE';
  bool get isOnSiteOnly =>
      isServiceWithSlots && serviceLocationType == 'ON_SITE';
  bool get isHomeServiceOnly =>
      isServiceWithSlots && serviceLocationType == 'HOME_SERVICE';
  bool get isCustomerChoiceService =>
      isServiceWithSlots && serviceLocationType == 'CUSTOMER_CHOICE';

  /// Total stock quantity considering variants if active
  double get totalStockQuantity {
    if (!hasVariants) return stockQuantity ?? 0;
    if (variants.isEmpty) return stockQuantity ?? 0;
    return variants
        .where((v) => v.isActive)
        .fold<double>(0, (sum, v) => sum + v.stockQuantity);
  }

  /// Whether the item is considered in stock
  bool get isInStock {
    if (!trackInventory) return true;
    if (hasVariants) {
      if (variants.isNotEmpty) {
        return variants.any((v) => v.isActive && v.stockQuantity > 0);
      }
      return (stockQuantity ?? 0) > 0;
    }
    return (stockQuantity ?? 0) > 0;
  }

  /// Convenience out of stock flag
  bool get isOutOfStock => !isInStock;

  /// Whether active variants have differing prices
  bool get hasDifferentVariantPrices {
    if (!hasVariants || variants.isEmpty) return false;
    final active = variants.where((v) => v.isActive).toList();
    if (active.isEmpty) return false;
    final prices = active.map((v) => v.price ?? price).toSet();
    return prices.length > 1;
  }

  /// Range of prices across active variants
  ({double min, double max}) get variantPriceRange {
    if (!hasVariants || variants.isEmpty) return (min: price, max: price);
    final active = variants.where((v) => v.isActive).toList();
    if (active.isEmpty) return (min: price, max: price);
    double min = double.infinity;
    double max = double.negativeInfinity;
    for (final v in active) {
      final p = v.price ?? price;
      if (p < min) min = p;
      if (p > max) max = p;
    }
    return (min: min, max: max);
  }

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
    this.isAgeRestricted = false,
    this.hasVariants = false,
    this.bookingType,
    this.slotConfig,
    this.preorderConfig,
    this.favoritesCount = 0,
    this.variantAxes = const [],
    this.variants = const [],
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
        bookingType,
        slotConfig,
        preorderConfig,
        attributes,
        categoryId,
        customizationGroups,
        allowInstallments,
        lateFeePercentage,
        isActive,
        isAgeRestricted,
        hasVariants,
        favoritesCount,
        variantAxes,
        variants,
      ];
}

class VariantAxis extends Equatable {
  final String? id;
  final String name;
  final List<String> values;
  final int position;

  const VariantAxis({
    this.id,
    required this.name,
    required this.values,
    this.position = 0,
  });

  factory VariantAxis.fromJson(Map<String, dynamic> json) {
    return VariantAxis(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      values: (json['values'] as List<dynamic>?)
              ?.map((v) => v.toString())
              .toList() ??
          const [],
      position: json['position'] is num ? (json['position'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'values': values,
    'position': position,
  };

  VariantAxis copyWith({
    String? id,
    String? name,
    List<String>? values,
    int? position,
  }) {
    return VariantAxis(
      id: id ?? this.id,
      name: name ?? this.name,
      values: values ?? this.values,
      position: position ?? this.position,
    );
  }

  @override
  List<Object?> get props => [id, name, values, position];
}

class ItemVariant extends Equatable {
  final String? id;
  final String? sku;
  final double? price;
  final double? discountPrice;
  final double stockQuantity;
  final bool isActive;
  final Map<String, String> axisValues;
  final String? imageUrl;

  const ItemVariant({
    this.id,
    this.sku,
    this.price,
    this.discountPrice,
    this.stockQuantity = 0,
    this.isActive = true,
    this.axisValues = const {},
    this.imageUrl,
  });

  factory ItemVariant.fromJson(Map<String, dynamic> json) {
    Map<String, String> parsedAxisValues = {};
    if (json['axisValues'] is Map) {
      (json['axisValues'] as Map).forEach((key, val) {
        if (key != null && val != null) {
          parsedAxisValues[key.toString()] = val.toString();
        }
      });
    }

    String? img = json['imageUrl']?.toString();
    if (img == null || img.isEmpty) {
      for (final val in parsedAxisValues.values) {
        if (val.contains('|')) {
          final parts = val.split('|');
          if (parts.length > 2 && parts[2].trim().isNotEmpty) {
            img = parts[2].trim();
            break;
          }
        }
      }
    }

    return ItemVariant(
      id: json['id']?.toString(),
      sku: json['sku']?.toString(),
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      discountPrice: json['discountPrice'] != null ? double.tryParse(json['discountPrice'].toString()) : null,
      stockQuantity: json['stockQuantity'] != null ? double.tryParse(json['stockQuantity'].toString()) ?? 0 : 0,
      isActive: json['isActive'] ?? true,
      axisValues: parsedAxisValues,
      imageUrl: img,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (sku != null) 'sku': sku,
    if (price != null) 'price': price,
    if (discountPrice != null) 'discountPrice': discountPrice,
    'stockQuantity': stockQuantity,
    'isActive': isActive,
    'axisValues': axisValues,
    if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
  };

  ItemVariant copyWith({
    String? id,
    String? sku,
    double? price,
    double? discountPrice,
    double? stockQuantity,
    bool? isActive,
    Map<String, String>? axisValues,
    String? imageUrl,
  }) {
    return ItemVariant(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      axisValues: axisValues ?? this.axisValues,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [id, sku, price, discountPrice, stockQuantity, isActive, axisValues, imageUrl];
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

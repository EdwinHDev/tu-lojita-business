import 'dart:convert';
import '../../domain/entities/item.dart';

class ItemModel extends Item {
  const ItemModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    super.priceType = PriceType.fixed,
    required super.mainImage,
    required super.images,
    required super.isFeatured,
    super.discountPrice,
    required super.itemType,
    required super.trackInventory,
    super.stockQuantity,
    required super.requiresBooking,
    super.attributes,
    super.categoryId,
    super.customizationGroups = const [],
    super.allowInstallments = true,
    super.lateFeePercentage = 0,
    super.isActive = true,
    super.isAgeRestricted = false,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _parseDouble(json['price']),
      priceType: _parsePriceType(json['priceType']?.toString()),
      mainImage: json['mainImage']?.toString() ?? '',
      images: json['images'] != null && json['images'] is List
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : const [],
      isFeatured: json['isFeatured'] == true,
      discountPrice: json['discountPrice'] != null ? _parseDouble(json['discountPrice']) : null,
      itemType: _parseItemType(json['itemType']?.toString() ?? 'PRODUCT'),
      trackInventory: json['trackInventory'] == true,
      stockQuantity: json['stockQuantity'] != null ? _parseDouble(json['stockQuantity']) : null,
      requiresBooking: json['requiresBooking'] == true,
      attributes: _parseAttributes(json['attributes']),
      categoryId: _parseCategoryId(json['category']),
      customizationGroups: _extractCustomizationGroups(json),
      allowInstallments: json['allowInstallments'] == true,
      lateFeePercentage: _parseDouble(json['lateFeePercentage']),
      isActive: json['isActive'] ?? true,
      isAgeRestricted: json['isAgeRestricted'] == true,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static PriceType _parsePriceType(String? value) {
    if (value == null) return PriceType.fixed;
    switch (value.toUpperCase()) {
      case 'FIXED': return PriceType.fixed;
      case 'STARTING_AT': return PriceType.startingAt;
      case 'NEGOTIABLE': return PriceType.negotiable;
      case 'ON_DEMAND': return PriceType.onDemand;
      case 'FREE': return PriceType.free;
      default: return PriceType.fixed;
    }
  }

  static ItemType _parseItemType(String value) {
    switch (value.toUpperCase()) {
      case 'PRODUCT': return ItemType.product;
      case 'SERVICE': return ItemType.service;
      default: return ItemType.product;
    }
  }

  static Map<String, dynamic>? _parseAttributes(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String? _parseCategoryId(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value['id']?.toString();
    }
    if (value is String) return value;
    return null;
  }

  static List<CustomizationGroup> _extractCustomizationGroups(Map<String, dynamic> json) {
    final rel = json['customizationGroupsRel'];
    if (rel != null && rel is List && rel.isNotEmpty) {
      return _parseCustomizationGroups(rel);
    }
    final cg = json['customizationGroups'];
    if (cg != null && cg is List && cg.isNotEmpty) {
      return _parseCustomizationGroups(cg);
    }
    final cgSnake = json['customization_groups'];
    if (cgSnake != null && cgSnake is List && cgSnake.isNotEmpty) {
      return _parseCustomizationGroups(cgSnake);
    }
    return _parseCustomizationGroups(rel ?? cg ?? cgSnake);
  }

  static List<CustomizationGroup> _parseCustomizationGroups(dynamic value) {
    if (value == null) return const [];
    if (value is String) {
      try {
        final parsed = jsonDecode(value);
        return _parseCustomizationGroups(parsed);
      } catch (_) {
        return const [];
      }
    }
    if (value is List) {
      return value.map((c) {
        if (c is Map) {
          return CustomizationGroup.fromJson(Map<String, dynamic>.from(c));
        }
        return const CustomizationGroup(id: '', name: '', minSelect: 0, maxSelect: 0, options: []);
      }).toList();
    }
    return const [];
  }
}

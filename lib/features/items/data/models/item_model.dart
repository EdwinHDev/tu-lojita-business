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
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: _parseDouble(json['price']),
      priceType: _parsePriceType(json['priceType'] as String?),
      mainImage: json['mainImage'] as String,
      images: (json['images'] as List).map((e) => e as String).toList(),
      isFeatured: json['isFeatured'] as bool,
      discountPrice: json['discountPrice'] != null ? _parseDouble(json['discountPrice']) : null,
      itemType: _parseItemType(json['itemType'] as String),
      trackInventory: json['trackInventory'] as bool,
      stockQuantity: json['stockQuantity'] != null ? _parseDouble(json['stockQuantity']) : null,
      requiresBooking: json['requiresBooking'] as bool,
      attributes: json['attributes'] as Map<String, dynamic>?,
      categoryId: json['category'] != null ? (json['category'] as Map<String, dynamic>)['id'] as String : null,
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
}

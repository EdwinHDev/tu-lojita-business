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
      ];
}

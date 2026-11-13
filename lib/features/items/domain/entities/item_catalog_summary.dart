import 'package:equatable/equatable.dart';
import 'item.dart';

enum ItemCatalogStatusFilter {
  all,
  published,
  paused,
  outOfStock,
  discounted,
}

class ItemCatalogSummary extends Equatable {
  final int total;
  final int published;
  final int paused;
  final int outOfStock;
  final int discounted;
  final int products;
  final int services;

  const ItemCatalogSummary({
    this.total = 0,
    this.published = 0,
    this.paused = 0,
    this.outOfStock = 0,
    this.discounted = 0,
    this.products = 0,
    this.services = 0,
  });

  factory ItemCatalogSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return ItemCatalogSummary(
      total: parseInt(json['total']),
      published: parseInt(json['published']),
      paused: parseInt(json['paused']),
      outOfStock: parseInt(json['outOfStock']),
      discounted: parseInt(json['discounted']),
      products: parseInt(json['products']),
      services: parseInt(json['services']),
    );
  }

  factory ItemCatalogSummary.fromItems(List<Item> items) {
    int published = 0;
    int paused = 0;
    int outOfStock = 0;
    int discounted = 0;
    int products = 0;
    int services = 0;

    for (final item in items) {
      if (item.isActive) {
        published++;
      } else {
        paused++;
      }
      if (item.isOutOfStock) {
        outOfStock++;
      }
      if (item.discountPrice != null &&
          item.discountPrice! > 0 &&
          item.discountPrice! < item.price) {
        discounted++;
      }
      if (item.itemType == ItemType.service) {
        services++;
      } else {
        products++;
      }
    }

    return ItemCatalogSummary(
      total: items.length,
      published: published,
      paused: paused,
      outOfStock: outOfStock,
      discounted: discounted,
      products: products,
      services: services,
    );
  }

  ItemCatalogSummary copyWith({
    int? total,
    int? published,
    int? paused,
    int? outOfStock,
    int? discounted,
    int? products,
    int? services,
  }) {
    return ItemCatalogSummary(
      total: total ?? this.total,
      published: published ?? this.published,
      paused: paused ?? this.paused,
      outOfStock: outOfStock ?? this.outOfStock,
      discounted: discounted ?? this.discounted,
      products: products ?? this.products,
      services: services ?? this.services,
    );
  }

  @override
  List<Object?> get props => [
        total,
        published,
        paused,
        outOfStock,
        discounted,
        products,
        services,
      ];
}

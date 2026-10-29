import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/data/models/item_model.dart';

class OrderItem {
  final String id;
  final String title;
  final double price;
  final int quantity;
  final String? itemId;
  final String? variantId;
  final String? variantLabel;
  final ItemVariant? variant;
  final Map<String, List<String>> selectedOptions;
  final Item? item;

  OrderItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    this.itemId,
    this.variantId,
    this.variantLabel,
    this.variant,
    this.selectedOptions = const {},
    this.item,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final dynamicOpts = json['selectedOptions'];
    final Map<String, List<String>> options = {};
    if (dynamicOpts is Map) {
      dynamicOpts.forEach((k, v) {
        if (v is List) {
          options[k.toString()] = v.map((e) => e.toString()).toList();
        }
      });
    }

    ItemVariant? parsedVariant;
    if (json['variant'] != null && json['variant'] is Map) {
      parsedVariant = ItemVariant.fromJson(Map<String, dynamic>.from(json['variant']));
    }

    return OrderItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] ?? 0,
      itemId: json['item']?['id'] as String?,
      variantId: json['variantId']?.toString(),
      variantLabel: json['variantLabel']?.toString(),
      variant: parsedVariant,
      selectedOptions: options,
      item: json['item'] != null ? ItemModel.fromJson(json['item']) : null,
    );
  }

  OrderItem copyWith({
    String? id,
    String? title,
    double? price,
    int? quantity,
    String? itemId,
    String? variantId,
    String? variantLabel,
    ItemVariant? variant,
    Map<String, List<String>>? selectedOptions,
    Item? item,
  }) {
    return OrderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      itemId: itemId ?? this.itemId,
      variantId: variantId ?? this.variantId,
      variantLabel: variantLabel ?? this.variantLabel,
      variant: variant ?? this.variant,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      item: item ?? this.item,
    );
  }

  /// Resuelve la miniatura específica de la variante vendida si existe,
  /// con fallback a la imagen principal del artículo o su primera imagen.
  String? get resolvedThumbnail {
    // 0. Variante directa en el item de la orden
    if (variant != null) {
      if (variant!.imageUrl != null && variant!.imageUrl!.isNotEmpty) {
        return variant!.imageUrl;
      }
      for (final val in variant!.axisValues.values) {
        if (val.contains('|')) {
          final parts = val.split('|');
          if (parts.length > 2 && parts[2].trim().isNotEmpty) {
            return parts[2].trim();
          }
        }
      }
    }

    if (item == null) return null;

    // 1. Coincidencia directa por variantId en item.variants
    if (variantId != null && variantId!.isNotEmpty && item!.variants.isNotEmpty) {
      final match = item!.variants.where((v) => v.id == variantId).firstOrNull;
      if (match != null) {
        if (match.imageUrl != null && match.imageUrl!.isNotEmpty) {
          return match.imageUrl;
        }
        for (final val in match.axisValues.values) {
          if (val.contains('|')) {
            final parts = val.split('|');
            if (parts.length > 2 && parts[2].trim().isNotEmpty) {
              return parts[2].trim();
            }
          }
        }
      }
    }

    // 2. Coincidencia por etiqueta de variante (variantLabel) contra axisValues
    if (variantLabel != null && variantLabel!.isNotEmpty && item!.variants.isNotEmpty) {
      for (final v in item!.variants) {
        for (final val in v.axisValues.values) {
          final pureName = val.contains('|') ? val.split('|').first.trim() : val.trim();
          if (pureName.isNotEmpty && variantLabel!.contains(pureName)) {
            if (v.imageUrl != null && v.imageUrl!.isNotEmpty) {
              return v.imageUrl;
            }
            if (val.contains('|')) {
              final parts = val.split('|');
              if (parts.length > 2 && parts[2].trim().isNotEmpty) {
                return parts[2].trim();
              }
            }
          }
        }
      }
    }

    // 3. Fallback a imagen principal
    if (item!.mainImage.isNotEmpty) {
      return item!.mainImage;
    }
    if (item!.images.isNotEmpty) {
      return item!.images.first;
    }
    return null;
  }
}

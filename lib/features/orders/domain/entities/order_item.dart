import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/data/models/item_model.dart';

class OrderItem {
  final String id;
  final String title;
  final double price;
  final int quantity;
  final String? itemId;
  final Map<String, List<String>> selectedOptions;
  final Item? item;

  OrderItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    this.itemId,
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

    return OrderItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] ?? 0,
      itemId: json['item']?['id'] as String?,
      selectedOptions: options,
      item: json['item'] != null ? ItemModel.fromJson(json['item']) : null,
    );
  }
}

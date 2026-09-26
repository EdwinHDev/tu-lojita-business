import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order_item.dart';
import 'order_detail_helpers.dart';

/// Tarjeta que muestra los artículos del pedido con miniaturas, cantidades, extras y subtotales.
class OrderItemsCard extends StatelessWidget {
  final Order order;

  const OrderItemsCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: order.orderItems.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          color: Color(0xFFF1F5F9),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final item = order.orderItems[index];
          return _buildOrderItemTile(context, item);
        },
      ),
    );
  }

  Widget _buildOrderItemTile(BuildContext context, OrderItem item) {
    final rawImagePath = item.item?.mainImage ??
        (item.item?.images.isNotEmpty == true ? item.item!.images.first : '');
    final imageUrl = OrderDetailHelpers.resolveImageUrl(rawImagePath);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniatura de producto
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
                  color: const Color(0xFFF8FAFC),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFCBD5E1)),
                              ),
                            );
                          },
                        )
                      : _buildPlaceholder(),
                ),
              ),
              const SizedBox(width: 14),
              // Detalles del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'x${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${item.price.toStringAsFixed(2)} c/u',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          // Opciones y personalizaciones
          if (item.selectedOptions.isNotEmpty && item.item != null) ...[
            const SizedBox(height: 12),
            ...item.selectedOptions.entries.map((entry) {
              final groupId = entry.key;
              final optionIds = entry.value;

              final group = item.item!.customizationGroups.firstWhere(
                (g) => g.id == groupId,
                orElse: () => CustomizationGroup(
                  id: groupId,
                  name: 'Personalización',
                  maxSelect: 0,
                  minSelect: 0,
                  options: [],
                ),
              );

              final optCounts = <String, int>{};
              for (final optId in optionIds) {
                optCounts[optId] = (optCounts[optId] ?? 0) + 1;
              }
              if (optCounts.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_mosaic_outlined,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...optCounts.entries.map((optEntry) {
                      final optId = optEntry.key;
                      final count = optEntry.value;

                      final opt = group.options.firstWhere(
                        (o) => o.id == optId,
                        orElse: () => CustomizationOption(
                          id: optId,
                          name: optId,
                          price: 0,
                        ),
                      );

                      final nameLabel = count > 1 ? '${opt.name} x$count' : opt.name;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      nameLabel,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (opt.price > 0)
                              Text(
                                '+\$${(opt.price * count).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedPackage,
        color: Color(0xFF94A3B8),
        size: 24,
      ),
    );
  }
}

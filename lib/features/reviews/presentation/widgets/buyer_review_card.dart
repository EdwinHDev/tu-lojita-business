import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import '../providers/review_providers.dart';
import 'buyer_review_sheet.dart';

class BuyerReviewCard extends ConsumerWidget {
  final Order order;

  const BuyerReviewCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (order.status != 'FULLY_PAID') {
      return const SizedBox.shrink();
    }

    final reviewAsync = ref.watch(buyerReviewByOrderProvider(order.id));
    final dateFormat = DateFormat('dd/MM/yyyy');

    return reviewAsync.when(
      data: (review) {
        if (review == null) {
          // No review yet -> prompt button
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calificar al comprador',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Orden completada. Evalúa la experiencia con este cliente.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await BuyerReviewSheet.show(
                        context,
                        orderId: order.id,
                      );
                      if (result == true) {
                        ref.invalidate(buyerReviewByOrderProvider(order.id));
                      }
                    },
                    icon: const Icon(Icons.star_outline_rounded, size: 18),
                    label: const Text(
                      'Calificar al comprador',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Already reviewed
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tu calificación a este comprador',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (review.canEdit)
                    TextButton.icon(
                      onPressed: () async {
                        final result = await BuyerReviewSheet.show(
                          context,
                          orderId: order.id,
                          existingReview: review,
                        );
                        if (result == true) {
                          ref.invalidate(buyerReviewByOrderProvider(order.id));
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Editar', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ...List.generate(5, (s) {
                    return Icon(
                      s < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 18,
                      color: Colors.amber,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(review.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  review.comment!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

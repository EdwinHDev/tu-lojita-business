import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import '../providers/review_providers.dart';
import 'vendor_reply_sheet.dart';

class OrderReviewVendorCard extends ConsumerWidget {
  final Order order;

  const OrderReviewVendorCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(orderReviewByOrderProvider(order.id));
    final dateFormat = DateFormat('dd/MM/yyyy');

    return reviewAsync.when(
      data: (review) {
        if (review == null) {
          return const SizedBox.shrink();
        }

        final author = review.authorName?.trim();
        final title = (author != null && author.isNotEmpty)
            ? 'Reseña de $author'
            : 'Reseña del cliente';

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
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(review.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (s) {
                  return Icon(
                    s < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18,
                    color: Colors.amber,
                  );
                }),
              ),
              if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  review.comment!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                ),
              ],
              if (review.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: review.imageUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          review.imageUrls[index],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Vendor reply section or reply button
              const SizedBox(height: 14),
              if (review.hasVendorReply) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF16A34A), width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Tu respuesta publicada',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                          if (review.vendorRepliedAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              dateFormat.format(review.vendorRepliedAt!),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.vendorReply!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await VendorReplySheet.show(
                        context,
                        orderId: order.id,
                        review: review,
                      );
                      if (result == true) {
                        ref.invalidate(orderReviewByOrderProvider(order.id));
                      }
                    },
                    icon: const Icon(Icons.reply_rounded, size: 16),
                    label: const Text('Responder a esta reseña'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFF86EFAC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
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

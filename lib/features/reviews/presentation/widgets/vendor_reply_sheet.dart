import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../../domain/models/order_review_model.dart';
import '../providers/review_providers.dart';

class VendorReplySheet extends ConsumerStatefulWidget {
  final String orderId;
  final OrderReviewModel review;

  const VendorReplySheet({
    super.key,
    required this.orderId,
    required this.review,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String orderId,
    required OrderReviewModel review,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VendorReplySheet(
        orderId: orderId,
        review: review,
      ),
    );
  }

  @override
  ConsumerState<VendorReplySheet> createState() => _VendorReplySheetState();
}

class _VendorReplySheetState extends ConsumerState<VendorReplySheet> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) {
      NotificationService.showWarning(context, 'Por favor escribe tu respuesta');
      return;
    }

    final notifier = ref.read(reviewActionNotifierProvider.notifier);
    final success = await notifier.addVendorReply(
      orderId: widget.orderId,
      reviewId: widget.review.id,
      reply: text,
    );

    if (!mounted) return;

    if (success) {
      NotificationService.showSuccess(context, '¡Respuesta publicada exitosamente!');
      Navigator.pop(context, true);
    } else {
      final error = ref.read(reviewActionNotifierProvider).error;
      NotificationService.showError(context, error ?? 'Error al enviar respuesta');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewActionNotifierProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.reply_rounded,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Responder a la Reseña',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tu respuesta será pública y visible en el artículo',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Customer review quote
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.review.authorName ?? 'Cliente',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(5, (s) {
                        return Icon(
                          s < widget.review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 14,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
                if (widget.review.comment != null && widget.review.comment!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.review.comment!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Response textfield
          const Text(
            'Tu respuesta como tienda',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _replyController,
            maxLines: 4,
            maxLength: 400,
            decoration: InputDecoration(
              hintText: 'Agradece al cliente o responde cordialmente a sus dudas...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Submit button
          ElevatedButton(
            onPressed: state.isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: state.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Publicar Respuesta',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ],
      ),
    );
  }
}

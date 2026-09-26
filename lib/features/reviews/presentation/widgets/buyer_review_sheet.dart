import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../../domain/models/buyer_review_model.dart';
import '../providers/review_providers.dart';

class BuyerReviewSheet extends ConsumerStatefulWidget {
  final String orderId;
  final BuyerReviewModel? existingReview;

  const BuyerReviewSheet({
    super.key,
    required this.orderId,
    this.existingReview,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String orderId,
    BuyerReviewModel? existingReview,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BuyerReviewSheet(
        orderId: orderId,
        existingReview: existingReview,
      ),
    );
  }

  @override
  ConsumerState<BuyerReviewSheet> createState() => _BuyerReviewSheetState();
}

class _BuyerReviewSheetState extends ConsumerState<BuyerReviewSheet> {
  late int _rating;
  late final TextEditingController _commentController;

  final List<String> _ratingLabels = [
    '',
    'Comprador difícil',
    'Complicado',
    'Aceptable',
    'Buen comprador',
    '¡Excelente comprador!',
  ];

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 5;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(reviewActionNotifierProvider.notifier);
    final isEditing = widget.existingReview != null;

    bool success;
    if (isEditing) {
      success = await notifier.updateBuyerReview(
        orderId: widget.orderId,
        reviewId: widget.existingReview!.id,
        rating: _rating,
        comment: _commentController.text,
      );
    } else {
      success = await notifier.createBuyerReview(
        orderId: widget.orderId,
        rating: _rating,
        comment: _commentController.text,
      );
    }

    if (!mounted) return;

    if (success) {
      NotificationService.showSuccess(
        context,
        isEditing
            ? '¡Calificación de comprador actualizada!'
            : '¡Calificación de comprador guardada con éxito!',
      );
      Navigator.pop(context, true);
    } else {
      final error = ref.read(reviewActionNotifierProvider).error;
      NotificationService.showError(context, error ?? 'Error al guardar calificación');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewActionNotifierProvider);
    final isEditing = widget.existingReview != null;

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
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF4F46E5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Editar Calificación' : 'Calificar al Comprador',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tu reseña ayuda a construir la reputación del cliente',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Star selector
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starVal = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = starVal),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          starVal <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 40,
                          color: Colors.amber,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _ratingLabels[_rating],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Comment
          const Text(
            'Comentario (opcional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Ej: Cliente muy cordial, pago puntual y excelente comunicación...',
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
              backgroundColor: const Color(0xFF4F46E5),
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
                : Text(
                    isEditing ? 'Actualizar Calificación' : 'Guardar Calificación',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ],
      ),
    );
  }
}

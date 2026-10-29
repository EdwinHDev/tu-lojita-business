import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'package:tu_lojita_business/features/orders/presentation/providers/dispute_providers.dart';
import 'order_dispute_bottom_sheet.dart';

/// Tarjeta que notifica y guía al comerciante cuando una orden cancelada
/// requiere la devolución o reembolso de un pago previamente reportado por el cliente.
class RefundRequiredCard extends ConsumerWidget {
  final Order order;
  final Payment payment;
  final bool isUpdating;
  final VoidCallback? onProcessRefund;
  final VoidCallback? onMarkPaymentNotReceived;

  const RefundRequiredCard({
    super.key,
    required this.order,
    required this.payment,
    this.isUpdating = false,
    this.onProcessRefund,
    this.onMarkPaymentNotReceived,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDispute = ref.watch(activeStoreDisputeProvider(order.id));
    final hasActiveDispute = activeDispute != null && activeDispute.status.isActive;
    final effectiveReason = (order.cancellationReason != null &&
            order.cancellationReason!.trim().isNotEmpty)
        ? order.cancellationReason!.trim()
        : ((order.rejectionReason != null &&
                order.rejectionReason!.trim().isNotEmpty)
            ? order.rejectionReason!.trim()
            : 'Cancelada por el cliente');
    final notes = order.cancellationNotes;

    final bool isPendingConfirmation = payment.status == 'REFUND_PENDING';

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPendingConfirmation ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPendingConfirmation ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPendingConfirmation ? const Color(0xFF2563EB) : const Color(0xFFD97706)).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de Reembolso Requerido o Emitido
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPendingConfirmation ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPendingConfirmation ? Icons.schedule_rounded : Icons.currency_exchange_rounded,
                  size: 20,
                  color: isPendingConfirmation ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPendingConfirmation ? 'Reembolso Emitido (En Verificación)' : 'Reembolso Requerido',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isPendingConfirmation ? const Color(0xFF1E40AF) : const Color(0xFF92400E),
                      ),
                    ),
                    Text(
                      isPendingConfirmation
                          ? 'Se notificó al cliente. Esperando que confirme la recepción de \$${payment.amount.toStringAsFixed(2)}.'
                          : 'El cliente canceló la orden tras reportar \$${payment.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isPendingConfirmation ? const Color(0xFF3B82F6) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: isPendingConfirmation ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
          const SizedBox(height: 12),

          // Si ya se reportó el reembolso, mostrar datos emitidos
          if (isPendingConfirmation && payment.rejectionReason != null && payment.rejectionReason!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Text(
                        'Datos del reembolso emitido:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payment.rejectionReason!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Motivo e instrucciones de cancelación del cliente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isPendingConfirmation ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: isPendingConfirmation ? const Color(0xFF2563EB) : const Color(0xFFB45309)),
                    const SizedBox(width: 6),
                    Text(
                      'Motivo de cancelación del cliente:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPendingConfirmation ? const Color(0xFF2563EB) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  effectiveReason,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isPendingConfirmation ? const Color(0xFF1E3A8A) : const Color(0xFF78350F),
                  ),
                ),
                if (notes != null && notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Instrucciones/Cuenta: ${notes.trim()}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: isPendingConfirmation ? const Color(0xFF1E40AF) : const Color(0xFF92400E),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Datos de la transacción reportada originalmente
          Text(
            'Comprobante recibido: ${payment.displayLabel}${payment.reference != null && payment.reference!.isNotEmpty ? ' • Ref: ${payment.reference}' : ''} • ${payment.createdAt.toDateTimeString()}',
            style: TextStyle(
              fontSize: 11,
              color: isPendingConfirmation ? const Color(0xFF3B82F6) : const Color(0xFF92400E),
            ),
          ),

          // Botón de acción para registrar el reembolso (solo antes de emitirlo)
          if (!isPendingConfirmation) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUpdating ? null : onProcessRefund,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                label: const Text(
                  'Registrar Reembolso',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

          // Banner de mediación si hay un reclamo en curso
          if (hasActiveDispute) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                OrderDisputeBottomSheet.show(
                  context,
                  orderId: order.id,
                  dispute: activeDispute,
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reclamo en mediación (${activeDispute.status.label}). Las opciones de "No recibido" y acuerdos alternativos están en pausa.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Opciones alternativas: Pago no recibido y Mutuo acuerdo
          // Opción alternativa: Declarar pago no recibido
          if (!isPendingConfirmation) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (isUpdating || hasActiveDispute) ? null : onMarkPaymentNotReceived,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.money_off_rounded, size: 15),
                label: const Text(
                  'Declarar pago no recibido',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

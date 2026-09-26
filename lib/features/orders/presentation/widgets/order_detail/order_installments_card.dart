import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'order_detail_helpers.dart';

/// Tarjeta para el plan de cuotas con indicadores de estado y gestión de prórrogas in-situ.
class OrderInstallmentsCard extends StatelessWidget {
  final Order order;
  final bool isUpdating;
  final ValueChanged<Installment>? onApproveExtension;
  final ValueChanged<Installment>? onRejectExtension;

  const OrderInstallmentsCard({
    super.key,
    required this.order,
    this.isUpdating = false,
    this.onApproveExtension,
    this.onRejectExtension,
  });

  @override
  Widget build(BuildContext context) {
    if (order.installments.isEmpty) return const SizedBox.shrink();

    // Determinar qué cuotas están en revisión por comprobantes pendientes
    final waitingPayments = order.payments.where((p) => p.status == 'WAITING_VERIFICATION').toList();
    final installmentsInReview = <String>{};
    for (final wp in waitingPayments) {
      final ctx = OrderDetailHelpers.getInstallmentContextForPayment(order, wp);
      if (ctx.installment != null) {
        installmentsInReview.add(ctx.installment!.id);
      }
    }

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
      child: Column(
        children: order.installments.asMap().entries.map((entry) {
          final index = entry.key;
          final installment = entry.value;
          final isLast = index == order.installments.length - 1;

          return Column(
            children: [
              _buildInstallmentItem(context, installment, index, installmentsInReview, waitingPayments),
              if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 64),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInstallmentItem(
    BuildContext context,
    Installment installment,
    int index,
    Set<String> installmentsInReview,
    List<Payment> waitingPayments,
  ) {
    final isInitialPayment = index == 0;
    final isPaid = installment.status == 'PAID';
    final isInReview = installmentsInReview.contains(installment.id) ||
        (index == 0 && waitingPayments.isNotEmpty && installment.status != 'PAID');

    final isOverdue = !isPaid &&
        !isInReview &&
        !isInitialPayment &&
        installment.dueDate != null &&
        installment.dueDate!.isBefore(DateTime.now()) &&
        installment.status == 'PENDING';

    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;
    String dateLabel;
    Color dateColor;

    if (isPaid) {
      statusBgColor = const Color(0xFFECFDF5);
      statusTextColor = const Color(0xFF047857);
      statusLabel = 'PAGADA';
      dateLabel = installment.paymentDate != null
          ? 'Pagada el ${installment.paymentDate!.toSlashDateString()}'
          : 'Pagada';
      dateColor = const Color(0xFF047857);
    } else if (isInReview) {
      statusBgColor = const Color(0xFFFFFBEB);
      statusTextColor = const Color(0xFFD97706);
      statusLabel = 'EN REVISIÓN';
      dateLabel = isInitialPayment ? 'Pago inicial en verificación' : 'Comprobante en verificación';
      dateColor = const Color(0xFFD97706);
    } else if (isOverdue) {
      statusBgColor = const Color(0xFFFEF2F2);
      statusTextColor = const Color(0xFFB91C1C);
      statusLabel = 'VENCIDA';
      dateLabel = 'Venció el ${installment.dueDate!.toSlashDateString()}';
      dateColor = const Color(0xFFB91C1C);
    } else if (isInitialPayment) {
      statusBgColor = const Color(0xFFF1F5F9);
      statusTextColor = const Color(0xFF475569);
      statusLabel = 'PENDIENTE';
      dateLabel = 'Pago inicial (al comprar)';
      dateColor = const Color(0xFF64748B);
    } else if (installment.dueDate == null) {
      statusBgColor = const Color(0xFFF1F5F9);
      statusTextColor = const Color(0xFF475569);
      statusLabel = 'PENDIENTE';
      dateLabel = 'Por programar';
      dateColor = const Color(0xFF64748B);
    } else {
      statusBgColor = const Color(0xFFF1F5F9);
      statusTextColor = const Color(0xFF475569);
      statusLabel = 'PENDIENTE';
      dateLabel = 'Vence: ${installment.dueDate!.toSlashDateString()}';
      dateColor = const Color(0xFF64748B);
    }

    final titleLabel = isInitialPayment ? 'Pago Inicial (Cuota 1)' : 'Cuota ${index + 1}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFFECFDF5)
                      : (isInReview
                          ? const Color(0xFFFFFBEB)
                          : (isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFEEF2FF))),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isPaid
                          ? const Color(0xFF047857)
                          : (isInReview
                              ? const Color(0xFFD97706)
                              : (isOverdue ? const Color(0xFFB91C1C) : const Color(0xFF4F46E5))),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${installment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: dateColor,
                        fontWeight: (isOverdue || isInReview || isPaid) ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          // Solicitud de prórroga de cuota in-situ
          if (installment.extensionStatus == 'PENDING') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Solicitud de Prórroga (+${installment.extensionRequestedDays ?? 7} días)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  if (installment.extensionReason != null && installment.extensionReason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Motivo: "${installment.extensionReason}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: isUpdating ? null : () => onRejectExtension?.call(installment),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Rechazar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isUpdating ? null : () => onApproveExtension?.call(installment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                        ),
                        child: const Text('Aprobar Prórroga', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (installment.extensionStatus == 'APPROVED') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '✓ Prórroga aprobada (+${installment.extensionRequestedDays ?? 7} días)',
                style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
              ),
            ),
          ] else if (installment.extensionStatus == 'REJECTED') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '✗ Prórroga rechazada${installment.extensionMerchantComment != null ? ': "${installment.extensionMerchantComment}"' : ''}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

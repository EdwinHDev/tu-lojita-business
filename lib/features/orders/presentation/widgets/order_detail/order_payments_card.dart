import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import '../receipt_image_viewer.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'order_detail_helpers.dart';

/// Tarjeta que lista los comprobantes de pago reportados por el cliente,
/// con previsualización, impacto en cuotas y acciones de aprobación/rechazo.
class OrderPaymentsCard extends StatelessWidget {
  final Order order;
  final bool isUpdating;
  final ValueChanged<Payment>? onApprovePayment;
  final ValueChanged<Payment>? onRejectPayment;

  const OrderPaymentsCard({
    super.key,
    required this.order,
    this.isUpdating = false,
    this.onApprovePayment,
    this.onRejectPayment,
  });

  @override
  Widget build(BuildContext context) {
    if (order.payments.isEmpty) return const SizedBox.shrink();

    return Column(
      children: order.payments.map((payment) {
        final isApproved = payment.status == 'APPROVED';
        final isRejected = payment.status == 'REJECTED';
        final isWaiting = payment.status == 'WAITING_VERIFICATION';
        final imageUrl = OrderDetailHelpers.resolveImageUrl(payment.receiptImage ?? '');

        // Contexto de cuota para pagos en revisión
        final installmentCtx = isWaiting
            ? OrderDetailHelpers.getInstallmentContextForPayment(order, payment)
            : (installment: null, installmentIndex: -1, minRequired: 0.0);
        final coveredInstallment = installmentCtx.installment;
        final isSufficient = coveredInstallment != null &&
            (payment.amount * 100).round() >= ((installmentCtx.minRequired * 100).round() - 1);
        final impacts = isWaiting ? OrderDetailHelpers.getApprovalImpact(order, payment) : <({int index, String status, double remaining})>[];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del pago
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.displayLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                isApproved
                                    ? 'Verificado'
                                    : (isRejected ? 'Rechazado' : 'En revisión'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isApproved
                                      ? const Color(0xFF047857)
                                      : (isRejected ? const Color(0xFFDC2626) : const Color(0xFFC2410C)),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  payment.getQuotaLabel(order),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '\$${payment.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),

              // Banner de motivo de rechazo si fue rechazado
              if (isRejected && payment.rejectionReason != null && payment.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 6),
                          Text(
                            'Motivo del Rechazo:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.rejectionReason!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Banner de cuota asociada para pagos en revisión
              if (isWaiting && coveredInstallment != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSufficient ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSufficient ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 14,
                            color: isSufficient ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cuota ${installmentCtx.installmentIndex + 1} de ${order.installments.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSufficient ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            coveredInstallment.dueDate != null
                                ? '· Vence ${coveredInstallment.dueDate!.toSlashDateString()}'
                                : '· Por programar',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSufficient ? const Color(0xFF166534) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isSufficient ? Icons.check_circle_outline : Icons.error_outline_rounded,
                            size: 14,
                            color: isSufficient ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSufficient
                                ? 'Monto suficiente ✓  (mínimo \$${installmentCtx.minRequired.toStringAsFixed(2)})'
                                : 'Monto insuficiente — requiere \$${installmentCtx.minRequired.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSufficient ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Previsualización de impacto al aprobar
              if (isWaiting && impacts.isNotEmpty) ...[
                const SizedBox(height: 10),
                PaymentImpactPreview(
                  impacts: impacts,
                  installments: order.installments,
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              // Metadatos de fecha y referencia
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  const Text('Fecha:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(width: 4),
                  Text(
                    payment.createdAt.toDateTimeString(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ],
              ),
              if (payment.reference != null && payment.reference!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.tag_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    const Text('Referencia:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(width: 4),
                    Text(
                      payment.reference!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ],

              // Miniatura del comprobante con zoom
              if (imageUrl.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'COMPROBANTE ADJUNTO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierColor: Colors.black,
                      barrierDismissible: true,
                      barrierLabel: 'Cerrar',
                      pageBuilder: (context, anim1, anim2) => ReceiptImageViewer(imageUrl: imageUrl),
                    );
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImageError(),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Botones de acción si el pago está esperando verificación
              if (isWaiting) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isUpdating ? null : () => onRejectPayment?.call(payment),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Rechazar Pago', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: isUpdating ? null : () => onApprovePayment?.call(payment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Aprobar Pago', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageError() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8), size: 32),
          SizedBox(height: 8),
          Text(
            'Error al cargar comprobante',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Widget expandible que previsualiza el impacto de aprobar un pago sobre las cuotas.
class PaymentImpactPreview extends StatefulWidget {
  final List<({int index, String status, double remaining})> impacts;
  final List<Installment> installments;

  const PaymentImpactPreview({
    super.key,
    required this.impacts,
    required this.installments,
  });

  @override
  State<PaymentImpactPreview> createState() => _PaymentImpactPreviewState();
}

class _PaymentImpactPreviewState extends State<PaymentImpactPreview> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    final isFullLiquidation = widget.impacts.isNotEmpty &&
        widget.impacts.every((i) => i.status == 'PAID');
    final coversMultiple = widget.impacts.where((i) => i.status == 'PAID').length >= 2;
    _expanded = isFullLiquidation || coversMultiple;
  }

  @override
  Widget build(BuildContext context) {
    final paidCount = widget.impacts.where((i) => i.status == 'PAID').length;
    final isFullLiquidation = widget.impacts.isNotEmpty &&
        widget.impacts.every((i) => i.status == 'PAID');

    final headerColor = isFullLiquidation ? const Color(0xFF059669) : const Color(0xFF4F46E5);
    final bgColor = isFullLiquidation ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFF);
    final borderColor = isFullLiquidation ? const Color(0xFFA7F3D0) : const Color(0xFFE0E7FF);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isFullLiquidation ? Icons.verified_rounded : Icons.preview_outlined,
                    size: 18,
                    color: headerColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFullLiquidation
                          ? '✨ LIQUIDACIÓN TOTAL (Salda las $paidCount cuotas pendientes)'
                          : (paidCount > 1
                              ? '⚡ Cubre $paidCount cuotas pendientes'
                              : 'Impacto al aprobar'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: headerColor,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: headerColor,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: widget.impacts.map((impact) {
                  final installment = widget.installments[impact.index];
                  final isPaid = impact.status == 'PAID';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isPaid ? const Color(0xFFD1FAE5) : const Color(0xFFFFFBEB),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${impact.index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? const Color(0xFF047857) : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isPaid
                                ? 'Cuota ${impact.index + 1} → PAGADA (\$${installment.amount.toStringAsFixed(2)})'
                                : 'Cuota ${impact.index + 1} → queda \$${impact.remaining.toStringAsFixed(2)} pendiente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isPaid ? const Color(0xFF065F46) : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

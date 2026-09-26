import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';

/// Tarjeta de resumen financiero con barra de progreso, desglose de montos y métodos de pago.
class OrderFinancialCard extends StatelessWidget {
  final Order order;
  final String? storeId;

  const OrderFinancialCard({
    super.key,
    required this.order,
    this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    final paidAmount = order.totalPaidAmount;
    final hasDebt = order.balance > 0;
    final isInstallment = order.isPartialPayment;
    final effectiveStoreId = storeId ?? order.storeId;

    final double percentPaid = order.finalAmount > 0
        ? (paidAmount / order.finalAmount).clamp(0.0, 1.0)
        : 1.0;

    final paymentMethods = order.payments
        .map((p) => p.displayLabel)
        .toSet()
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasDebt ? const Color(0xFFFED7AA) : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
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
          // Encabezado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedMoney01,
                  color: Color(0xFF1D4ED8),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Resumen Financiero',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isInstallment ? const Color(0xFFEEF2FF) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isInstallment
                      ? (order.feeAmount > 0 ? 'CUOTAS (+RECARGO)' : 'EN CUOTAS')
                      : 'PAGO COMPLETO',
                  style: TextStyle(
                    color: isInstallment ? const Color(0xFF4F46E5) : const Color(0xFF047857),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra visual de progreso de pago
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso de Cobro (${(percentPaid * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  Text(
                    '\$${paidAmount.toStringAsFixed(2)} / \$${order.finalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percentPaid,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentPaid >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Métricas destacadas: Abonado vs Pendiente
          Row(
            children: [
              _buildMetricTile(
                label: 'Abonado',
                value: '\$${paidAmount.toStringAsFixed(2)}',
                color: const Color(0xFF047857),
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 12),
              _buildMetricTile(
                label: 'Pendiente',
                value: '\$${order.balance.toStringAsFixed(2)}',
                color: hasDebt ? const Color(0xFFB91C1C) : const Color(0xFF475569),
                icon: Icons.error_outline,
              ),
            ],
          ),

          // Métodos de pago utilizados
          if (paymentMethods.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: paymentMethods.map((method) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payment_rounded, size: 13, color: Color(0xFF475569)),
                      const SizedBox(width: 6),
                      Text(
                        method,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),

          // Desglose de facturación
          _buildRow('Subtotal (Productos)', '\$${order.totalAmount.toStringAsFixed(2)}', isBold: false),
          if (order.feeAmount > 0) ...[
            const SizedBox(height: 8),
            _buildRow('Recargo por cuotas', '+\$${order.feeAmount.toStringAsFixed(2)}', isBold: false),
          ],
          if (order.platformCommissionAmount > 0) ...[
            const SizedBox(height: 8),
            _buildRow(
              'Servicio Plataforma (+${order.platformCommissionRate.toStringAsFixed(1)}%)',
              '+\$${order.platformCommissionAmount.toStringAsFixed(2)}',
              isBold: false,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),
          _buildRow('Total Facturado', '\$${order.finalAmount.toStringAsFixed(2)}', isBold: true),

          // Enlace directo a cuentas por cobrar si es a cuotas
          if (isInstallment && effectiveStoreId != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/dashboard/stores/$effectiveStoreId/installments'),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedInvoice01,
                  color: Color(0xFF4F46E5),
                  size: 16,
                ),
                label: const Text('Ver Calendario de Cobros Global'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {required bool isBold}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 15 : 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isBold ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            fontSize: isBold ? 17 : 13,
          ),
        ),
      ],
    );
  }
}

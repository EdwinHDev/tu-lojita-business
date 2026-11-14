import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';

/// Tarjeta de resumen financiero con barra de progreso, desglose de montos y métodos de pago.
class OrderFinancialCard extends StatelessWidget {
  final Order order;
  final String? storeId;
  final bool canViewSensitiveFinances;

  const OrderFinancialCard({
    super.key,
    required this.order,
    this.storeId,
    this.canViewSensitiveFinances = true,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Progreso de Cobro (${(percentPaid * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DualPriceText(
                          amountInUsd: paidAmount,
                          customRate: order.exchangeRate,
                          isInline: true,
                          useScaleDown: true,
                          usdStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          bsStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                        ),
                        const Text(
                          '/',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        DualPriceText(
                          amountInUsd: order.finalAmount,
                          customRate: order.exchangeRate,
                          isInline: true,
                          useScaleDown: true,
                          usdStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          bsStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricTile(
                label: 'Abonado',
                amountInUsd: paidAmount,
                color: const Color(0xFF047857),
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 12),
              _buildMetricTile(
                label: 'Pendiente',
                amountInUsd: order.balance,
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

          // Desglose de facturación y liquidación para el comercio
          if (order.feeAmount > 0 || (canViewSensitiveFinances && order.platformCommissionAmount > 0)) ...[
            _buildRow(
              'Subtotal Artículos (Público)',
              amountInUsd: order.totalAmount,
              isBold: false,
            ),
            const SizedBox(height: 8),
          ],
          if (order.feeAmount > 0) ...[
            _buildRow(
              '• Recargo por cuotas tienda',
              amountInUsd: order.feeAmount,
              prefix: '+',
              isBold: false,
            ),
            const SizedBox(height: 8),
          ],
          _buildRow(
            'Total Cobrado al Cliente',
            amountInUsd: order.finalAmount,
            isBold: true,
          ),
          if (canViewSensitiveFinances) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Color(0xFFF1F5F9), height: 1),
            ),
            if (order.platformCommissionAmount > 0) ...[
              _buildRow(
                order.platformCommissionRate > 0
                    ? 'Comisión Plataforma (${_formatRate(order.platformCommissionRate)}%)'
                    : 'Comisión Plataforma (adeudada)',
                amountInUsd: order.platformCommissionAmount,
                prefix: '-',
                isBold: false,
                valueColor: const Color(0xFFB45309),
              ),
              const SizedBox(height: 8),
            ],
            _buildRow(
              'Tu Ingreso Neto Tienda',
              amountInUsd: order.finalAmount - order.platformCommissionAmount,
              isBold: true,
              valueColor: const Color(0xFF047857),
            ),
          ],

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
    required double amountInUsd,
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
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            DualPriceText(
              amountInUsd: amountInUsd,
              customRate: order.exchangeRate,
              useScaleDown: true,
              usdStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              bsStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.78)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRate(double rate) {
    if ((rate - rate.roundToDouble()).abs() < 0.01) {
      return rate.round().toString();
    }
    return rate.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  Widget _buildRow(
    String label, {
    required double amountInUsd,
    required bool isBold,
    Color? valueColor,
    String? prefix,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: DualPriceText(
            amountInUsd: amountInUsd,
            customRate: order.exchangeRate,
            prefix: prefix,
            crossAxisAlignment: CrossAxisAlignment.end,
            useScaleDown: true,
            usdStyle: TextStyle(
              color: valueColor ?? (isBold ? const Color(0xFF4F46E5) : const Color(0xFF0F172A)),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              fontSize: isBold ? 17 : 13,
            ),
            bsStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import '../../../domain/entities/order.dart';

/// Tarjeta Bento prioritaria que resume las acciones operativas urgentes
/// del pedido y permite saltar directamente a la sección correspondiente.
class OrderUrgentActionCard extends StatelessWidget {
  final Order order;
  final bool canApproveInstallments;
  final bool canRejectInstallments;
  final bool canProcessOrders;
  final VoidCallback? onJumpToPayments;
  final VoidCallback? onJumpToInstallments;
  final VoidCallback? onJumpToPreOrder;

  const OrderUrgentActionCard({
    super.key,
    required this.order,
    this.canApproveInstallments = true,
    this.canRejectInstallments = true,
    this.canProcessOrders = true,
    this.onJumpToPayments,
    this.onJumpToInstallments,
    this.onJumpToPreOrder,
  });

  /// Indica si el pedido posee gestiones operativas prioritarias pendientes.
  static bool hasUrgentActions(Order order) {
    final isCancelled = order.status == 'CANCELLED';
    final hasWaitingPayment = !isCancelled &&
        order.payments.any((p) => p.status == 'WAITING_VERIFICATION');
    final hasRefundAction = isCancelled &&
        order.payments.any(
          (p) => p.status == 'WAITING_VERIFICATION' || p.status == 'PENDING',
        );
    final hasExtension =
        order.installments.any((i) => i.extensionStatus == 'PENDING');
    final needsStock = order.isAwaitingStock && !isCancelled;
    return hasWaitingPayment || hasRefundAction || hasExtension || needsStock;
  }

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = order.status == 'CANCELLED';

    final waitingPayments = isCancelled
        ? const <Payment>[]
        : order.payments
            .where((p) => p.status == 'WAITING_VERIFICATION')
            .toList();

    final refundRequiredPayments = isCancelled
        ? order.payments
            .where(
              (p) =>
                  p.status == 'WAITING_VERIFICATION' || p.status == 'PENDING',
            )
            .toList()
        : const <Payment>[];

    final List<int> pendingExtensionIndices = [];
    for (var i = 0; i < order.installments.length; i++) {
      if (order.installments[i].extensionStatus == 'PENDING') {
        pendingExtensionIndices.add(i + 1);
      }
    }

    final bool needsStockArrival = order.isAwaitingStock && !isCancelled;

    final List<_UrgentActionItem> items = [];

    if (waitingPayments.isNotEmpty) {
      final double totalUsd =
          waitingPayments.fold<double>(0, (sum, p) => sum + p.amount);
      final int count = waitingPayments.length;
      final bool canVerify = canApproveInstallments || canRejectInstallments;
      items.add(
        _UrgentActionItem(
          icon: Icons.verified_user_outlined,
          accentColor: const Color(0xFFD97706),
          badgeBg: const Color(0xFFFEF3C7),
          title: count == 1
              ? '1 comprobante por verificar'
              : '$count comprobantes por verificar',
          amountUsd: totalUsd,
          helperText: canVerify
              ? 'Confirma o rechaza el pago reportado por el cliente.'
              : 'Solo lectura: requiere permiso para verificar pagos.',
          actionLabel: canVerify ? 'Revisar ahora' : 'Ver sección',
          onTap: onJumpToPayments,
        ),
      );
    }

    if (refundRequiredPayments.isNotEmpty) {
      final double totalUsd =
          refundRequiredPayments.fold<double>(0, (sum, p) => sum + p.amount);
      final int count = refundRequiredPayments.length;
      items.add(
        _UrgentActionItem(
          icon: Icons.currency_exchange_rounded,
          accentColor: const Color(0xFFDC2626),
          badgeBg: const Color(0xFFFEE2E2),
          title: count == 1
              ? '1 reembolso pendiente por cancelación'
              : '$count reembolsos pendientes por cancelación',
          amountUsd: totalUsd,
          helperText: canProcessOrders
              ? 'Registra el reembolso o declara pago no recibido.'
              : 'Solo lectura: requiere permiso de gestión de pedidos.',
          actionLabel: canProcessOrders ? 'Revisar ahora' : 'Ver sección',
          onTap: onJumpToPayments,
        ),
      );
    }

    if (pendingExtensionIndices.isNotEmpty) {
      final cuotas = pendingExtensionIndices.map((n) => '#$n').join(', ');
      items.add(
        _UrgentActionItem(
          icon: Icons.more_time_rounded,
          accentColor: const Color(0xFFEA580C),
          badgeBg: const Color(0xFFFFEDD5),
          title: pendingExtensionIndices.length == 1
              ? 'Solicitud de prórroga pendiente (Cuota $cuotas)'
              : '${pendingExtensionIndices.length} prórrogas pendientes ($cuotas)',
          helperText: canApproveInstallments
              ? 'Aprueba o rechaza el nuevo plazo solicitado.'
              : 'Solo lectura: requiere permiso para aprobar prórrogas.',
          actionLabel: canApproveInstallments ? 'Revisar ahora' : 'Ver sección',
          onTap: onJumpToInstallments,
        ),
      );
    }

    if (needsStockArrival) {
      items.add(
        _UrgentActionItem(
          icon: Icons.inventory_2_outlined,
          accentColor: const Color(0xFF2563EB),
          badgeBg: const Color(0xFFDBEAFE),
          title: 'Preventa esperando llegada de stock',
          helperText: canProcessOrders
              ? 'Marca el stock como recibido cuando llegue para continuar.'
              : 'Solo lectura: requiere permiso de gestión de pedidos.',
          actionLabel: canProcessOrders ? 'Revisar ahora' : 'Ver sección',
          onTap: onJumpToPreOrder,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    final bool hasRefund = refundRequiredPayments.isNotEmpty;
    final Color primaryAccent =
        hasRefund ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final Color cardBg =
        hasRefund ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final Color borderColor =
        hasRefund ? const Color(0xFFFECACA) : const Color(0xFFFDE68A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryAccent.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.priority_high_rounded,
                  size: 18,
                  color: primaryAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acción Requerida',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryAccent,
                      ),
                    ),
                    Text(
                      items.length == 1
                          ? 'Tienes 1 gestión operativa pendiente en este pedido'
                          : 'Tienes ${items.length} gestiones operativas pendientes',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 8),
              child: _UrgentAlertTile(item: item),
            );
          }),
        ],
      ),
    );
  }
}

class _UrgentActionItem {
  final IconData icon;
  final Color accentColor;
  final Color badgeBg;
  final String title;
  final double? amountUsd;
  final String helperText;
  final String actionLabel;
  final VoidCallback? onTap;

  const _UrgentActionItem({
    required this.icon,
    required this.accentColor,
    required this.badgeBg,
    required this.title,
    this.amountUsd,
    required this.helperText,
    required this.actionLabel,
    this.onTap,
  });
}

class _UrgentAlertTile extends StatelessWidget {
  final _UrgentActionItem item;

  const _UrgentAlertTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 16, color: item.accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.helperText,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.amountUsd != null || item.onTap != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                if (item.amountUsd != null)
                  DualPriceText(
                    amountInUsd: item.amountUsd!,
                    useScaleDown: true,
                    usdStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    bsStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                if (item.onTap != null)
                  FilledButton.tonalIcon(
                    onPressed: item.onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: item.badgeBg,
                      foregroundColor: item.accentColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 15),
                    label: Text(
                      item.actionLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

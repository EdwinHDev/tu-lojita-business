import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import '../../providers/dispute_providers.dart';
import 'order_detail_helpers.dart';
import 'order_dispute_bottom_sheet.dart';

/// AppBar especializada para el detalle de orden de la tienda con accesos directos (Chat y Reclamos con Badge).
class OrderDetailAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Order order;
  final String? storeId;

  const OrderDetailAppBar({
    super.key,
    required this.order,
    this.storeId,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveStoreId = storeId ?? order.storeId;
    final hasPendingRefund = order.payments.any((p) =>
        p.status == 'WAITING_VERIFICATION' ||
        p.status == 'REFUND_PENDING' ||
        p.status == 'PENDING');
    final isClosed = order.status == 'FULLY_PAID' ||
        ((order.status == 'CANCELLED' || order.status == 'REJECTED') && !hasPendingRefund);
    final shortId = order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase();
    final activeDispute = ref.watch(activeStoreDisputeProvider(order.id));
    final authState = ref.watch(authProvider);
    final currentUser = authState is Authenticated ? authState.user : null;
    final canChat = currentUser?.canChatWithCustomer ?? true;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          color: Color(0xFF1E293B),
          size: 22,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalle de Orden',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          InkWell(
            onTap: () => OrderDetailHelpers.copyToClipboard(
              context: context,
              text: order.id,
              label: 'ID de orden',
            ),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#$shortId',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Acceso rápido a Reclamo / Mediación si existe reporte
        if (activeDispute != null) ...[
          IconButton(
            tooltip: activeDispute.status.isActive
                ? 'Reclamo activo (${activeDispute.status.label})'
                : 'Detalles del reclamo',
            onPressed: () {
              OrderDisputeBottomSheet.show(
                context,
                orderId: order.id,
                dispute: activeDispute,
              );
            },
            icon: Badge(
              isLabelVisible: activeDispute.status.isActive,
              backgroundColor: const Color(0xFFDC2626),
              smallSize: 9,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAlertSquare,
                color: activeDispute.status.isActive
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF64748B),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],

        // Botón de Chat / Historial
        if (canChat)
          IconButton(
            icon: isClosed
                ? const Icon(
                    Icons.history_rounded,
                    color: Color(0xFF64748B),
                    size: 22,
                  )
                : const HugeIcon(
                    icon: HugeIcons.strokeRoundedComment01,
                    color: Color(0xFF4F46E5),
                    size: 22,
                  ),
            tooltip: isClosed
                ? 'Ver historial de chat'
                : 'Chatear con el cliente',
            onPressed: () {
              if (effectiveStoreId == null) return;
              final user = order.user;
              final firstName = user?['firstName'] ?? 'Cliente';
              final lastName = user?['lastName'] ?? '';
              final userName = '$firstName $lastName'.trim();

              context.push(
                '/dashboard/stores/$effectiveStoreId/orders/${order.id}/chat?userName=$userName',
              );
            },
          ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
    );
  }
}

/// Tarjeta principal de estado con diseño visual enriquecido.
class OrderStatusCard extends StatelessWidget {
  final Order order;

  const OrderStatusCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final (baseBgColor, baseTextColor, baseIcon, baseLabel) =
        OrderDetailHelpers.getStatusStyle(order.status);

    final bool isResolved = order.isCancellationResolved;

    final Color bgColor = isResolved ? const Color(0xFFF0FDF4) : baseBgColor;
    final Color textColor = isResolved ? const Color(0xFF15803D) : baseTextColor;
    final IconData icon =
        isResolved ? Icons.check_circle_outline_rounded : baseIcon;
    final String label = isResolved ? 'Cancelada (Resuelta)' : baseLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: textColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado de la Orden',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: isResolved ? 16 : 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total del Pedido',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${order.finalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Motivo de rechazo o cancelación si existe
          Builder(
            builder: (context) {
              if (order.status != 'CANCELLED' && order.status != 'REJECTED') {
                return const SizedBox.shrink();
              }

              if (order.isCancellationResolved) {
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFF1F5F9), height: 1),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF15803D), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Orden Cerrada de Mutuo Acuerdo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF14532D),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'El cliente aceptó que los fondos no se debitaron de su cuenta. La orden quedó archivada y concluida sin reclamos ni reembolsos pendientes.',
                                  style: TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              String? effectiveReason = (order.rejectionReason != null && order.rejectionReason!.trim().isNotEmpty)
                  ? order.rejectionReason!.trim()
                  : null;

              if (effectiveReason == null) {
                for (final p in order.payments.reversed) {
                  if (p.status == 'REJECTED' && p.rejectionReason != null && p.rejectionReason!.trim().isNotEmpty) {
                    effectiveReason = p.rejectionReason!.trim();
                    break;
                  }
                }
              }

              final isRejected = order.status == 'REJECTED';
              final title = isRejected ? 'Motivo de rechazo:' : 'Motivo de cancelación:';
              final displayReason = effectiveReason ??
                  (isRejected
                      ? 'El pago o pedido fue rechazado por la tienda.'
                      : 'El pedido fue cancelado.');

              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFF1F5F9), height: 1),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFBE123C), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9F1239),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayReason,
                                style: const TextStyle(
                                  color: Color(0xFFBE123C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                'Creada el ${order.createdAt.toFriendlyDate()}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

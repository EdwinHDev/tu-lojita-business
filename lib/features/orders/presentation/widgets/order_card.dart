import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_dispute.dart';
import '../../domain/enums/dispute_enums.dart';
import 'order_detail/order_detail_helpers.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final bool hasActiveDispute;
  final bool hasUnreadDispute;
  final VoidCallback? onChatTap;
  final VoidCallback? onDisputeTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.hasActiveDispute = false,
    this.hasUnreadDispute = false,
    this.onChatTap,
    this.onDisputeTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeDispute = order.activeDispute;
    final isDisputed = hasActiveDispute || activeDispute != null;

    final customerName = order.user?['firstName'] != null
        ? '${order.user!['firstName']} ${order.user!['lastName'] ?? ''}'.trim()
        : 'Cliente';
    final customerPhone = order.user?['phone']?.toString();
    final customerAvatar = order.user?['avatar']?.toString() ??
        order.user?['profileImage']?.toString();

    final firstItem = order.orderItems.isNotEmpty ? order.orderItems.first : null;
    final rawImagePath = firstItem?.item?.mainImage ??
        (firstItem?.item?.images.isNotEmpty == true
            ? firstItem!.item!.images.first
            : '');
    final imageUrl = OrderDetailHelpers.resolveImageUrl(rawImagePath);

    final paymentMethod = order.payments.isNotEmpty
        ? order.payments.first.paymentMethod
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDisputed
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFF1F5F9),
          width: isDisputed ? 1.8 : 1.4,
        ),
        boxShadow: [
          if (isDisputed)
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: const Color(0xFF4F46E5).withValues(alpha: 0.04),
            highlightColor: const Color(0xFF4F46E5).withValues(alpha: 0.01),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Cabecera: ID, chips de reclamo y estado
                  _buildHeaderRow(isDisputed, activeDispute),

                  const SizedBox(height: 12),

                  // 2. Previa del Producto con Miniatura
                  _buildProductPreview(firstItem, imageUrl),

                  const SizedBox(height: 12),

                  // 3. Resumen del Cliente y Pills de contexto (Envío / Pago)
                  _buildCustomerAndPillsRow(customerName, customerPhone, customerAvatar, paymentMethod),

                  // 4. Banner de Reclamo Activo (si aplica)
                  if (isDisputed && activeDispute != null) ...[
                    const SizedBox(height: 12),
                    _buildDisputeNoticeBanner(activeDispute),
                  ],

                  const SizedBox(height: 14),

                  // 5. Separador
                  Container(height: 1, color: const Color(0xFFF1F5F9)),

                  const SizedBox(height: 12),

                  // 6. Barra inferior: Total y Botones de Acción Rápida
                  _buildFooterActionsRow(context, isDisputed),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Fila superior con ID de orden, chip de estado del reclamo y estado de orden
  Widget _buildHeaderRow(bool isDisputed, OrderDispute? activeDispute) {
    final orderShortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedInvoice01,
                color: Color(0xFF64748B),
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '#$orderShortId',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDisputed) ...[
              _buildDisputeStatusChip(activeDispute),
              const SizedBox(width: 6),
            ],
            _buildStatusChip(order.status),
          ],
        ),
      ],
    );
  }

  /// Chip de estado de la disputa (independiente de si fue leída)
  Widget _buildDisputeStatusChip(OrderDispute? dispute) {
    Color bg;
    Color border;
    Color text;
    String label;
    IconData icon;

    if (dispute == null || dispute.status == DisputeStatus.open) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFCA5A5);
      text = const Color(0xFFDC2626);
      label = 'Reclamo Abierto';
      icon = Icons.gavel_rounded;
    } else if (dispute.status == DisputeStatus.merchantResponded) {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFBFDBFE);
      text = const Color(0xFF2563EB);
      label = 'Respondido';
      icon = Icons.mark_chat_read_rounded;
    } else if (dispute.status == DisputeStatus.adminReview) {
      bg = const Color(0xFFFAF5FF);
      border = const Color(0xFFE9D5FF);
      text = const Color(0xFF7C3AED);
      label = 'En Mediación';
      icon = Icons.shield_outlined;
    } else {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      text = const Color(0xFF16A34A);
      label = 'Reclamo Resuelto';
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hasUnreadDispute) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Previa del producto con miniatura e indicador de "+N productos"
  Widget _buildProductPreview(OrderItem? firstItem, String imageUrl) {
    final itemCount = order.orderItems.length;

    return Row(
      children: [
        // Miniatura
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 52,
                height: 52,
                color: const Color(0xFFF8FAFC),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholder(),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                          );
                        },
                      )
                    : _buildPlaceholder(),
              ),
            ),
            if (itemCount > 1)
              Positioned(
                right: 3,
                bottom: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${itemCount - 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Nombre y detalles del ítem
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstItem?.title ?? 'Compra en tienda',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '$itemCount artículo${itemCount != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                  const SizedBox(width: 6),
                  Text(
                    order.createdAt.toShortDateString(),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  if (order.isPartialPayment || order.feeAmount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Cuotas',
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Información del cliente con avatar y pills de contexto
  Widget _buildCustomerAndPillsRow(
    String customerName,
    String? customerPhone,
    String? customerAvatar,
    String? paymentMethod,
  ) {
    return Row(
      children: [
        // Avatar circular
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFFEEF2FF),
          backgroundImage: (customerAvatar != null && customerAvatar.isNotEmpty)
              ? NetworkImage(OrderDetailHelpers.resolveImageUrl(customerAvatar))
              : null,
          child: (customerAvatar == null || customerAvatar.isEmpty)
              ? Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  customerName,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (customerPhone != null && customerPhone.isNotEmpty) ...[
                const SizedBox(width: 6),
                const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                const SizedBox(width: 6),
                Icon(Icons.phone_rounded, size: 11, color: const Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    customerPhone,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Badge de método de pago si existe
        if (paymentMethod != null && paymentMethod.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              _formatPaymentMethod(paymentMethod),
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Banner llamativo de reclamo si está activo
  Widget _buildDisputeNoticeBanner(OrderDispute dispute) {
    final isAwaitingMerchant = dispute.status == DisputeStatus.open;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isAwaitingMerchant
            ? const Color(0xFFFFF1F2)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAwaitingMerchant
              ? const Color(0xFFFECDD3)
              : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAwaitingMerchant ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 16,
            color: isAwaitingMerchant
                ? const Color(0xFFE11D48)
                : const Color(0xFF16A34A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAwaitingMerchant
                  ? 'Reclamo: "${dispute.reason}"'
                  : 'Respuesta enviada: "${dispute.merchantResponse ?? 'En revisión'}"',
              style: TextStyle(
                color: isAwaitingMerchant
                    ? const Color(0xFF9F1239)
                    : const Color(0xFF166534),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Barra inferior con Monto total y botones de acción rápida
  Widget _buildFooterActionsRow(BuildContext context, bool isDisputed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Monto Total
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${order.finalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF4F46E5),
                fontSize: 17,
                letterSpacing: -0.2,
              ),
            ),
            if (order.feeAmount > 0)
              Text(
                'Base: \$${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        // Botones de acción rápida
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón de Chat rápido
            if (onChatTap != null) ...[
              InkWell(
                onTap: onChatTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedChat01,
                        color: Color(0xFF4F46E5),
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Chat',
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Botón de Gestionar Reclamo destacado
            if (isDisputed && onDisputeTap != null) ...[
              InkWell(
                onTap: onDisputeTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.gavel_rounded, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Gestionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Flecha para ver detalles
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: Color(0xFF94A3B8),
                size: 16,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedPackage,
          color: Color(0xFF94A3B8),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'PENDING':
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFC2410C);
        label = 'Pendiente';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'FULLY_PAID':
        bgColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF047857);
        label = 'Pagado';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'CANCELLED':
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFB91C1C);
        label = 'Cancelado';
        icon = Icons.cancel_outlined;
        break;
      case 'PARTIALLY_PAID':
        bgColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF1D4ED8);
        label = 'Abonado';
        icon = Icons.payments_outlined;
        break;
      default:
        bgColor = const Color(0xFFF8FAFC);
        textColor = const Color(0xFF64748B);
        label = status;
        icon = Icons.circle_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toUpperCase()) {
      case 'PAGO_MOVIL':
        return 'Pago Móvil';
      case 'ZELLE':
        return 'Zelle';
      case 'TRANSFERENCIA':
        return 'Transferencia';
      case 'EFECTIVO':
        return 'Efectivo';
      case 'CARD':
        return 'Tarjeta';
      default:
        return method;
    }
  }
}

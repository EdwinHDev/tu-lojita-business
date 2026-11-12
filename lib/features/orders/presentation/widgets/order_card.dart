import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
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
  final bool canViewCustomerData;
  final VoidCallback? onChatTap;
  final VoidCallback? onDisputeTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.hasActiveDispute = false,
    this.hasUnreadDispute = false,
    this.canViewCustomerData = true,
    this.onChatTap,
    this.onDisputeTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeDispute = order.activeDispute;
    final isDisputed = hasActiveDispute || activeDispute != null;
    final hasPendingReceipt = !order.isCancelled &&
        order.payments.any(
          (p) => p.status.toUpperCase() == 'WAITING_VERIFICATION',
        );
    final hasPendingExtension =
        order.installments.any((i) => i.extensionStatus == 'PENDING');

    final customerName = order.user?['firstName'] != null
        ? '${order.user!['firstName']} ${order.user!['lastName'] ?? ''}'.trim()
        : 'Cliente';
    final rawPhone = order.user?['phone']?.toString();
    final customerPhone = canViewCustomerData ? rawPhone : null;
    final customerAvatar = order.user?['avatarUrl']?.toString() ??
        order.user?['avatar']?.toString() ??
        order.user?['profileImage']?.toString();

    final firstItem = order.orderItems.isNotEmpty ? order.orderItems.first : null;
    final rawImagePath = firstItem?.resolvedThumbnail ??
        firstItem?.item?.mainImage ??
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
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDisputed
              ? const Color(0xFFFCA5A5)
              : (hasPendingReceipt
                  ? TuLojitaBrandColors.amber400
                  : TuLojitaBrandColors.borderSubtle),
          width: (isDisputed || hasPendingReceipt) ? 1.6 : 1.4,
        ),
        boxShadow: [
          if (isDisputed)
            BoxShadow(
              color: TuLojitaBrandColors.danger.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          BoxShadow(
            color: TuLojitaBrandColors.inkPrimary.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: TuLojitaBrandColors.indigo600.withValues(alpha: 0.04),
            highlightColor:
                TuLojitaBrandColors.indigo600.withValues(alpha: 0.01),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(isDisputed, activeDispute),
                  const SizedBox(height: 12),
                  _buildProductPreview(firstItem, imageUrl),
                  const SizedBox(height: 12),
                  _buildCustomerAndPillsRow(
                    customerName,
                    customerPhone,
                    customerAvatar,
                    paymentMethod,
                  ),
                  if (hasPendingReceipt ||
                      hasPendingExtension ||
                      order.balance > 0) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (hasPendingReceipt)
                          const _OperationalBadgeChip(
                            icon: Icons.fact_check_rounded,
                            label: 'Comprobante en revisión',
                            bgColor: TuLojitaBrandColors.amber50,
                            borderColor: TuLojitaBrandColors.amber400,
                            textColor: TuLojitaBrandColors.amber800,
                          ),
                        if (hasPendingExtension)
                          const _OperationalBadgeChip(
                            icon: Icons.more_time_rounded,
                            label: 'Prórroga pendiente',
                            bgColor: TuLojitaBrandColors.indigo50,
                            borderColor: TuLojitaBrandColors.indigo100,
                            textColor: TuLojitaBrandColors.indigo700,
                          ),
                        if (order.balance > 0 && !order.isCancelled)
                          const _OperationalBadgeChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Saldo pendiente',
                            bgColor: Color(0xFFFFF7ED),
                            borderColor: Color(0xFFFED7AA),
                            textColor: Color(0xFFC2410C),
                          ),
                      ],
                    ),
                  ],
                  if (isDisputed && activeDispute != null) ...[
                    const SizedBox(height: 12),
                    _buildDisputeNoticeBanner(activeDispute),
                  ],
                  const SizedBox(height: 14),
                  Container(height: 1, color: TuLojitaBrandColors.borderSubtle),
                  const SizedBox(height: 12),
                  _buildFooterActionsRow(context, isDisputed),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Fila superior con ID de orden y chips de estado con ajuste seguro a 320px @ 1.35x.
  Widget _buildHeaderRow(bool isDisputed, OrderDispute? activeDispute) {
    final orderShortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: TuLojitaBrandColors.borderSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedInvoice01,
                  color: TuLojitaBrandColors.inkSecondary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '#$orderShortId',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.inkPrimary,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isDisputed) _buildDisputeStatusChip(activeDispute),
              _buildStatusChip(order.status),
            ],
          ),
        ],
      ),
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
      bg = TuLojitaBrandColors.dangerBg;
      border = const Color(0xFFFCA5A5);
      text = TuLojitaBrandColors.danger;
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
      bg = TuLojitaBrandColors.positiveBg;
      border = const Color(0xFFBBF7D0);
      text = TuLojitaBrandColors.positive;
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
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
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 52,
                height: 52,
                color: TuLojitaBrandColors.canvas,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                        loadingBuilder: (context, child, progress) {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstItem?.title ?? 'Compra en tienda',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '$itemCount artículo${itemCount != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: TuLojitaBrandColors.inkSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                  Text(
                    order.createdAt.toShortDateString(),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  if (order.isPartialPayment || order.feeAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.indigo50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Cuotas',
                        style: TextStyle(
                          color: TuLojitaBrandColors.indigo600,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Información del cliente (protegida según permiso) y badge de método de pago
  Widget _buildCustomerAndPillsRow(
    String customerName,
    String? customerPhone,
    String? customerAvatar,
    String? paymentMethod,
  ) {
    final hasPhone = customerPhone != null && customerPhone.isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: TuLojitaBrandColors.indigo50,
          backgroundImage: (customerAvatar != null && customerAvatar.isNotEmpty)
              ? NetworkImage(OrderDetailHelpers.resolveImageUrl(customerAvatar))
              : null,
          child: (customerAvatar == null || customerAvatar.isEmpty)
              ? Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: TuLojitaBrandColors.indigo600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                customerName,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasPhone)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.phone_rounded,
                      size: 11,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        customerPhone,
                        style: const TextStyle(
                          color: TuLojitaBrandColors.inkSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else if (!canViewCustomerData)
                const Text(
                  '• Contacto protegido',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        if (paymentMethod != null && paymentMethod.isNotEmpty) ...[
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 116),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: TuLojitaBrandColors.canvas,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: TuLojitaBrandColors.borderMuted),
              ),
              child: Text(
                OrderDetailHelpers.formatPaymentMethod(paymentMethod),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
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
            : TuLojitaBrandColors.positiveBg,
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
            isAwaitingMerchant
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline,
            size: 16,
            color: isAwaitingMerchant
                ? const Color(0xFFE11D48)
                : TuLojitaBrandColors.positive,
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

  /// Barra inferior con montos duales (Total, Base y Saldo) y acciones rápidas
  Widget _buildFooterActionsRow(BuildContext context, bool isDisputed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DualPriceText(
                amountInUsd: order.finalAmount,
                useScaleDown: true,
                usdStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: TuLojitaBrandColors.indigo600,
                  fontSize: 17,
                  letterSpacing: -0.2,
                ),
                bsStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
              if (order.feeAmount > 0) ...[
                const SizedBox(height: 4),
                DualPriceText(
                  amountInUsd: order.totalAmount,
                  prefix: 'Base: ',
                  isInline: true,
                  useScaleDown: true,
                  usdStyle: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  bsStyle: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (order.balance > 0 && !order.isCancelled) ...[
                const SizedBox(height: 3),
                DualPriceText(
                  amountInUsd: order.balance,
                  prefix: 'Saldo: ',
                  isInline: true,
                  useScaleDown: true,
                  usdStyle: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFC2410C),
                    fontWeight: FontWeight.w700,
                  ),
                  bsStyle: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFEA580C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (onChatTap != null)
                Material(
                  color: TuLojitaBrandColors.indigo50,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onChatTap,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedChat01,
                            color: TuLojitaBrandColors.indigo600,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Chat',
                            style: TextStyle(
                              color: TuLojitaBrandColors.indigo600,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isDisputed && onDisputeTap != null)
                Material(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onDisputeTap,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.gavel_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
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
                )
              else
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: Color(0xFF94A3B8),
                  size: 16,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: TuLojitaBrandColors.borderSubtle,
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
    final (bgColor, textColor, icon, label) =
        OrderDetailHelpers.getStatusStyle(status);

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
}

class _OperationalBadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _OperationalBadgeChip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

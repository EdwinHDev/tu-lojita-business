import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/utils/error_parser.dart';
import 'package:tu_lojita_business/core/utils/notification_helper.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import '../providers/orders_provider.dart';
import '../providers/dispute_providers.dart';

// Componentes modulares del detalle de orden
import '../widgets/order_detail/order_detail_header.dart';
import '../widgets/order_detail/order_customer_card.dart';
import '../widgets/order_detail/order_items_card.dart';
import '../widgets/order_detail/order_financial_card.dart';
import '../widgets/order_detail/order_installments_card.dart';
import '../widgets/order_detail/order_payments_card.dart';
import '../widgets/order_detail/order_detail_bottom_bar.dart';
import '../widgets/order_detail/order_detail_dialogs.dart';
import '../widgets/order_detail/order_dispute_bottom_sheet.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/block_customer_dialog.dart';
import 'package:tu_lojita_business/features/reviews/presentation/widgets/buyer_review_card.dart';
import 'package:tu_lojita_business/features/reviews/presentation/widgets/order_review_vendor_card.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final Order? order;
  final String? orderId;
  final String? storeId;
  final bool autoOpenDispute;

  const OrderDetailsScreen({
    super.key,
    this.order,
    this.orderId,
    this.storeId,
    this.autoOpenDispute = false,
  }) : assert(order != null || orderId != null);

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  Order? currentOrder;
  bool _isUpdating = false;
  bool _autoDisputeHandled = false;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      currentOrder = widget.order;
    }
    _clearNotifications();
  }

  void _clearNotifications() {
    final orderId = widget.orderId ?? widget.order?.id;
    if (orderId == null) return;

    NotificationHelper.cancelNotification(orderId.hashCode);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationsAsync = ref.read(notificationsProvider);
      if (notificationsAsync.value != null) {
        final unreadForOrder = notificationsAsync.value!
            .where((n) => !n.isRead && n.targetId == orderId)
            .toList();

        if (unreadForOrder.isNotEmpty) {
          final repo = ref.read(notificationRepositoryProvider);
          Future.wait(unreadForOrder.map((n) => repo.markAsRead(n.id))).then((_) {
            if (mounted) {
              ref.invalidate(notificationsProvider);
            }
          });
        }
      }
      ref.read(notificationRepositoryProvider).markDisputeRead(orderId);
    });
  }

  void _checkAutoOpenDispute(String effectiveOrderId) {
    if (widget.autoOpenDispute && !_autoDisputeHandled) {
      _autoDisputeHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        OrderDisputeBottomSheet.show(context, orderId: effectiveOrderId);
      });
    }
  }

  void _invalidateCaches() {
    final orderId = widget.orderId ?? currentOrder?.id;
    final storeId = widget.storeId ?? currentOrder?.storeId;

    if (orderId != null) {
      ref.invalidate(orderByIdProvider(orderId));
      ref.invalidate(storeDisputesByOrderProvider(orderId));
    }
    if (storeId != null && storeId.isNotEmpty) {
      ref.invalidate(ordersNotifierProvider((storeId: storeId, status: null, hasDispute: null)));
      ref.invalidate(storeInstallmentsProvider(storeId));
      ref.invalidate(storeReceivablesProvider(storeId));
    }
  }

  Future<void> _confirmPayment() async {
    if (currentOrder == null) return;
    final storeId = widget.storeId ?? currentOrder?.storeId;
    if (storeId == null) return;

    final confirmed = await OrderDetailDialogs.showConfirmOrderPayment(context);
    if (confirmed != true) return;

    setState(() => _isUpdating = true);
    final updatedOrder = await ref
        .read(ordersNotifierProvider((storeId: storeId, status: null, hasDispute: null)).notifier)
        .updateOrderStatus(currentOrder!.id, 'FULLY_PAID');

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (updatedOrder != null) {
      setState(() => currentOrder = updatedOrder);
      _invalidateCaches();
      if (mounted) {
        NotificationService.showSuccess(context, 'Pago confirmado exitosamente');
      }
    } else {
      if (mounted) {
        NotificationService.showError(context, 'Error al confirmar el pago');
      }
    }
  }

  Future<void> _rejectOrder() async {
    if (currentOrder == null) return;
    final storeId = widget.storeId ?? currentOrder?.storeId;
    if (storeId == null) return;

    final reason = await OrderDetailDialogs.showRejectOrder(context);
    if (reason == null) return;

    setState(() => _isUpdating = true);
    final updatedOrder = await ref
        .read(ordersNotifierProvider((storeId: storeId, status: null, hasDispute: null)).notifier)
        .updateOrderStatus(currentOrder!.id, 'CANCELLED', reason: reason);

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (updatedOrder != null) {
      setState(() => currentOrder = updatedOrder);
      _invalidateCaches();
      if (mounted) {
        NotificationService.showSuccess(context, 'Orden rechazada exitosamente');
      }
    }
  }

  Future<void> _approveIndividualPayment(Payment payment) async {
    if (_isUpdating || currentOrder == null) return;

    final confirmed = await OrderDetailDialogs.showConfirmApprovePayment(
      context,
      payment: payment,
      order: currentOrder!,
    );
    if (confirmed != true) return;

    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final updatedOrder = await repo.verifyPayment(
        payment.id,
        'APPROVED',
        currentOrder!.id,
      );

      _invalidateCaches();

      if (mounted) {
        setState(() {
          currentOrder = updatedOrder;
          _isUpdating = false;
        });
        NotificationService.showSuccess(context, 'Pago aprobado con éxito');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        final cleanMsg = ErrorParser.parse(e)
            .replaceAll('Exception: ', '')
            .replaceAll('ServerException: ', '');
        NotificationService.showError(context, 'No se pudo aprobar el pago: $cleanMsg');
      }
    }
  }

  Future<void> _rejectIndividualPayment(Payment payment) async {
    if (_isUpdating || currentOrder == null) return;

    final action = await OrderDetailDialogs.showRejectPaymentBottomSheet(
      context,
      payment: payment,
    );
    if (action == null) return;

    final storeId = (widget.storeId != null && widget.storeId!.isNotEmpty)
        ? widget.storeId!
        : (currentOrder?.storeId ?? '');
    final user = currentOrder?.user;
    final customerId = user?['id']?.toString() ?? '';
    final firstName = user?['firstName'] as String? ?? 'Cliente';
    final lastName = user?['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = user?['email'] as String?;
    final avatar = user?['avatar'] as String?;

    bool customerWasBlocked = false;

    if (action.shouldRestrictCustomer && storeId.isNotEmpty) {
      if (!mounted) return;
      final blockResult = await BlockCustomerDialog.show(
        context: context,
        storeId: storeId,
        customerId: customerId.isNotEmpty ? customerId : null,
        customerName: fullName.isNotEmpty ? fullName : null,
        customerEmail:
            (email != null && email != 'Sin correo registrado') ? email : null,
        customerAvatar: avatar,
      );
      if (blockResult == true) {
        customerWasBlocked = true;
      }
    }

    if (!mounted) return;
    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final updatedOrder = await repo.verifyPayment(
        payment.id,
        'REJECTED',
        currentOrder!.id,
        rejectionReason: action.reason,
      );

      _invalidateCaches();

      if (mounted) {
        setState(() {
          currentOrder = updatedOrder;
          _isUpdating = false;
        });
        if (customerWasBlocked) {
          NotificationService.showSuccess(
            context,
            'Pago rechazado y cliente restringido correctamente',
          );
        } else {
          NotificationService.showSuccess(
            context,
            'Pago rechazado correctamente',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        final cleanMsg = ErrorParser.parse(e)
            .replaceAll('Exception: ', '')
            .replaceAll('ServerException: ', '');
        NotificationService.showError(context, 'No se pudo rechazar el pago: $cleanMsg');
      }
    }
  }

  Future<void> _approveExtension(Installment installment) async {
    if (_isUpdating || currentOrder == null) return;
    setState(() => _isUpdating = true);

    try {
      final storeId = widget.storeId ?? currentOrder?.storeId ?? '';
      await ref.read(verifyExtensionProvider({
        'installmentId': installment.id,
        'status': 'APPROVED',
        'merchantComment': 'Prórroga aprobada por la tienda.',
        'storeId': storeId,
      }).future);

      _invalidateCaches();

      final orderId = widget.orderId ?? currentOrder?.id;
      if (orderId != null) {
        final refreshed = await ref.read(orderByIdProvider(orderId).future);
        if (mounted) setState(() => currentOrder = refreshed);
      }

      if (mounted) {
        setState(() => _isUpdating = false);
        NotificationService.showSuccess(context, 'Prórroga aprobada exitosamente');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        final cleanMsg = ErrorParser.parse(e).replaceAll('Exception: ', '');
        NotificationService.showError(context, 'Error al aprobar prórroga: $cleanMsg');
      }
    }
  }

  Future<void> _rejectExtension(Installment installment) async {
    if (_isUpdating || currentOrder == null) return;

    final comment = await OrderDetailDialogs.showRejectExtensionDialog(
      context,
      installment: installment,
    );
    if (comment == null) return;

    setState(() => _isUpdating = true);
    try {
      final storeId = widget.storeId ?? currentOrder?.storeId ?? '';
      await ref.read(verifyExtensionProvider({
        'installmentId': installment.id,
        'status': 'REJECTED',
        'merchantComment': comment,
        'storeId': storeId,
      }).future);

      _invalidateCaches();

      final orderId = widget.orderId ?? currentOrder?.id;
      if (orderId != null) {
        final refreshed = await ref.read(orderByIdProvider(orderId).future);
        if (mounted) setState(() => currentOrder = refreshed);
      }

      if (mounted) {
        setState(() => _isUpdating = false);
        NotificationService.showWarning(context, 'Prórroga rechazada');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        final cleanMsg = ErrorParser.parse(e).replaceAll('Exception: ', '');
        NotificationService.showError(context, 'Error al rechazar prórroga: $cleanMsg');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = widget.orderId != null
        ? ref.watch(orderByIdProvider(widget.orderId!))
        : null;

    currentOrder = orderAsync?.asData?.value ?? currentOrder ?? widget.order;

    if (currentOrder == null) {
      if (orderAsync != null && orderAsync.isLoading) {
        return _buildLoading();
      }
      if (orderAsync != null && orderAsync.hasError) {
        return _buildError(orderAsync.error.toString());
      }
      return _buildError('Orden no encontrada');
    }

    final order = currentOrder!;
    _checkAutoOpenDispute(order.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: OrderDetailAppBar(
        order: order,
        storeId: widget.storeId,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF4F46E5),
        onRefresh: () async {
          final orderId = widget.orderId ?? order.id;
          ref.invalidate(orderByIdProvider(orderId));
          ref.invalidate(storeDisputesByOrderProvider(orderId));
          await ref.read(orderByIdProvider(orderId).future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OrderStatusCard(order: order),
              const SizedBox(height: 16),
              OrderReviewVendorCard(order: order),
              BuyerReviewCard(order: order),
              OrderCustomerCard(order: order, storeId: widget.storeId),
              const SizedBox(height: 16),
              _buildSectionTitle('Artículos del pedido'),
              const SizedBox(height: 8),
              OrderItemsCard(order: order),
              const SizedBox(height: 16),
              OrderFinancialCard(
                order: order,
                storeId: widget.storeId,
              ),
              if (order.installments.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Plan de Pagos / Cuotas'),
                const SizedBox(height: 8),
                OrderInstallmentsCard(
                  order: order,
                  isUpdating: _isUpdating,
                  onApproveExtension: _approveExtension,
                  onRejectExtension: _rejectExtension,
                ),
              ],
              if (order.payments.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Comprobantes de Pago'),
                const SizedBox(height: 8),
                OrderPaymentsCard(
                  order: order,
                  isUpdating: _isUpdating,
                  onApprovePayment: _approveIndividualPayment,
                  onRejectPayment: _rejectIndividualPayment,
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: OrderDetailBottomBar.shouldShow(order)
          ? OrderDetailBottomBar(
              order: order,
              isUpdating: _isUpdating,
              onConfirmPayment: _confirmPayment,
              onRejectOrder: _rejectOrder,
            )
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      ),
    );
  }

  Widget _buildError(String error) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 48),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

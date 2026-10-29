import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/services/order_sync_service.dart';
import 'package:tu_lojita_business/core/services/app_lifecycle_sync_observer.dart';
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
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
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
  StreamSubscription<OrderSyncEvent>? _orderSyncSub;
  late final String _screenSyncKey;
  AppLifecycleSyncObserver? _lifecycleSyncObserver;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      currentOrder = widget.order;
    }
    _clearNotifications();

    final effectiveId = widget.orderId ?? widget.order?.id;
    _screenSyncKey = 'business_order_${effectiveId ?? DateTime.now().millisecondsSinceEpoch}';

    if (effectiveId != null) {
      final syncService = ref.read(orderSyncServiceProvider);
      _orderSyncSub = syncService.eventsForOrder(effectiveId).listen((event) {
        _handleOrderSyncEvent(event);
      });

      _lifecycleSyncObserver = ref.read(appLifecycleSyncObserverProvider);
      _lifecycleSyncObserver?.registerTarget(_screenSyncKey, () async {
        await _silentRefreshOrder(showFeedback: false);
      });
    }
  }

  @override
  void dispose() {
    _orderSyncSub?.cancel();
    _lifecycleSyncObserver?.unregisterTarget(_screenSyncKey);
    super.dispose();
  }

  Future<void> _silentRefreshOrder({bool showFeedback = false, String? feedbackMessage}) async {
    final effectiveId = widget.orderId ?? widget.order?.id ?? currentOrder?.id;
    if (effectiveId == null || !mounted) return;

    try {
      ref.invalidate(orderByIdProvider(effectiveId));
      ref.invalidate(storeDisputesByOrderProvider(effectiveId));
      ref.invalidate(activeStoreDisputeProvider(effectiveId));

      final updated = await ref.read(orderByIdProvider(effectiveId).future);
      if (!mounted) return;

      final previousStatus = currentOrder?.status;
      setState(() {
        currentOrder = updated;
      });

      if (showFeedback && mounted) {
        final msg = feedbackMessage ??
            (previousStatus != null && previousStatus != updated.status
                ? 'Estado del pedido actualizado en tiempo real'
                : 'Detalle de la orden sincronizado en tiempo real');
        NotificationService.showInfo(context, msg);
      }
    } catch (e) {
      log('Error during silent order refresh in business: $e');
    }
  }

  void _handleOrderSyncEvent(OrderSyncEvent event) {
    if (!mounted) return;
    _silentRefreshOrder();
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

  Future<void> _refundIndividualPayment(Payment payment) async {
    if (_isUpdating || currentOrder == null) return;

    final result = await OrderDetailDialogs.showProcessRefundBottomSheet(
      context,
      payment: payment,
      order: currentOrder!,
      ref: ref,
    );
    if (result == null) return;

    if (!mounted) return;
    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final updatedOrder = await repo.verifyPayment(
        payment.id,
        'REFUND_PENDING',
        currentOrder!.id,
        rejectionReason: result.reference,
        receiptImage: result.receiptImage,
      );

      _invalidateCaches();

      if (mounted) {
        setState(() {
          currentOrder = updatedOrder;
          _isUpdating = false;
        });
        NotificationService.showSuccess(
          context,
          'Reembolso registrado y notificado al cliente para su verificación',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        final cleanMsg = ErrorParser.parse(e)
            .replaceAll('Exception: ', '')
            .replaceAll('ServerException: ', '');
        NotificationService.showError(
          context,
          'No se pudo registrar el reembolso: $cleanMsg',
        );
      }
    }
  }

  Future<void> _markPaymentNotReceived(Payment payment) async {
    if (_isUpdating || currentOrder == null) return;

    final reason = await OrderDetailDialogs.showMarkPaymentNotReceivedDialog(
      context,
      payment: payment,
    );
    if (reason == null) return;

    if (!mounted) return;
    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final updatedOrder = await repo.verifyPayment(
        payment.id,
        'REJECTED',
        currentOrder!.id,
        rejectionReason: reason,
      );

      _invalidateCaches();

      if (mounted) {
        setState(() {
          currentOrder = updatedOrder;
          _isUpdating = false;
        });
        NotificationService.showSuccess(
          context,
          'Comprobante marcado como no recibido. Se notificó al cliente.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        final cleanMsg = ErrorParser.parse(e)
            .replaceAll('Exception: ', '')
            .replaceAll('ServerException: ', '');
        NotificationService.showError(
          context,
          'No se pudo actualizar el comprobante: $cleanMsg',
        );
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

  Future<void> _markPreOrderStockArrived() async {
    if (_isUpdating || currentOrder == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Llegada de Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Al confirmar que la mercancía ha llegado a la tienda, el comprador recibirá una notificación inmediata para que proceda a liquidar el saldo pendiente antes de la fecha límite.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Confirmar Llegada'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final updated = await repo.markPreOrderStockArrived(currentOrder!.id);
      _invalidateCaches();
      if (mounted) {
        setState(() {
          currentOrder = updated;
          _isUpdating = false;
        });
        NotificationService.showSuccess(context, '¡Stock marcado como recibido! Comprador notificado.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        final cleanMsg = ErrorParser.parse(e).replaceAll('Exception: ', '');
        NotificationService.showError(context, 'Error al marcar recepción: $cleanMsg');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOrderId = widget.orderId ?? widget.order?.id ?? currentOrder?.id;
    final orderAsync = effectiveOrderId != null
        ? ref.watch(orderByIdProvider(effectiveOrderId))
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
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final canProcess = user?.canProcessOrders ?? true;
    final canCancel = user?.canCancelOrders ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: OrderDetailAppBar(
        order: order,
        storeId: widget.storeId,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF4F46E5),
        onRefresh: () async {
          final orderId = effectiveOrderId ?? order.id;
          ref.invalidate(orderByIdProvider(orderId));
          ref.invalidate(storeDisputesByOrderProvider(orderId));
          ref.invalidate(activeStoreDisputeProvider(orderId));
          final storeId = widget.storeId ?? order.storeId;
          if (storeId != null && storeId.isNotEmpty) {
            ref.invalidate(ordersNotifierProvider);
            ref.invalidate(storeInstallmentsProvider(storeId));
          }
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
              if (order.isPreOrder) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Control de Preventa (Bajo Demanda)'),
                const SizedBox(height: 8),
                _buildPreOrderCard(order),
              ],
              if (order.hasSlotBookings) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Reserva de Turno / Agenda'),
                const SizedBox(height: 8),
                _buildSlotBookingsCard(order),
              ],
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
                  onRefundPayment: _refundIndividualPayment,
                  onMarkPaymentNotReceived: _markPaymentNotReceived,
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
              onConfirmPayment: canProcess ? _confirmPayment : null,
              onRejectOrder: canCancel ? _rejectOrder : null,
            )
          : null,
    );
  }

  Widget _buildPreOrderCard(Order order) {
    String statusLabel = 'En Espera';
    Color statusColor = const Color(0xFF2563EB);
    switch (order.preOrderStatus) {
      case 'AWAITING_STOCK':
        statusLabel = 'Esperando Recepción de Stock';
        statusColor = const Color(0xFFD97706);
        break;
      case 'STOCK_ARRIVED':
        statusLabel = 'Stock Recibido en Tienda';
        statusColor = const Color(0xFF059669);
        break;
      case 'READY_FOR_SETTLEMENT':
        statusLabel = 'Listo para Liquidar Saldo';
        statusColor = const Color(0xFF4F46E5);
        break;
      case 'FULFILLED':
        statusLabel = 'Entregado al Cliente';
        statusColor = const Color(0xFF10B981);
        break;
      case 'CANCELLED':
        statusLabel = 'Preventa Cancelada';
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusLabel = order.preOrderStatus ?? 'Desconocido';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Artículo Fabricado Bajo Demanda / Preventa',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.settlementDeadline != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alarm, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plazo para liquidar saldo: ${order.settlementDeadline!.day}/${order.settlementDeadline!.month}/${order.settlementDeadline!.year} ${order.settlementDeadline!.hour.toString().padLeft(2, '0')}:${order.settlementDeadline!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (order.isAwaitingStock) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isUpdating ? null : _markPreOrderStockArrived,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Stock Recibido en Tienda',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
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

  Widget _buildSlotBookingsCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month, color: Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Citas y Turnos Agendados',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      '${order.slotBookings.length} turno(s) reservado(s)',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.slotBookings.map((sb) {
            final slot = sb['slot'] is Map ? sb['slot'] : {};
            final date = sb['bookingDate']?.toString() ?? '-';
            final start = slot['startTime']?.toString() ?? '';
            final end = slot['endTime']?.toString() ?? '';
            final label = slot['label']?.toString() ?? 'Turno';
            final status = sb['status']?.toString() ?? 'CONFIRMED';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDE9FE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5B21B6)),
                        ),
                        Text(
                          '$label: $start - $end',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6D28D9)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'CONFIRMED' ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'CONFIRMED' ? const Color(0xFF065F46) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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

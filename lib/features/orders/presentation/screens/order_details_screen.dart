import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import '../../domain/entities/order.dart';
import '../../../../core/config/envs.dart';
import '../providers/orders_provider.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/utils/error_parser.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import '../widgets/receipt_image_viewer.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/core/utils/notification_helper.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final Order? order;
  final String? orderId;
  final String? storeId; // Ahora es opcional

  const OrderDetailsScreen({super.key, this.order, this.orderId, this.storeId})
    : assert(order != null || orderId != null);

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  Order? currentOrder;
  bool _isUpdating = false;

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
    if (orderId != null) {
      // Cancelar notificación local del sistema operativo
      NotificationHelper.cancelNotification(orderId.hashCode);
      
      // Marcar como leída en el backend (después de que el frame se haya renderizado)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notificationsAsync = ref.read(notificationsProvider);
        if (notificationsAsync.value != null) {
          final unreadForOrder = notificationsAsync.value!.where((n) => 
            !n.isRead && n.targetId == orderId
          ).toList();
          
          if (unreadForOrder.isNotEmpty) {
            final repo = ref.read(notificationRepositoryProvider);
            Future.wait(unreadForOrder.map((n) => repo.markAsRead(n.id))).then((_) {
              if (mounted) {
                ref.invalidate(notificationsProvider);
              }
            });
          }
        }
      });
    }
  }

  Future<void> _confirmPayment() async {
    if (currentOrder == null) return;

    final storeId = widget.storeId ?? currentOrder?.storeId;
    if (storeId == null) return;

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_outlined, color: Color(0xFF047857), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Confirmar Pago',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              content: const Text(
                '¿Estás seguro de que deseas confirmar el pago de esta orden? El estado cambiará a "Pagado".',
                style: TextStyle(color: Color(0xFF475569), height: 1.5, fontSize: 14),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF047857),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isUpdating = true);

      final updatedOrder = await ref
          .read(ordersNotifierProvider((storeId: storeId, status: null)).notifier)
          .updateOrderStatus(currentOrder!.id, 'FULLY_PAID');

      if (!mounted) return;
      setState(() => _isUpdating = false);

      if (updatedOrder != null) {
        setState(() => currentOrder = updatedOrder);
        if (mounted) {
          NotificationService.showSuccess(
            context,
            'Pago confirmado exitosamente',
          );
        }
      } else {
        if (mounted) {
          NotificationService.showError(context, 'Error al confirmar el pago');
        }
      }
    }
  }

  Future<void> _rejectOrder() async {
    if (currentOrder == null) return;

    final storeId = widget.storeId ?? currentOrder?.storeId;
    if (storeId == null) return;

    final reasons = [
      'Producto agotado',
      'Problemas de logística/entrega',
      'Precio incorrecto',
      'Información del cliente incompleta',
      'Otro motivo',
    ];

    String? selectedReason = reasons[0];
    final customReasonController = TextEditingController();

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: animation,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF2F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cancel_outlined, color: Color(0xFFB91C1C), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Rechazar Orden',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selecciona el motivo del rechazo para informar al cliente:',
                          style: TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        RadioGroup<String>(
                          groupValue: selectedReason,
                          onChanged: (val) =>
                              setDialogState(() => selectedReason = val),
                          child: Column(
                            children: reasons.map(
                              (reason) => RadioListTile<String>(
                                title: Text(reason, style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
                                value: reason,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: const Color(0xFFB91C1C),
                              ),
                            ).toList(),
                          ),
                        ),
                        if (selectedReason == 'Otro motivo') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: customReasonController,
                            decoration: InputDecoration(
                              hintText: 'Escribe el motivo...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFB91C1C), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 2,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFB91C1C),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Rechazar', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      final finalReason = selectedReason == 'Otro motivo'
          ? customReasonController.text
          : selectedReason;

      setState(() => _isUpdating = true);

      final updatedOrder = await ref
          .read(ordersNotifierProvider((storeId: storeId, status: null)).notifier)
          .updateOrderStatus(
            currentOrder!.id,
            'CANCELLED',
            reason: finalReason,
          );

      if (!mounted) return;
      setState(() => _isUpdating = false);

      if (updatedOrder != null) {
        setState(() => currentOrder = updatedOrder);
        if (mounted) {
          NotificationService.showSuccess(
            context,
            'Orden rechazada exitosamente',
          );
        }
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
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
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '#${currentOrder!.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (currentOrder != null)
            Builder(
              builder: (context) {
                final isClosed = currentOrder!.status == 'FULLY_PAID' || currentOrder!.status == 'CANCELLED';
                
                return IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: isClosed ? const Color(0xFF94A3B8) : const Color(0xFF4F46E5),
                  ),
                  tooltip: isClosed 
                      ? 'Ver historial de chat (Solo lectura)' 
                      : 'Chatear con el cliente',
                  onPressed: () {
                    final user = currentOrder!.user;
                    final firstName = user?['firstName'] ?? 'Cliente';
                    final lastName = user?['lastName'] ?? '';
                    final userName = '$firstName $lastName'.trim();

                    final storeId = widget.storeId ?? currentOrder?.storeId;
                    if (storeId != null) {
                      context.push(
                        '/dashboard/stores/$storeId/orders/${currentOrder!.id}/chat?userName=$userName',
                      );
                    }
                  },
                );
              }
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF4F46E5),
        onRefresh: () async {
          final orderId = widget.orderId ?? currentOrder?.id;
          if (orderId != null) {
            ref.invalidate(orderByIdProvider(orderId));
            await ref.read(orderByIdProvider(orderId).future);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildCustomerCard(),
              const SizedBox(height: 16),
              _buildSectionTitle('Artículos del pedido'),
              const SizedBox(height: 8),
              _buildItemsList(),
              const SizedBox(height: 16),
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildFinancialSummary(),
              if (currentOrder!.installments.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Plan de Pagos / Cuotas'),
                const SizedBox(height: 8),
                _buildInstallmentsSection(),
              ],
              if (currentOrder!.payments.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Comprobantes de Pago'),
                const SizedBox(height: 8),
                _buildPaymentsCard(),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      appBar: AppBar(title: const Text('Cargando orden...')),
      body: const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      ),
    );
  }

  Widget _buildError(String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text(error)),
    );
  }

  Widget _buildStatusCard() {
    final (bgColor, textColor, icon, label) = _statusStyle(
      currentOrder!.status,
    );
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de la Orden',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total del Pedido',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${currentOrder!.finalAmount.toStringAsFixed(2)}',
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
          if (currentOrder!.status == 'CANCELLED' &&
              currentOrder!.rejectionReason != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Color(0xFFF1F5F9), height: 1),
            ),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFBE123C), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Motivo de cancelación: ${currentOrder!.rejectionReason}',
                    style: const TextStyle(
                      color: Color(0xFFBE123C),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                'Creada el ${currentOrder!.createdAt.toFriendlyDate()}',
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

  Widget _buildCustomerCard() {
    final user = currentOrder!.user;
    final firstName = user?['firstName'] ?? 'Cliente';
    final lastName = user?['lastName'] ?? '';
    final email = user?['email'] ?? 'Sin correo';
    final phone = user?['phone'] as String?;
    final address = user?['address'] as String?;

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUser02,
                  color: Color(0xFF4F46E5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Datos del Cliente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName'.trim(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  phone,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  Widget _buildItemsList() {
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: currentOrder!.orderItems.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          color: Color(0xFFF1F5F9),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final item = currentOrder!.orderItems[index];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Cantidad: ${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\$${item.price.toStringAsFixed(2)} c/u',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (item.selectedOptions.isNotEmpty && item.item != null) ...[
                  const SizedBox(height: 12),
                  ...item.selectedOptions.entries.map((entry) {
                    final groupId = entry.key;
                    final optionIds = entry.value;

                    final group = item.item!.customizationGroups.firstWhere(
                      (g) => g.id == groupId,
                      orElse: () => CustomizationGroup(
                        id: groupId,
                        name: 'Personalización',
                        maxSelect: 0,
                        minSelect: 0,
                        options: [],
                      ),
                    );

                    final optCounts = <String, int>{};
                    for (final optId in optionIds) {
                      optCounts[optId] = (optCounts[optId] ?? 0) + 1;
                    }

                    if (optCounts.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_mosaic,
                                size: 14,
                                color: Color(0xFF475569),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...optCounts.entries.map((optEntry) {
                            final optId = optEntry.key;
                            final count = optEntry.value;

                            final opt = group.options.firstWhere(
                              (o) => o.id == optId,
                              orElse: () => CustomizationOption(
                                id: optId,
                                name: optId,
                                price: 0,
                              ),
                            );

                            final parts = [opt.name];
                            if (count > 1) {
                              parts.add('x$count');
                            }
                            final String nameLabel = parts.join(' ');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          size: 14,
                                          color: Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            nameLabel,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF334155),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (opt.price > 0)
                                    Text(
                                      '+\$${opt.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
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
        children: [
          _buildSummaryRow(
            'Subtotal (Productos)',
            '\$${currentOrder!.totalAmount.toStringAsFixed(2)}',
            isTotal: false,
          ),
          if (currentOrder!.feeAmount > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Color(0xFFF1F5F9), height: 1),
            ),
            _buildSummaryRow(
              'Recargo por pago en cuotas',
              '+\$${currentOrder!.feeAmount.toStringAsFixed(2)}',
              isTotal: false,
            ),
          ],
          if (currentOrder!.platformCommissionAmount > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Color(0xFFF1F5F9), height: 1),
            ),
            _buildSummaryRow(
              'Servicio Plataforma (+${currentOrder!.platformCommissionRate.toStringAsFixed(1)}%)',
              '+\$${currentOrder!.platformCommissionAmount.toStringAsFixed(2)}',
              isTotal: false,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),
          _buildSummaryRow(
            'Total Facturado al Cliente',
            '\$${currentOrder!.finalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final paidAmount = currentOrder!.totalPaidAmount;
    final hasDebt = currentOrder!.balance > 0;
    final isInstallment = currentOrder!.isPartialPayment;

    // Get unique payment methods
    final paymentMethods = currentOrder!.payments
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                  const Text(
                    'Estado Financiero',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isInstallment
                      ? const Color(0xFFEEF2FF)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isInstallment
                      ? (currentOrder!.feeAmount > 0 ? 'PAGO EN CUOTAS (+RECARGO)' : 'PAGO EN CUOTAS')
                      : 'PAGO COMPLETO',
                  style: TextStyle(
                    color: isInstallment
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF047857),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Payment method chips if available
          if (paymentMethods.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: paymentMethods.map((method) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.payment_rounded,
                        size: 12,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        method,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              _buildFinStatItem(
                'Abonado',
                '\$${paidAmount.toStringAsFixed(2)}',
                const Color(0xFF047857),
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 12),
              _buildFinStatItem(
                'Pendiente',
                '\$${currentOrder!.balance.toStringAsFixed(2)}',
                hasDebt ? const Color(0xFFB91C1C) : const Color(0xFF475569),
                Icons.error_outline,
              ),
            ],
          ),
          if (isInstallment) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final storeId = widget.storeId ?? currentOrder?.storeId;
                  if (storeId != null) {
                    context.push('/dashboard/stores/$storeId/installments');
                  }
                },
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedInvoice01,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text('Ver Cuotas y Deudas'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentsSection() {
    // Pre-calcular qué cuotas están "en revisión" por pagos en espera
    final waitingPayments = currentOrder!.payments
        .where((p) => p.status == 'WAITING_VERIFICATION')
        .toList();
    final installmentsInReview = <String>{};
    for (final wp in waitingPayments) {
      final ctx = _getInstallmentContextForPayment(wp);
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
        children: [
          ...currentOrder!.installments.asMap().entries.map((entry) {
            final index = entry.key;
            final installment = entry.value;
            final isLast = index == currentOrder!.installments.length - 1;
            
            final isInReview = installmentsInReview.contains(installment.id) ||
                (index == 0 && waitingPayments.isNotEmpty && installment.status != 'PAID');
            final isPaid = installment.status == 'PAID';
            final isInitialPayment = index == 0;
            
            // Regla: la primera cuota o pagos en revisión NUNCA pueden ser vencidos
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
              dateLabel = isInitialPayment
                  ? 'Pago inicial en verificación'
                  : 'Comprobante en verificación';
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
              dateLabel = 'Por programar (al pagar cuota anterior)';
              dateColor = const Color(0xFF64748B);
            } else {
              statusBgColor = const Color(0xFFF1F5F9);
              statusTextColor = const Color(0xFF475569);
              statusLabel = 'PENDIENTE';
              dateLabel = 'Vence: ${installment.dueDate!.toSlashDateString()}';
              dateColor = const Color(0xFF64748B);
            }

            final titleLabel = isInitialPayment ? 'Pago Inicial (Cuota 1)' : 'Cuota ${index + 1}';

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isPaid
                              ? const Color(0xFFECFDF5)
                              : (isInReview
                                  ? const Color(0xFFFFFBEB)
                                  : (isOverdue
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFEEF2FF))),
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
                                      : (isOverdue
                                          ? const Color(0xFFB91C1C)
                                          : const Color(0xFF4F46E5))),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${installment.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: dateColor,
                                fontWeight: (isOverdue || isInReview || isPaid)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
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
                ),
                if (!isLast)
                  const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 66),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required bool isTotal}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomActions() {
    if (currentOrder!.status == 'FULLY_PAID' ||
        currentOrder!.status == 'CANCELLED' ||
        currentOrder!.isPartialPayment) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _isUpdating ? null : _rejectOrder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBE123C),
                  side: const BorderSide(color: Color(0xFFBE123C)),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Rechazar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                onPressed: _isUpdating ? null : _confirmPayment,
                icon: _isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isUpdating ? 'Procesando...' : 'Confirmar Pago'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  disabledBackgroundColor: const Color(0xFF86EFAC),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData, String) _statusStyle(String status) {
    switch (status) {
      case 'PENDING':
        return (
          const Color(0xFFFFF7ED),
          const Color(0xFFC2410C),
          Icons.hourglass_empty_rounded,
          'Pendiente',
        );
      case 'FULLY_PAID':
        return (
          const Color(0xFFF0FDF4),
          const Color(0xFF15803D),
          Icons.check_circle_outline,
          'Pagado',
        );
      case 'CANCELLED':
        return (
          const Color(0xFFFFF1F2),
          const Color(0xFFBE123C),
          Icons.cancel_outlined,
          'Cancelado',
        );
      case 'PARTIALLY_PAID':
        return (
          const Color(0xFFEFF6FF),
          const Color(0xFF1D4ED8),
          Icons.payments_outlined,
          'Abonado',
        );
      default:
        return (
          const Color(0xFFF8FAFC),
          const Color(0xFF64748B),
          Icons.circle_outlined,
          status,
        );
    }
  }

  Widget _buildPaymentsCard() {
    return Column(
      children: currentOrder!.payments.map((payment) {
        final isApproved = payment.status == 'APPROVED';
        final isRejected = payment.status == 'REJECTED';
        final isWaiting = payment.status == 'WAITING_VERIFICATION';
        final imageUrl = _resolveImageUrl(payment.receiptImage ?? '');

        // Contexto de cuota para pagos en revisión
        final installmentCtx = isWaiting
            ? _getInstallmentContextForPayment(payment)
            : (installment: null, installmentIndex: -1, minRequired: 0.0);
        final coveredInstallment = installmentCtx.installment;
        final isSufficient = coveredInstallment != null &&
            (payment.amount * 100).round() >= ((installmentCtx.minRequired * 100).round() - 1);
        final impacts = isWaiting ? _getApprovalImpact(payment) : <({int index, String status, double remaining})>[];
        
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
                          size: 16,
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
                                  payment.getQuotaLabel(currentOrder!),
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

              // ── Banner de motivo de rechazo si fue rechazado ──
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

              // ── Banner de cuota asociada (solo para pagos en revisión) ──
              if (isWaiting && coveredInstallment != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSufficient
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSufficient
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5),
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
                            color: isSufficient
                                ? const Color(0xFF15803D)
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cuota ${installmentCtx.installmentIndex + 1} de ${currentOrder!.installments.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSufficient
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            coveredInstallment.dueDate != null
                                ? '· Vence ${coveredInstallment.dueDate!.toSlashDateString()}'
                                : '· Por programar',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSufficient
                                  ? const Color(0xFF166534)
                                  : const Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isSufficient
                                ? Icons.check_circle_outline
                                : Icons.error_outline_rounded,
                            size: 14,
                            color: isSufficient
                                ? const Color(0xFF15803D)
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSufficient
                                ? 'Monto suficiente ✓  (mínimo \$${installmentCtx.minRequired.toStringAsFixed(2)})'
                                : 'Monto insuficiente — requiere \$${installmentCtx.minRequired.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSufficient
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // ── Preview de impacto de aprobación ──────────────────────
              if (isWaiting && impacts.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ImpactPreview(
                  impacts: impacts,
                  installments: currentOrder!.installments,
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  const Text(
                    'Fecha:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    payment.createdAt.toDateTimeString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              if (payment.reference != null && payment.reference!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.tag, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    const Text(
                      'Referencia:',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      payment.reference!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ],
              if (imageUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Comprobante:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierColor: Colors.black,
                      barrierDismissible: true,
                      barrierLabel: 'Cerrar',
                      pageBuilder: (context, animation, secondaryAnimation) => ReceiptImageViewer(imageUrl: imageUrl),
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
                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isWaiting) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isUpdating ? null : () => _showRejectPaymentDialog(payment),
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
                      onPressed: _isUpdating ? null : () => _approveIndividualPayment(payment),
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

  // ── Helpers de contexto de cuota ──────────────────────────────────────

  /// Dado un pago, retorna la (cuota, minRequired) que ese pago cubre primero,
  /// simulando la amortización secuencial del backend.
  ({Installment? installment, int installmentIndex, double minRequired}) _getInstallmentContextForPayment(Payment payment) {
    // Cuotas ordenadas por fecha de vencimiento (o por orden de cuota si no está programada)
    final sorted = [...currentOrder!.installments];
    sorted.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    // Acumular lo ya pagado (pagos APPROVED antes que este)
    int alreadyCoveredCents = 0;
    for (final p in currentOrder!.payments) {
      if (p.id == payment.id) break;
      if (p.status == 'APPROVED') {
        alreadyCoveredCents += (p.amount * 100).round();
      }
    }

    // Recorrer cuotas y saltear las ya cubiertas por pagos anteriores
    for (int i = 0; i < sorted.length; i++) {
      final inst = sorted[i];
      final neededCents = ((inst.amount + inst.lateFeeApplied - inst.paidAmount) * 100).round();
      if (neededCents <= 1) continue; // ya pagada

      if (alreadyCoveredCents >= neededCents - 1) {
        alreadyCoveredCents -= neededCents;
        continue;
      }
      // Esta es la cuota que el pago cubre (parcial o totalmente)
      final originalIndex = currentOrder!.installments.indexOf(inst);
      final remainingCents = neededCents - alreadyCoveredCents;
      final minRequired = remainingCents > 0 ? remainingCents / 100.0 : 0.0;
      return (installment: inst, installmentIndex: originalIndex, minRequired: minRequired);
    }
    return (installment: null, installmentIndex: -1, minRequired: 0.0);
  }

  /// Calcula el impacto de aprobar un pago: qué cuotas quedan PAID y cuánto
  /// queda de la siguiente cuota si hay exceso.
  List<({int index, String status, double remaining})> _getApprovalImpact(Payment payment) {
    final sorted = [...currentOrder!.installments];
    sorted.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    int alreadyCoveredCents = 0;
    for (final p in currentOrder!.payments) {
      if (p.id == payment.id) break;
      if (p.status == 'APPROVED') {
        alreadyCoveredCents += (p.amount * 100).round();
      }
    }

    int remainingCents = (payment.amount * 100).round();
    final impacts = <({int index, String status, double remaining})>[];
    bool started = false;

    for (int i = 0; i < sorted.length; i++) {
      final inst = sorted[i];
      final neededCents = ((inst.amount + inst.lateFeeApplied - inst.paidAmount) * 100).round();
      if (neededCents <= 1) continue;

      if (!started && alreadyCoveredCents >= neededCents - 1) {
        alreadyCoveredCents -= neededCents;
        continue;
      }
      started = true;
      if (remainingCents <= 0) break;

      final originalIndex = currentOrder!.installments.indexOf(inst);
      final effectiveNeededCents = neededCents - alreadyCoveredCents;

      // Se permite tolerancia de 1 centavo ($0.01) para considerar la cuota PAGADA
      if (remainingCents >= effectiveNeededCents - 1) {
        impacts.add((index: originalIndex, status: 'PAID', remaining: 0.0));
        remainingCents -= effectiveNeededCents;
        alreadyCoveredCents = 0;
      } else {
        final newRemainingCents = effectiveNeededCents - remainingCents;
        final newRemaining = newRemainingCents > 1 ? newRemainingCents / 100.0 : 0.0;
        impacts.add((
          index: originalIndex,
          status: newRemaining <= 0.01 ? 'PAID' : 'PARTIAL',
          remaining: newRemaining <= 0.01 ? 0.0 : newRemaining,
        ));
        remainingCents = 0;
      }
    }
    return impacts;
  }

  Future<void> _approveIndividualPayment(Payment payment) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final updatedOrder = await repo.verifyPayment(
        payment.id,
        'APPROVED',
        currentOrder!.id,
      );

      final orderId = widget.orderId ?? currentOrder!.id;
      final storeId = widget.storeId ?? currentOrder?.storeId;

      ref.invalidate(orderByIdProvider(orderId));
      if (storeId != null && storeId.isNotEmpty) {
        ref.invalidate(ordersNotifierProvider((storeId: storeId, status: null)));
        ref.invalidate(storeInstallmentsProvider(storeId));
        ref.invalidate(storeReceivablesProvider(storeId));
      }

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
        NotificationService.showError(
          context,
          'No se pudo aprobar el pago: $cleanMsg',
        );
      }
    }
  }

  Future<void> _showRejectPaymentDialog(Payment payment) async {
    String selectedReason = 'Referencia bancaria no encontrada';
    final customNotesController = TextEditingController();
    final reasons = [
      'Referencia bancaria no encontrada',
      'Monto incompleto o incorrecto',
      'Comprobante ilegible o cortado',
      'Cuenta bancaria destino equivocada',
      'Otro motivo',
    ];

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: Color(0xFFDC2626),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rechazar Comprobante',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Indica el motivo para informar al cliente',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Selecciona el motivo:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => selectedReason = reason);
                          }
                        },
                        selectedColor: const Color(0xFFFEE2E2),
                        backgroundColor: const Color(0xFFF8FAFC),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF475569),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Detalle o instrucciones adicionales (opcional):',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customNotesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ej: El monto reportado fue de \$5 en lugar de \$10.',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Confirmar Rechazo', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      final extra = customNotesController.text.trim();
      final fullReason = extra.isNotEmpty && selectedReason != 'Otro motivo'
          ? '$selectedReason ($extra)'
          : (extra.isNotEmpty ? extra : selectedReason);
      await _executeRejectPayment(payment, fullReason);
    }
  }

  Future<void> _executeRejectPayment(Payment payment, String reason) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final updatedOrder = await repo.verifyPayment(
        payment.id,
        'REJECTED',
        currentOrder!.id,
        rejectionReason: reason,
      );

      final orderId = widget.orderId ?? currentOrder!.id;
      final storeId = widget.storeId ?? currentOrder?.storeId;

      ref.invalidate(orderByIdProvider(orderId));
      if (storeId != null && storeId.isNotEmpty) {
        ref.invalidate(ordersNotifierProvider((storeId: storeId, status: null)));
        ref.invalidate(storeInstallmentsProvider(storeId));
        ref.invalidate(storeReceivablesProvider(storeId));
      }

      if (mounted) {
        setState(() {
          currentOrder = updatedOrder;
          _isUpdating = false;
        });
        NotificationService.showSuccess(context, 'Pago rechazado correctamente');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        final cleanMsg = ErrorParser.parse(e)
            .replaceAll('Exception: ', '')
            .replaceAll('ServerException: ', '');
        NotificationService.showError(
          context,
          'No se pudo rechazar el pago: $cleanMsg',
        );
      }
    }
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) {
      try {
        Uri.parse(path);
        return path;
      } catch (_) {
        return '';
      }
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final url = '${Envs.apiBaseUrlImages}/$cleanPath';
    try {
      Uri.parse(url);
      return url;
    } catch (_) {
      return '';
    }
  }

  Widget _buildImageError() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8), size: 32),
          SizedBox(height: 8),
          Text(
            'Error al cargar imagen',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Widget de preview de impacto de aprobación ────────────────────────────────

class _ImpactPreview extends StatefulWidget {
  final List<({int index, String status, double remaining})> impacts;
  final List<Installment> installments;

  const _ImpactPreview({
    required this.impacts,
    required this.installments,
  });

  @override
  State<_ImpactPreview> createState() => _ImpactPreviewState();
}

class _ImpactPreviewState extends State<_ImpactPreview> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    final isFullLiquidation = widget.impacts.isNotEmpty &&
        widget.impacts.every((i) => i.status == 'PAID');
    final coversMultiple =
        widget.impacts.where((i) => i.status == 'PAID').length >= 2;
    _expanded = isFullLiquidation || coversMultiple;
  }

  @override
  Widget build(BuildContext context) {
    final paidCount = widget.impacts.where((i) => i.status == 'PAID').length;
    final isFullLiquidation = widget.impacts.isNotEmpty &&
        widget.impacts.every((i) => i.status == 'PAID');

    final headerColor = isFullLiquidation
        ? const Color(0xFF059669)
        : const Color(0xFF4F46E5);
    final bgColor = isFullLiquidation
        ? const Color(0xFFECFDF5)
        : const Color(0xFFF8FAFF);
    final borderColor = isFullLiquidation
        ? const Color(0xFFA7F3D0)
        : const Color(0xFFE0E7FF);

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
                    isFullLiquidation
                        ? Icons.verified_rounded
                        : Icons.preview_outlined,
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
                            color: isPaid
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFFFBEB),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${impact.index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPaid
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFD97706),
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
                              color: isPaid
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF92400E),
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

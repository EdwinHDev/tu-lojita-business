import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import '../../domain/entities/order.dart';
import '../../../../core/config/envs.dart';
import '../providers/orders_provider.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import '../widgets/receipt_image_viewer.dart';

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
          .read(ordersNotifierProvider(storeId).notifier)
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
          .read(ordersNotifierProvider(storeId).notifier)
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
    if (currentOrder == null && widget.orderId != null) {
      final orderFuture = ref.watch(orderByIdProvider(widget.orderId!));

      return orderFuture.when(
        data: (order) {
          Future.microtask(() {
            if (mounted) setState(() => currentOrder = order);
          });
          return _buildLoading();
        },
        loading: () => _buildLoading(),
        error: (err, stack) => _buildError(err.toString()),
      );
    }

    if (currentOrder == null) return _buildError('Orden no encontrada');

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
          if (currentOrder != null &&
              currentOrder!.status != 'FULLY_PAID' &&
              currentOrder!.status != 'CANCELLED')
            IconButton(
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF4F46E5),
              ),
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
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
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
                        allowOptionQuantity: false,
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
            'Subtotal',
            '\$${currentOrder!.totalAmount.toStringAsFixed(2)}',
            isTotal: false,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),
          _buildSummaryRow(
            'Total a Pagar',
            '\$${currentOrder!.finalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final paidAmount = currentOrder!.finalAmount - currentOrder!.balance;
    final hasDebt = currentOrder!.balance > 0;
    final isInstallment = currentOrder!.installments.isNotEmpty;

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
                      : (hasDebt
                          ? const Color(0xFFFFF7ED)
                          : const Color(0xFFECFDF5)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isInstallment
                      ? 'PAGO EN CUOTAS'
                      : (hasDebt ? 'PAGO PARCIAL' : 'PAGO COMPLETO'),
                  style: TextStyle(
                    color: isInstallment
                        ? const Color(0xFF4F46E5)
                        : (hasDebt ? const Color(0xFFC2410C) : const Color(0xFF047857)),
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
            final isOverdue = installment.dueDate.isBefore(DateTime.now()) &&
                installment.status == 'PENDING';

            Color statusBgColor;
            Color statusTextColor;
            String statusLabel;

            if (installment.status == 'PAID') {
              statusBgColor = const Color(0xFFECFDF5);
              statusTextColor = const Color(0xFF047857);
              statusLabel = 'PAGADA';
            } else if (isOverdue) {
              statusBgColor = const Color(0xFFFEF2F2);
              statusTextColor = const Color(0xFFB91C1C);
              statusLabel = 'VENCIDA';
            } else {
              statusBgColor = const Color(0xFFF1F5F9);
              statusTextColor = const Color(0xFF475569);
              statusLabel = 'PENDIENTE';
            }

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
                          color: installment.status == 'PAID'
                              ? const Color(0xFFECFDF5)
                              : (isOverdue
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFEEF2FF)),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: installment.status == 'PAID'
                                  ? const Color(0xFF047857)
                                  : (isOverdue
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF4F46E5)),
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
                              '\$${installment.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Vence: ${installment.dueDate.toSlashDateString()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOverdue
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFF64748B),
                                fontWeight:
                                    isOverdue ? FontWeight.bold : FontWeight.normal,
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
        currentOrder!.status == 'CANCELLED') {
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
        final imageUrl = _resolveImageUrl(payment.receiptImage ?? '');
        
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
                          Text(
                            isApproved ? 'Verificado' : 'En revisión',
                            style: TextStyle(
                              fontSize: 11,
                              color: isApproved ? const Color(0xFF047857) : const Color(0xFFC2410C),
                              fontWeight: FontWeight.bold,
                            ),
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
            ],
          ),
        );
      }).toList(),
    );
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath';
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

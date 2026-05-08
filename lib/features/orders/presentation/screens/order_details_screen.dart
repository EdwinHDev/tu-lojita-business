import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_provider.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final Order? order;
  final String? orderId;
  final String? storeId; // Ahora es opcional

  const OrderDetailsScreen({
    super.key,
    this.order,
    this.orderId,
    this.storeId,
  }) : assert(order != null || orderId != null);

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
    
    // Necesitamos el storeId para el notifier.
    // Si no vino por parámetro, lo sacamos de la orden.
    final storeId = widget.storeId ?? currentOrder?.storeId;
    if (storeId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.payments_outlined, color: Color(0xFF4F46E5)),
            SizedBox(width: 10),
            Text('Confirmar Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas confirmar el pago de esta orden? El estado cambiará a "Pagado".',
          style: TextStyle(color: Color(0xFF64748B), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Pago confirmado exitosamente'),
              ]),
              backgroundColor: const Color(0xFF15803D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.error_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Error al confirmar el pago'),
              ]),
              backgroundColor: const Color(0xFFBE123C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Color(0xFFBE123C)),
              SizedBox(width: 10),
              Text('Rechazar Orden', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el motivo del rechazo para informar al cliente:',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 16),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: selectedReason,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFFBE123C),
                  onChanged: (val) => setDialogState(() => selectedReason = val),
                )),
                if (selectedReason == 'Otro motivo') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customReasonController,
                    decoration: InputDecoration(
                      hintText: 'Escribe el motivo...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBE123C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Rechazar Orden'),
            ),
          ],
        ),
      ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Orden rechazada exitosamente'),
              ]),
              backgroundColor: const Color(0xFFBE123C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle de Orden',
              style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '#${currentOrder!.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
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
            _buildStatusBanner(),
            const SizedBox(height: 16),
            _buildCustomerCard(),
            const SizedBox(height: 16),
            _buildSectionTitle('Artículos del pedido'),
            const SizedBox(height: 8),
            _buildItemsList(),
            const SizedBox(height: 16),
            _buildSummaryCard(),
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
      body: const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
    );
  }

  Widget _buildError(String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text(error)),
    );
  }

  Widget _buildStatusBanner() {
    final (bgColor, textColor, icon, label) = _statusStyle(currentOrder!.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado: $label',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              if (currentOrder!.status == 'CANCELLED' && currentOrder!.rejectionReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Motivo: ${currentOrder!.rejectionReason}',
                    style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              Text(
                _formatDate(currentOrder!.createdAt),
                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            child: Text(
              firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C',
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$firstName $lastName'.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.person_outline, color: Color(0xFFCBD5E1)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: currentOrder!.orderItems.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final item = currentOrder!.orderItems[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.title} x${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
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
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (item.selectedOptions.isNotEmpty && item.item != null) ...[
                  const SizedBox(height: 8),
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
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_mosaic, size: 14, color: Color(0xFF475569)),
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
                          const SizedBox(height: 6),
                          ...optCounts.entries.map((optEntry) {
                            final optId = optEntry.key;
                            final count = optEntry.value;

                            final opt = group.options.firstWhere(
                              (o) => o.id == optId,
                              orElse: () => CustomizationOption(id: optId, name: optId, price: 0),
                            );

                            final parts = [opt.name];
                            if (count > 1) {
                              parts.add('x$count');
                            }
                            final String nameLabel = parts.join(' ');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF2563EB)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            nameLabel,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF1E293B),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', '\$${currentOrder!.totalAmount.toStringAsFixed(2)}', isTotal: false),
          if (currentOrder!.balance != currentOrder!.finalAmount) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Balance', '\$${currentOrder!.balance.toStringAsFixed(2)}', isTotal: false),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE2E8F0), height: 1),
          ),
          _buildSummaryRow('Total', '\$${currentOrder!.finalAmount.toStringAsFixed(2)}', isTotal: true),
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
            color: isTotal ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomActions() {
    if (currentOrder!.status == 'FULLY_PAID' || currentOrder!.status == 'CANCELLED') {
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isUpdating ? 'Procesando...' : 'Confirmar Pago'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  disabledBackgroundColor: const Color(0xFF86EFAC),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        return (const Color(0xFFFFF7ED), const Color(0xFFC2410C), Icons.hourglass_empty_rounded, 'Pendiente');
      case 'FULLY_PAID':
        return (const Color(0xFFF0FDF4), const Color(0xFF15803D), Icons.check_circle_outline, 'Pagado');
      case 'CANCELLED':
        return (const Color(0xFFFFF1F2), const Color(0xFFBE123C), Icons.cancel_outlined, 'Cancelado');
      case 'PARTIALLY_PAID':
        return (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), Icons.payments_outlined, 'Abonado');
      default:
        return (const Color(0xFFF8FAFC), const Color(0xFF64748B), Icons.circle_outlined, status);
    }
  }

  String _formatDate(DateTime date) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  Widget _buildPaymentsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: currentOrder!.payments.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final payment = currentOrder!.payments[index];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Método: ${payment.paymentMethod}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: payment.status == 'APPROVED' ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payment.status == 'APPROVED' ? 'Aprobado' : 'Pendiente',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: payment.status == 'APPROVED' ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Monto: \$${payment.amount.toStringAsFixed(2)} ${payment.currency}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                ),
                if (payment.reference != null && payment.reference!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Referencia: ${payment.reference}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
                if (payment.receiptImage != null && payment.receiptImage!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Comprobante adjunto:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      payment.receiptImage!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

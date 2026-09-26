import 'package:flutter/material.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';

/// Barra flotante inferior de acciones para pedidos de contado que requieren confirmación o rechazo.
class OrderDetailBottomBar extends StatelessWidget {
  final Order order;
  final bool isUpdating;
  final VoidCallback? onConfirmPayment;
  final VoidCallback? onRejectOrder;

  const OrderDetailBottomBar({
    super.key,
    required this.order,
    this.isUpdating = false,
    this.onConfirmPayment,
    this.onRejectOrder,
  });

  /// Determina si la barra inferior debe mostrarse según el estado y tipo de orden.
  /// Solo se muestra para pedidos de contado en estado PENDING que no tengan comprobantes digitales adjuntos.
  static bool shouldShow(Order? order) {
    if (order == null) return false;
    if (order.status == 'FULLY_PAID' ||
        order.status == 'CANCELLED' ||
        order.status == 'REJECTED' ||
        order.isPartialPayment ||
        order.payments.isNotEmpty) {
      return false;
    }
    return order.status == 'PENDING';
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(order)) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: isUpdating ? null : onRejectOrder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBE123C),
                  side: const BorderSide(color: Color(0xFFBE123C)),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Rechazar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                onPressed: isUpdating ? null : onConfirmPayment,
                icon: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  isUpdating ? 'Procesando...' : 'Confirmar Pago',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  disabledBackgroundColor: const Color(0xFF86EFAC),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

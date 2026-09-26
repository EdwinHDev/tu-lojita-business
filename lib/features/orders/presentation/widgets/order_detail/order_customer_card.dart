import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/block_customer_dialog.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'order_detail_helpers.dart';

/// Tarjeta interactiva con datos del cliente y acciones directas (WhatsApp, Llamada, Copiar, Restringir).
class OrderCustomerCard extends StatelessWidget {
  final Order order;
  final String? storeId;

  const OrderCustomerCard({
    super.key,
    required this.order,
    this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    final user = order.user;
    final firstName = user?['firstName'] as String? ?? 'Cliente';
    final lastName = user?['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = user?['email'] as String? ?? 'Sin correo registrado';
    final phone = user?['phone'] as String?;
    final address = user?['address'] as String?;
    final hasPhone = phone != null && phone.trim().isNotEmpty;
    final hasAddress = address != null && address.trim().isNotEmpty;
    final customerId = user?['id']?.toString() ?? '';
    final effectiveStoreId = (storeId != null && storeId!.isNotEmpty) ? storeId! : (order.storeId ?? '');

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
              const Spacer(),
              if (customerId.isNotEmpty && effectiveStoreId.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    BlockCustomerDialog.show(
                      context: context,
                      storeId: effectiveStoreId,
                      customerId: customerId,
                      customerName: fullName,
                      customerEmail: email != 'Sin correo registrado' ? email : null,
                    );
                  },
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUserBlock01,
                    size: 14,
                    color: Color(0xFFDC2626),
                  ),
                  label: const Text(
                    'Restringir',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                    ),
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
                      fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
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
          if (hasPhone) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phone,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Fila de acciones interactivas para el comerciante
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => OrderDetailHelpers.launchWhatsApp(
                      context: context,
                      phone: phone,
                      customerName: fullName,
                      storeName: order.storeName,
                      orderItems: order.orderItems,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                      backgroundColor: const Color(0xFFECFDF5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => OrderDetailHelpers.launchPhoneCall(
                      context: context,
                      phone: phone,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                      backgroundColor: const Color(0xFFEEF2FF),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.call_outlined, size: 16),
                    label: const Text(
                      'Llamar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => OrderDetailHelpers.copyToClipboard(
                    context: context,
                    text: phone,
                    label: 'Teléfono',
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                  tooltip: 'Copiar teléfono',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
          if (hasAddress) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dirección de entrega:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => OrderDetailHelpers.copyToClipboard(
                    context: context,
                    text: address,
                    label: 'Dirección',
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                  tooltip: 'Copiar dirección',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

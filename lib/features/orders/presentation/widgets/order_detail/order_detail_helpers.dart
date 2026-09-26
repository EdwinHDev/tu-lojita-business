import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order_item.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';

/// Funciones puras de cálculo de cuotas, normalización y comunicación para el detalle de órdenes.
class OrderDetailHelpers {
  /// Resuelve la URL pública para imágenes de productos y comprobantes.
  static String resolveImageUrl(String path) {
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

  /// Limpia y normaliza el número telefónico asegurando el formato internacional (predeterminado Venezuela +58).
  static String formatWhatsAppNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '58${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('58') && cleanPhone.length == 10) {
      cleanPhone = '58$cleanPhone';
    }
    return cleanPhone;
  }

  /// Formatea la lista de artículos o servicios adquiridos en una frase amigable.
  static String formatPurchasedItems(List<OrderItem> items) {
    if (items.isEmpty) return 'tu compra';
    final titles = items
        .map((e) => e.title.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (titles.isEmpty) return 'tu compra';

    if (titles.length == 1) {
      return 'tu compra de ${titles[0]}';
    } else if (titles.length == 2) {
      return 'tu compra de ${titles[0]} y ${titles[1]}';
    } else {
      return 'tu compra de ${titles[0]}, ${titles[1]} y otros artículos';
    }
  }

  /// Abre WhatsApp con un mensaje cálido, mencionando la tienda y los artículos adquiridos, sin códigos de orden.
  static Future<void> launchWhatsApp({
    required BuildContext context,
    required String phone,
    required String customerName,
    String? storeName,
    List<OrderItem> orderItems = const [],
    String? orderId,
  }) async {
    final cleanPhone = formatWhatsAppNumber(phone);
    if (cleanPhone.isEmpty) {
      NotificationService.showWarning(context, 'El cliente no tiene un teléfono válido registrado.');
      return;
    }

    final name = customerName.trim().isNotEmpty ? customerName.trim() : 'estimado cliente';
    final store = (storeName != null && storeName.trim().isNotEmpty) ? storeName.trim() : 'nuestra tienda';
    final itemsDescription = formatPurchasedItems(orderItems);
    final message = '¡Hola $name! Te escribo de $store con relación a $itemsDescription. ¿En qué podemos colaborarte hoy?';

    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        NotificationService.showError(context, 'No se pudo abrir WhatsApp en este dispositivo.');
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'Error al abrir WhatsApp: $e');
      }
    }
  }

  /// Inicia una llamada telefónica normal al número registrado del cliente.
  static Future<void> launchPhoneCall({
    required BuildContext context,
    required String phone,
  }) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanDigits.isEmpty) {
      NotificationService.showWarning(context, 'Número de teléfono no disponible.');
      return;
    }

    final uri = Uri.parse('tel:$cleanDigits');
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        NotificationService.showError(context, 'No se pudo realizar la llamada telefónica.');
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'Error al iniciar llamada: $e');
      }
    }
  }

  /// Copia un texto al portapapeles y muestra confirmación visual.
  static Future<void> copyToClipboard({
    required BuildContext context,
    required String text,
    required String label,
  }) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text.trim()));
    if (context.mounted) {
      NotificationService.showSuccess(context, '$label copiado al portapapeles');
    }
  }

  /// Dado un pago, retorna la (cuota, minRequired) que ese pago cubre primero,
  /// simulando la amortización secuencial del backend.
  static ({Installment? installment, int installmentIndex, double minRequired}) getInstallmentContextForPayment(
    Order order,
    Payment payment,
  ) {
    if (order.installments.isEmpty) {
      return (installment: null, installmentIndex: -1, minRequired: 0.0);
    }

    final sorted = [...order.installments];
    sorted.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    int alreadyCoveredCents = 0;
    for (final p in order.payments) {
      if (p.id == payment.id) break;
      if (p.status == 'APPROVED') {
        alreadyCoveredCents += (p.amount * 100).round();
      }
    }

    for (int i = 0; i < sorted.length; i++) {
      final inst = sorted[i];
      final neededCents = ((inst.amount + inst.lateFeeApplied - inst.paidAmount) * 100).round();
      if (neededCents <= 1) continue;

      if (alreadyCoveredCents >= neededCents - 1) {
        alreadyCoveredCents -= neededCents;
        continue;
      }

      final originalIndex = order.installments.indexOf(inst);
      final remainingCents = neededCents - alreadyCoveredCents;
      final minRequired = remainingCents > 0 ? remainingCents / 100.0 : 0.0;
      return (installment: inst, installmentIndex: originalIndex, minRequired: minRequired);
    }
    return (installment: null, installmentIndex: -1, minRequired: 0.0);
  }

  /// Simula y calcula el impacto que tendrá la aprobación de un pago sobre las cuotas pendientes.
  static List<({int index, String status, double remaining})> getApprovalImpact(
    Order order,
    Payment payment,
  ) {
    if (order.installments.isEmpty) return const [];

    final sorted = [...order.installments];
    sorted.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    int alreadyCoveredCents = 0;
    for (final p in order.payments) {
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

      final originalIndex = order.installments.indexOf(inst);
      final effectiveNeededCents = neededCents - alreadyCoveredCents;

      // Tolerancia de 1 centavo para considerar cuota saldada
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

  /// Retorna paleta de color, icono y etiqueta para un estado de orden.
  static (Color bgColor, Color textColor, IconData icon, String label) getStatusStyle(String status) {
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
      case 'REJECTED':
        return (
          const Color(0xFFFEF2F2),
          const Color(0xFFDC2626),
          Icons.cancel_outlined,
          'Rechazado',
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
}

import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';

/// Metadata visual localizada para estados, categorías y disputas del CRM.
class CrmBadgeMeta {
  const CrmBadgeMeta({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final IconData? icon;
}

const CrmBadgeMeta _neutralFallbackMeta = CrmBadgeMeta(
  label: 'Sin estado',
  backgroundColor: TuLojitaBrandColors.canvas,
  foregroundColor: TuLojitaBrandColors.inkSecondary,
  borderColor: TuLojitaBrandColors.borderMuted,
);

String _normalizeCode(String raw) => raw.trim().toUpperCase().replaceAll(' ', '_');

String _humanizeUnknownStatus(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'Sin estado';
  final words = trimmed
      .toLowerCase()
      .split(RegExp(r'[_\s-]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .toList();
  return words.isEmpty ? 'Sin estado' : words.join(' ');
}

CrmBadgeMeta _successBadge(String label, [IconData? icon]) => CrmBadgeMeta(
      label: label,
      backgroundColor: TuLojitaBrandColors.positiveBg,
      foregroundColor: TuLojitaBrandColors.positive,
      borderColor: const Color(0xFFBBEAD2),
      icon: icon,
    );

CrmBadgeMeta _warningBadge(String label, [IconData? icon]) => CrmBadgeMeta(
      label: label,
      backgroundColor: TuLojitaBrandColors.amber50,
      foregroundColor: TuLojitaBrandColors.amber800,
      borderColor: TuLojitaBrandColors.amber100,
      icon: icon,
    );

CrmBadgeMeta _dangerBadge(String label, [IconData? icon]) => CrmBadgeMeta(
      label: label,
      backgroundColor: TuLojitaBrandColors.dangerBg,
      foregroundColor: TuLojitaBrandColors.danger,
      borderColor: const Color(0xFFF3C6CA),
      icon: icon,
    );

CrmBadgeMeta _infoBadge(String label, [IconData? icon]) => CrmBadgeMeta(
      label: label,
      backgroundColor: TuLojitaBrandColors.indigo50,
      foregroundColor: TuLojitaBrandColors.indigo700,
      borderColor: TuLojitaBrandColors.indigo100,
      icon: icon,
    );

CrmBadgeMeta _neutralBadge(String label, [IconData? icon]) => CrmBadgeMeta(
      label: label,
      backgroundColor: TuLojitaBrandColors.canvas,
      foregroundColor: TuLojitaBrandColors.inkSecondary,
      borderColor: TuLojitaBrandColors.borderMuted,
      icon: icon,
    );

/// Traduce un estado de pedido (y opcionalmente pre-orden) a una etiqueta legible en español.
CrmBadgeMeta crmOrderStatusMeta(String status, {String? preOrderStatus}) {
  final code = _normalizeCode(status);
  if (code.isEmpty) {
    final normalizedPreOrder = preOrderStatus != null
        ? _normalizeCode(preOrderStatus)
        : '';
    if (normalizedPreOrder.isNotEmpty && normalizedPreOrder != 'NONE') {
      return crmPreOrderStatusMeta(preOrderStatus!);
    }
    return _neutralFallbackMeta;
  }

  switch (code) {
    case 'PENDING':
    case 'PENDING_PAYMENT':
      return _warningBadge('Pendiente de pago', Icons.schedule_rounded);
    case 'PAYMENT_SUBMITTED':
      return _infoBadge('Pago reportado', Icons.receipt_long_rounded);
    case 'PARTIALLY_PAID':
      return _warningBadge('Abono parcial', Icons.pie_chart_outline_rounded);
    case 'FULLY_PAID':
      return _successBadge('Pagado completo', Icons.check_circle_outline_rounded);
    case 'CONFIRMED':
      return _infoBadge('Confirmado', Icons.verified_outlined);
    case 'IN_PREPARATION':
    case 'PREPARING':
      return _infoBadge('En preparación', Icons.inventory_2_outlined);
    case 'READY_FOR_PICKUP':
      return _infoBadge('Listo para retiro', Icons.store_mall_directory_outlined);
    case 'SHIPPED':
    case 'IN_TRANSIT':
      return _infoBadge('En camino', Icons.local_shipping_outlined);
    case 'DELIVERED':
      return _successBadge('Entregado', Icons.done_all_rounded);
    case 'COMPLETED':
      return _successBadge('Completado', Icons.check_circle_rounded);
    case 'CANCELLED':
      return _dangerBadge('Cancelado', Icons.cancel_outlined);
    case 'REJECTED':
      return _dangerBadge('Pago rechazado', Icons.error_outline_rounded);
    case 'REFUNDED':
      return _neutralBadge('Reembolsado', Icons.undo_rounded);
    default:
      return _neutralBadge(_humanizeUnknownStatus(status));
  }
}

/// Traduce un estado específico de pre-orden / reserva por lote.
CrmBadgeMeta crmPreOrderStatusMeta(String preOrderStatus) {
  final code = _normalizeCode(preOrderStatus);
  switch (code) {
    case 'NONE':
      return _neutralBadge('Sin pre-orden');
    case 'AWAITING_STOCK':
    case 'WAITING_BATCH':
    case 'PENDING_BATCH':
      return _warningBadge('Esperando stock', Icons.hourglass_top_rounded);
    case 'STOCK_ARRIVED':
      return _infoBadge('Stock disponible', Icons.inventory_2_outlined);
    case 'READY_FOR_SETTLEMENT':
      return _infoBadge('Listo para liquidar', Icons.receipt_long_rounded);
    case 'BATCH_CONFIRMED':
    case 'CONFIRMED':
      return _infoBadge('Lote confirmado', Icons.inventory_outlined);
    case 'IN_TRANSIT':
      return _infoBadge('Pre-orden en tránsito', Icons.local_shipping_outlined);
    case 'READY_FOR_DELIVERY':
    case 'ARRIVED':
      return _successBadge('Lote listo para entrega', Icons.done_all_rounded);
    case 'FULFILLED':
    case 'COMPLETED':
      return _successBadge('Completado', Icons.check_circle_rounded);
    case 'CANCELLED':
      return _dangerBadge('Pre-orden cancelada', Icons.cancel_outlined);
    default:
      return _neutralBadge(_humanizeUnknownStatus(preOrderStatus));
  }
}

/// Traduce el estado de una cuota de pago por partes.
CrmBadgeMeta crmInstallmentStatusMeta(String status) {
  final code = _normalizeCode(status);
  switch (code) {
    case 'PAID':
    case 'VERIFIED':
    case 'COMPLETED':
      return _successBadge('Pagada', Icons.check_circle_rounded);
    case 'SUBMITTED':
    case 'PAYMENT_SUBMITTED':
    case 'IN_REVIEW':
      return _infoBadge('En revisión', Icons.receipt_long_rounded);
    case 'PENDING':
      return _warningBadge('Pendiente', Icons.schedule_rounded);
    case 'OVERDUE':
      return _dangerBadge('Vencida', Icons.warning_amber_rounded);
    case 'REJECTED':
      return _dangerBadge('Rechazada', Icons.error_outline_rounded);
    case 'CANCELLED':
      return _neutralBadge('Cancelada', Icons.cancel_outlined);
    default:
      return _neutralBadge(_humanizeUnknownStatus(status));
  }
}

/// Resume el avance de cuotas de un pedido (ej. "2/3 cuotas pagadas").
String? formatOrderInstallmentsSummary(List<Map<String, dynamic>> installments) {
  if (installments.isEmpty) return null;
  var paidCount = 0;
  var overdueCount = 0;
  var inReviewCount = 0;
  for (final item in installments) {
    final code = _normalizeCode(item['status']?.toString() ?? '');
    if (code == 'PAID' || code == 'VERIFIED' || code == 'COMPLETED') {
      paidCount++;
    } else if (code == 'OVERDUE') {
      overdueCount++;
    } else if (code == 'SUBMITTED' ||
        code == 'PAYMENT_SUBMITTED' ||
        code == 'IN_REVIEW') {
      inReviewCount++;
    }
  }
  final total = installments.length;
  if (overdueCount > 0) {
    return '$paidCount/$total cuotas pagadas ($overdueCount vencida${overdueCount == 1 ? '' : 's'})';
  }
  if (inReviewCount > 0) {
    return '$paidCount/$total cuotas pagadas ($inReviewCount por verificar)';
  }
  return '$paidCount/$total cuotas pagadas';
}

/// Traduce el estado de una reserva o cita.
CrmBadgeMeta crmSlotBookingStatusMeta(String status) {
  final code = _normalizeCode(status);
  switch (code) {
    case 'HOLD':
      return _warningBadge('En espera', Icons.schedule_rounded);
    case 'PENDING':
      return _warningBadge('Pendiente', Icons.schedule_rounded);
    case 'CONFIRMED':
      return _infoBadge('Confirmada', Icons.event_available_rounded);
    case 'COMPLETED':
      return _successBadge('Completada', Icons.check_circle_rounded);
    case 'ATTENDED':
      return _successBadge('Asistió', Icons.check_circle_rounded);
    case 'NO_SHOW':
      return _dangerBadge('No asistió', Icons.person_off_outlined);
    case 'CANCELLED':
      return _neutralBadge('Cancelada', Icons.cancel_outlined);
    case 'EXPIRED':
      return _neutralBadge('Expirada', Icons.history_rounded);
    default:
      return _neutralBadge(_humanizeUnknownStatus(status));
  }
}

/// Traduce el estado de una oferta especial CRM.
CrmBadgeMeta crmOfferStatusMeta(String status) {
  final code = _normalizeCode(status);
  switch (code) {
    case 'ACTIVE':
      return _warningBadge('Activa', Icons.local_offer_outlined);
    case 'REDEEMED':
      return _successBadge('Canjeada', Icons.check_circle_rounded);
    case 'PENDING':
      return _warningBadge('Pendiente de ver', Icons.hourglass_bottom_rounded);
    case 'VIEWED':
      return _infoBadge('Vista por cliente', Icons.visibility_outlined);
    case 'ACCEPTED':
    case 'CONVERTED':
      return _successBadge('Aprovechada', Icons.shopping_bag_outlined);
    case 'EXPIRED':
      return _neutralBadge('Expirada', Icons.timer_off_outlined);
    case 'CANCELLED':
      return _dangerBadge('Cancelada', Icons.cancel_outlined);
    case 'REJECTED':
      return _dangerBadge('Rechazada', Icons.close_rounded);
    default:
      return _neutralBadge(_humanizeUnknownStatus(status));
  }
}

/// Traduce el tipo de incidencia/disputa reportada en un cliente.
String crmDisputeTypeLabel(String type) {
  final code = _normalizeCode(type);
  switch (code) {
    case 'NO_SHOW':
      return 'Inasistencia a cita o retiro';
    case 'REFUND':
    case 'REFUND_REQUEST':
      return 'Solicitud de reembolso';
    case 'NOT_DELIVERED':
    case 'ITEM_NOT_RECEIVED':
      return 'No entregado';
    case 'DAMAGED_ITEM':
      return 'Producto dañado';
    case 'WRONG_ITEM':
      return 'Producto equivocado';
    case 'PAYMENT_ISSUE':
      return 'Incidencia de pago';
    case 'QUALITY_ISSUE':
      return 'Reclamo de calidad';
    case 'DELIVERY_ISSUE':
      return 'Problema de entrega';
    case 'FRAUD':
      return 'Riesgo de fraude';
    case 'OTHER':
      return 'Otra incidencia';
    default:
      return _humanizeUnknownStatus(type);
  }
}

/// Traduce el estado de resolución de una disputa CRM.
CrmBadgeMeta crmDisputeStatusMeta(String status) {
  final code = _normalizeCode(status);
  switch (code) {
    case 'OPEN':
      return _dangerBadge('Abierta', Icons.report_problem_outlined);
    case 'MERCHANT_RESPONDED':
      return _infoBadge('Comercio respondió', Icons.reply_rounded);
    case 'ADMIN_REVIEW':
      return _warningBadge(
        'En revisión admin',
        Icons.admin_panel_settings_outlined,
      );
    case 'IN_REVIEW':
    case 'UNDER_REVIEW':
      return _warningBadge('En revisión', Icons.manage_search_rounded);
    case 'RESOLVED':
      return _successBadge('Resuelta', Icons.check_circle_outline_rounded);
    case 'REFUNDED':
      return _successBadge('Reembolsada', Icons.currency_exchange_rounded);
    case 'REJECTED':
      return _dangerBadge('Rechazada', Icons.cancel_outlined);
    case 'DISMISSED':
    case 'CLOSED':
      return _neutralBadge('Cerrada', Icons.archive_outlined);
    default:
      return _neutralBadge(_humanizeUnknownStatus(status));
  }
}

/// Traduce las categorías internas de notas de bitácora.
CrmBadgeMeta crmNoteCategoryMeta(String category) {
  final code = _normalizeCode(category);
  switch (code) {
    case 'GENERAL':
      return _neutralBadge('General', Icons.notes_rounded);
    case 'FOLLOW_UP':
      return _infoBadge('Seguimiento', Icons.event_repeat_rounded);
    case 'PAYMENT':
      return _warningBadge('Cobranza', Icons.payments_outlined);
    case 'VIP':
      return _infoBadge('Atención VIP', Icons.workspace_premium_outlined);
    case 'ALERT':
      return _dangerBadge('Alerta', Icons.warning_amber_rounded);
    default:
      return _neutralBadge(_humanizeUnknownStatus(category));
  }
}

/// Widget compacto y consistente para renderizar badges de estado CRM localizados.
class CrmStatusBadge extends StatelessWidget {
  const CrmStatusBadge({
    super.key,
    required this.meta,
    this.compact = false,
  });

  final CrmBadgeMeta meta;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: meta.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: meta.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (meta.icon != null) ...[
            Icon(meta.icon, size: compact ? 12 : 13, color: meta.foregroundColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              meta.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 10.5 : 11,
                fontWeight: FontWeight.w700,
                color: meta.foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

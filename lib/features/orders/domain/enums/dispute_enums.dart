import 'package:flutter/material.dart';

enum DisputeType {
  itemNotReceived('ITEM_NOT_RECEIVED', 'No recibió el pedido'),
  damagedItem('DAMAGED_ITEM', 'Producto dañado o roto'),
  wrongItem('WRONG_ITEM', 'Producto equivocado o incompleto'),
  refundRequest('REFUND_REQUEST', 'Solicitud de reembolso'),
  other('OTHER', 'Otro reclamo');

  final String value;
  final String label;
  const DisputeType(this.value, this.label);

  factory DisputeType.fromString(String? val) {
    if (val == null) return DisputeType.other;
    return DisputeType.values.firstWhere(
      (e) => e.value == val.toUpperCase(),
      orElse: () => DisputeType.other,
    );
  }
}

enum DisputeStatus {
  open('OPEN', 'Pendiente de tu respuesta', Color(0xFFF59E0B), Color(0xFFFEF3C7)),
  merchantResponded('MERCHANT_RESPONDED', 'Respuesta enviada', Color(0xFF3B82F6), Color(0xFFEFF6FF)),
  adminReview('ADMIN_REVIEW', 'En mediación por Tu Lojita', Color(0xFF8B5CF6), Color(0xFFF5F3FF)),
  resolved('RESOLVED', 'Resuelto', Color(0xFF10B981), Color(0xFFECFDF5)),
  refunded('REFUNDED', 'Reembolsado', Color(0xFF059669), Color(0xFFD1FAE5)),
  rejected('REJECTED', 'Desestimado', Color(0xFFEF4444), Color(0xFFFEF2F2));

  final String value;
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const DisputeStatus(this.value, this.label, this.textColor, this.backgroundColor);

  bool get isActive =>
      this == DisputeStatus.open ||
      this == DisputeStatus.merchantResponded ||
      this == DisputeStatus.adminReview;

  bool get requiresMerchantAction => this == DisputeStatus.open;

  factory DisputeStatus.fromString(String? val) {
    if (val == null) return DisputeStatus.open;
    return DisputeStatus.values.firstWhere(
      (e) => e.value == val.toUpperCase(),
      orElse: () => DisputeStatus.open,
    );
  }
}

enum DisputeResolution {
  refund('REFUND', 'Reembolso otorgado al cliente'),
  rejected('REJECTED', 'Reclamo desestimado'),
  resolved('RESOLVED', 'Acuerdo alcanzado');

  final String value;
  final String label;
  const DisputeResolution(this.value, this.label);

  factory DisputeResolution.fromString(String? val) {
    if (val == null) return DisputeResolution.resolved;
    return DisputeResolution.values.firstWhere(
      (e) => e.value == val.toUpperCase(),
      orElse: () => DisputeResolution.resolved,
    );
  }
}

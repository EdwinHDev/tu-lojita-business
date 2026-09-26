import '../enums/dispute_enums.dart';

class OrderDispute {
  final String id;
  final String orderId;
  final String userId;
  final DisputeType type;
  final DisputeStatus status;
  final String reason;
  final List<String> evidenceUrls;
  final String? merchantResponse;
  final List<String> merchantEvidenceUrls;
  final DateTime? merchantRespondedAt;
  final String? resolvedById;
  final DisputeResolution? resolution;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos de votación bilateral
  final bool merchantMarkedResolved;
  final bool clientMarkedResolved;
  final DateTime? merchantMarkedResolvedAt;
  final DateTime? clientMarkedResolvedAt;

  const OrderDispute({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.type,
    required this.status,
    required this.reason,
    this.evidenceUrls = const [],
    this.merchantResponse,
    this.merchantEvidenceUrls = const [],
    this.merchantRespondedAt,
    this.resolvedById,
    this.resolution,
    this.resolutionNotes,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.merchantMarkedResolved = false,
    this.clientMarkedResolved = false,
    this.merchantMarkedResolvedAt,
    this.clientMarkedResolvedAt,
  });

  bool get isOpen => status == DisputeStatus.open;
  bool get hasMerchantResponse => merchantResponse != null && merchantResponse!.isNotEmpty;
  bool get isResolved =>
      status == DisputeStatus.resolved ||
      status == DisputeStatus.refunded ||
      status == DisputeStatus.rejected;

  /// La tienda puede marcar como resuelto si ya respondió y aún no votó
  bool get merchantCanMarkResolved =>
      status == DisputeStatus.merchantResponded && !merchantMarkedResolved;

  /// Cualquiera puede escalar mientras no esté ya en revisión de soporte o concluido
  bool get canEscalate =>
      status == DisputeStatus.open || status == DisputeStatus.merchantResponded;
}

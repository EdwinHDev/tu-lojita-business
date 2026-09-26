import '../../domain/entities/order_dispute.dart';
import '../../domain/enums/dispute_enums.dart';

class OrderDisputeModel extends OrderDispute {
  const OrderDisputeModel({
    required super.id,
    required super.orderId,
    required super.userId,
    required super.type,
    required super.status,
    required super.reason,
    super.evidenceUrls,
    super.merchantResponse,
    super.merchantEvidenceUrls,
    super.merchantRespondedAt,
    super.resolvedById,
    super.resolution,
    super.resolutionNotes,
    super.resolvedAt,
    required super.createdAt,
    required super.updatedAt,
    super.merchantMarkedResolved,
    super.clientMarkedResolved,
    super.merchantMarkedResolvedAt,
    super.clientMarkedResolvedAt,
  });

  factory OrderDisputeModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return [];
    }

    DateTime parseDate(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw.toString());
    }

    return OrderDisputeModel(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['requestedById']?.toString() ?? '',
      type: DisputeType.fromString(json['type']?.toString()),
      status: DisputeStatus.fromString(json['status']?.toString()),
      reason: json['reason']?.toString() ?? json['description']?.toString() ?? '',
      evidenceUrls: parseStringList(json['evidenceUrls']),
      merchantResponse: json['merchantResponse']?.toString() ?? json['response']?.toString(),
      merchantEvidenceUrls: parseStringList(json['merchantEvidenceUrls']),
      merchantRespondedAt: parseNullableDate(json['merchantRespondedAt']),
      resolvedById: json['resolvedById']?.toString(),
      resolution: json['resolution'] != null
          ? DisputeResolution.fromString(json['resolution']?.toString())
          : null,
      resolutionNotes: json['resolutionNotes']?.toString() ?? json['adminNote']?.toString(),
      resolvedAt: parseNullableDate(json['resolvedAt']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      merchantMarkedResolved: json['merchantMarkedResolved'] == true,
      clientMarkedResolved: json['clientMarkedResolved'] == true,
      merchantMarkedResolvedAt: parseNullableDate(json['merchantMarkedResolvedAt']),
      clientMarkedResolvedAt: parseNullableDate(json['clientMarkedResolvedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'type': type.value,
      'status': status.value,
      'reason': reason,
      'evidenceUrls': evidenceUrls,
      'merchantResponse': merchantResponse,
      'merchantEvidenceUrls': merchantEvidenceUrls,
      'merchantRespondedAt': merchantRespondedAt?.toIso8601String(),
      'resolvedById': resolvedById,
      'resolution': resolution?.value,
      'resolutionNotes': resolutionNotes,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'merchantMarkedResolved': merchantMarkedResolved,
      'clientMarkedResolved': clientMarkedResolved,
      'merchantMarkedResolvedAt': merchantMarkedResolvedAt?.toIso8601String(),
      'clientMarkedResolvedAt': clientMarkedResolvedAt?.toIso8601String(),
    };
  }
}

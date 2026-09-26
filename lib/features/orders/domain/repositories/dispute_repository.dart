import 'dart:io';
import '../entities/order_dispute.dart';

abstract class DisputeRepository {
  Future<OrderDispute> respondDispute({
    required String disputeId,
    required String response,
    List<File> evidenceFiles = const [],
    bool acceptDispute = false,
  });

  Future<List<OrderDispute>> getDisputesByOrder(String orderId);

  Future<OrderDispute> markResolved(String disputeId);

  Future<OrderDispute> escalate(String disputeId);
}

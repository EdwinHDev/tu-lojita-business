import 'dart:io';
import '../../domain/entities/order_dispute.dart';
import '../../domain/repositories/dispute_repository.dart';
import '../datasources/dispute_remote_data_source.dart';
import 'package:tu_lojita_business/features/company_onboarding/data/datasources/image_remote_data_source.dart';

class DisputeRepositoryImpl implements DisputeRepository {
  final DisputeRemoteDataSource _disputeRemoteDataSource;
  final ImageRemoteDataSource _imageRemoteDataSource;

  DisputeRepositoryImpl({
    required DisputeRemoteDataSource disputeRemoteDataSource,
    required ImageRemoteDataSource imageRemoteDataSource,
  })  : _disputeRemoteDataSource = disputeRemoteDataSource,
        _imageRemoteDataSource = imageRemoteDataSource;

  @override
  Future<OrderDispute> respondDispute({
    required String disputeId,
    required String response,
    List<File> evidenceFiles = const [],
    bool acceptDispute = false,
  }) async {
    final List<String> evidenceUrls = [];

    for (final file in evidenceFiles) {
      final url = await _imageRemoteDataSource.uploadImage(file);
      if (url.isNotEmpty) {
        evidenceUrls.add(url);
      }
    }

    return await _disputeRemoteDataSource.respondDispute(
      disputeId: disputeId,
      response: response,
      evidenceUrls: evidenceUrls,
      acceptDispute: acceptDispute,
    );
  }

  @override
  Future<List<OrderDispute>> getDisputesByOrder(String orderId) async {
    final models = await _disputeRemoteDataSource.getDisputesByOrder(orderId);
    return List<OrderDispute>.from(models);
  }

  @override
  Future<OrderDispute> markResolved(String disputeId) async {
    return await _disputeRemoteDataSource.markResolved(disputeId);
  }

  @override
  Future<OrderDispute> escalate(String disputeId) async {
    return await _disputeRemoteDataSource.escalate(disputeId);
  }
}

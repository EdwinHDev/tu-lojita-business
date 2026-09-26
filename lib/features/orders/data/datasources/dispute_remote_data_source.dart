import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/order_dispute_model.dart';

class DisputeRemoteDataSource {
  final Dio _dio;

  DisputeRemoteDataSource(this._dio);

  Future<OrderDisputeModel> respondDispute({
    required String disputeId,
    required String response,
    List<String> evidenceUrls = const [],
    bool acceptDispute = false,
  }) async {
    try {
      final res = await _dio.patch(
        '/order-dispute/$disputeId/respond',
        data: {
          'merchantResponse': response,
          'response': response,
          'evidenceUrls': evidenceUrls,
          'acceptDispute': acceptDispute,
        },
      );
      return OrderDisputeModel.fromJson(res.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is List) {
        throw ServerException(msg.join(', '));
      }
      throw ServerException(msg ?? e.message ?? 'Error al responder al reclamo');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<OrderDisputeModel>> getDisputesByOrder(String orderId) async {
    try {
      final res = await _dio.get('/order-dispute/order/$orderId');
      if (res.data is List) {
        return (res.data as List)
            .map((item) => OrderDisputeModel.fromJson(item))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      throw ServerException(msg ?? e.message ?? 'Error al obtener reclamos de la orden');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<OrderDisputeModel> markResolved(String disputeId) async {
    try {
      final res = await _dio.patch('/order-dispute/$disputeId/mark-resolved');
      return OrderDisputeModel.fromJson(res.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is List) throw ServerException(msg.join(', '));
      throw ServerException(msg ?? e.message ?? 'Error al marcar el reclamo como resuelto');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<OrderDisputeModel> escalate(String disputeId) async {
    try {
      final res = await _dio.patch('/order-dispute/$disputeId/escalate');
      return OrderDisputeModel.fromJson(res.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is List) throw ServerException(msg.join(', '));
      throw ServerException(msg ?? e.message ?? 'Error al escalar el reclamo');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

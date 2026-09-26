import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/order_review_model.dart';
import '../../domain/models/buyer_review_model.dart';

class ReviewRemoteDataSource {
  final Dio _dio;

  ReviewRemoteDataSource(this._dio);

  Future<BuyerReviewModel> createBuyerReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    try {
      final res = await _dio.post(
        '/reviews/buyer/$orderId',
        data: {
          'rating': rating,
          if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
        },
      );
      return BuyerReviewModel.fromJson(res.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is List) throw ServerException(msg.join(', '));
      throw ServerException(msg ?? e.message ?? 'Error al calificar al comprador');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<BuyerReviewModel> updateBuyerReview({
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (rating != null) data['rating'] = rating;
      if (comment != null) data['comment'] = comment.trim();

      final res = await _dio.patch(
        '/reviews/buyer/$reviewId',
        data: data,
      );
      return BuyerReviewModel.fromJson(res.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is List) throw ServerException(msg.join(', '));
      throw ServerException(msg ?? e.message ?? 'Error al actualizar la calificación');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<OrderReviewModel> addVendorReply({
    required String reviewId,
    required String reply,
  }) async {
    try {
      final res = await _dio.post(
        '/reviews/order/$reviewId/reply',
        data: {'reply': reply.trim()},
      );
      return OrderReviewModel.fromJson(res.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is List) throw ServerException(msg.join(', '));
      throw ServerException(msg ?? e.message ?? 'Error al responder a la reseña');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<OrderReviewModel?> getOrderReviewByOrder(String orderId) async {
    try {
      final res = await _dio.get('/reviews/order/by-order/$orderId');
      if (res.data == null || res.data == '') return null;
      return OrderReviewModel.fromJson(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      final msg = e.response?.data?['message'];
      throw ServerException(msg ?? e.message ?? 'Error al obtener la reseña');
    } catch (e) {
      return null;
    }
  }

  Future<BuyerReviewModel?> getBuyerReviewByOrder(String orderId) async {
    try {
      final res = await _dio.get('/reviews/buyer/by-order/$orderId');
      if (res.data == null || res.data == '') return null;
      return BuyerReviewModel.fromJson(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      final msg = e.response?.data?['message'];
      throw ServerException(msg ?? e.message ?? 'Error al obtener calificación del comprador');
    } catch (e) {
      return null;
    }
  }

  Future<List<OrderReviewModel>> getItemReviews(
    String itemId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final res = await _dio.get(
        '/reviews/order/item/$itemId',
        queryParameters: {'page': page, 'limit': limit},
      );
      final rawItems = res.data['items'] as List? ?? [];
      return rawItems
          .map((item) => OrderReviewModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      throw ServerException(msg ?? e.message ?? 'Error al obtener reseñas');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

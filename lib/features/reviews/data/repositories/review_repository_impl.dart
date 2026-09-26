import '../../domain/models/order_review_model.dart';
import '../../domain/models/buyer_review_model.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_data_source.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource _dataSource;

  ReviewRepositoryImpl(this._dataSource);

  @override
  Future<BuyerReviewModel> createBuyerReview({
    required String orderId,
    required int rating,
    String? comment,
  }) {
    return _dataSource.createBuyerReview(
      orderId: orderId,
      rating: rating,
      comment: comment,
    );
  }

  @override
  Future<BuyerReviewModel> updateBuyerReview({
    required String reviewId,
    int? rating,
    String? comment,
  }) {
    return _dataSource.updateBuyerReview(
      reviewId: reviewId,
      rating: rating,
      comment: comment,
    );
  }

  @override
  Future<OrderReviewModel> addVendorReply({
    required String reviewId,
    required String reply,
  }) {
    return _dataSource.addVendorReply(
      reviewId: reviewId,
      reply: reply,
    );
  }

  @override
  Future<OrderReviewModel?> getOrderReviewByOrder(String orderId) {
    return _dataSource.getOrderReviewByOrder(orderId);
  }

  @override
  Future<BuyerReviewModel?> getBuyerReviewByOrder(String orderId) {
    return _dataSource.getBuyerReviewByOrder(orderId);
  }

  @override
  Future<List<OrderReviewModel>> getItemReviews(
    String itemId, {
    int page = 1,
    int limit = 10,
  }) {
    return _dataSource.getItemReviews(itemId, page: page, limit: limit);
  }
}

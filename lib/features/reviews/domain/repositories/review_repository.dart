import '../../domain/models/order_review_model.dart';
import '../../domain/models/buyer_review_model.dart';

abstract class ReviewRepository {
  Future<BuyerReviewModel> createBuyerReview({
    required String orderId,
    required int rating,
    String? comment,
  });

  Future<BuyerReviewModel> updateBuyerReview({
    required String reviewId,
    int? rating,
    String? comment,
  });

  Future<OrderReviewModel> addVendorReply({
    required String reviewId,
    required String reply,
  });

  Future<OrderReviewModel?> getOrderReviewByOrder(String orderId);

  Future<BuyerReviewModel?> getBuyerReviewByOrder(String orderId);

  Future<List<OrderReviewModel>> getItemReviews(
    String itemId, {
    int page = 1,
    int limit = 10,
  });
}

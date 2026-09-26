import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import '../../domain/models/order_review_model.dart';
import '../../domain/models/buyer_review_model.dart';
import '../../domain/repositories/review_repository.dart';
import '../../data/datasources/review_remote_data_source.dart';
import '../../data/repositories/review_repository_impl.dart';

// --- Data Source & Repository ---
final reviewRemoteDataSourceProvider = Provider<ReviewRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ReviewRemoteDataSource(dio);
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final ds = ref.watch(reviewRemoteDataSourceProvider);
  return ReviewRepositoryImpl(ds);
});

// --- Queries ---
final orderReviewByOrderProvider =
    FutureProvider.family.autoDispose<OrderReviewModel?, String>(
  (ref, orderId) async {
    final repo = ref.watch(reviewRepositoryProvider);
    return await repo.getOrderReviewByOrder(orderId);
  },
);

final buyerReviewByOrderProvider =
    FutureProvider.family.autoDispose<BuyerReviewModel?, String>(
  (ref, orderId) async {
    final repo = ref.watch(reviewRepositoryProvider);
    return await repo.getBuyerReviewByOrder(orderId);
  },
);

// --- Action State & Notifier ---
class ReviewActionState {
  final bool isLoading;
  final String? error;

  const ReviewActionState({
    this.isLoading = false,
    this.error,
  });

  ReviewActionState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ReviewActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReviewActionNotifier extends Notifier<ReviewActionState> {
  @override
  ReviewActionState build() {
    return const ReviewActionState();
  }

  Future<bool> createBuyerReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.createBuyerReview(
        orderId: orderId,
        rating: rating,
        comment: comment,
      );
      state = const ReviewActionState(isLoading: false);
      ref.invalidate(buyerReviewByOrderProvider(orderId));
      return true;
    } catch (e) {
      state = ReviewActionState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateBuyerReview({
    required String orderId,
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.updateBuyerReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );
      state = const ReviewActionState(isLoading: false);
      ref.invalidate(buyerReviewByOrderProvider(orderId));
      return true;
    } catch (e) {
      state = ReviewActionState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', ''),
      );
      return false;
    }
  }

  Future<bool> addVendorReply({
    required String orderId,
    required String reviewId,
    required String reply,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.addVendorReply(
        reviewId: reviewId,
        reply: reply,
      );
      state = const ReviewActionState(isLoading: false);
      ref.invalidate(orderReviewByOrderProvider(orderId));
      return true;
    } catch (e) {
      state = ReviewActionState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', ''),
      );
      return false;
    }
  }
}

final reviewActionNotifierProvider =
    NotifierProvider<ReviewActionNotifier, ReviewActionState>(
  ReviewActionNotifier.new,
);

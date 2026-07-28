import '../../technicians/domain/review.dart';

abstract class ReviewsRepository {
  /// Submit a new review for a completed service request
  Future<Review> createReview({
    required String requestId,
    required double rating,
    String? comment,
  });
}

import '../../../../core/network/error_mapper.dart';
import '../../technicians/domain/review.dart';
import '../domain/reviews_repository.dart';
import 'reviews_remote_data_source.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsRemoteDataSource _remoteDataSource;

  ReviewsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Review> createReview({
    required String requestId,
    required double rating,
    String? comment,
  }) async {
    try {
      final res = await _remoteDataSource.createReview(
        requestId: requestId,
        rating: rating,
        comment: comment,
      );
      return Review.fromJson(res);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }
}

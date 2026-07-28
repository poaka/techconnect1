import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/auth_provider.dart';
import '../../data/reviews_remote_data_source.dart';
import '../../data/reviews_repository_impl.dart';
import '../../domain/reviews_repository.dart';
import '../../../technicians/domain/review.dart';

final reviewsRemoteDataSourceProvider = Provider<ReviewsRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ReviewsRemoteDataSource(dioClient.dio);
});

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  final remoteDataSource = ref.watch(reviewsRemoteDataSourceProvider);
  return ReviewsRepositoryImpl(remoteDataSource);
});

class SubmitReviewNotifier extends StateNotifier<AsyncValue<Review?>> {
  final ReviewsRepository _repository;

  SubmitReviewNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> submit({
    required String requestId,
    required double rating,
    String? comment,
  }) async {
    state = const AsyncValue.loading();
    try {
      final review = await _repository.createReview(
        requestId: requestId,
        rating: rating,
        comment: comment,
      );
      state = AsyncValue.data(review);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final submitReviewProvider = StateNotifierProvider<SubmitReviewNotifier, AsyncValue<Review?>>((ref) {
  final repository = ref.watch(reviewsRepositoryProvider);
  return SubmitReviewNotifier(repository);
});

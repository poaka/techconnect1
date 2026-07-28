import 'package:dio/dio.dart';

class ReviewsRemoteDataSource {
  final Dio dio;

  ReviewsRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> createReview({
    required String requestId,
    required double rating,
    String? comment,
  }) async {
    final response = await dio.post('/reviews', data: {
      'requestId': requestId,
      'rating': rating.toInt(),
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
    return response.data['data'] as Map<String, dynamic>;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_provider.dart';

class TechnicianStats {
  final int pendingRequestsCount;
  final int acceptedRequestsCount;
  final int inProgressRequestsCount;
  final int completedJobsCount;
  final int totalRequestsCount;
  final double ratingAvg;
  final int ratingCount;
  final String availability;
  final bool verified;

  const TechnicianStats({
    this.pendingRequestsCount = 0,
    this.acceptedRequestsCount = 0,
    this.inProgressRequestsCount = 0,
    this.completedJobsCount = 0,
    this.totalRequestsCount = 0,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.availability = 'offline',
    this.verified = false,
  });

  factory TechnicianStats.fromJson(Map<String, dynamic> json) {
    return TechnicianStats(
      pendingRequestsCount: (json['pendingRequestsCount'] as num?)?.toInt() ?? 0,
      acceptedRequestsCount: (json['acceptedRequestsCount'] as num?)?.toInt() ?? 0,
      inProgressRequestsCount: (json['inProgressRequestsCount'] as num?)?.toInt() ?? 0,
      completedJobsCount: (json['completedJobsCount'] as num?)?.toInt() ?? 0,
      totalRequestsCount: (json['totalRequestsCount'] as num?)?.toInt() ?? 0,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      availability: json['availability']?.toString() ?? 'offline',
      verified: json['verified'] == true,
    );
  }
}

final technicianStatsProvider =
    FutureProvider.autoDispose<TechnicianStats>((ref) async {
  final dioClient = ref.watch(dioClientProvider);
  try {
    final response = await dioClient.get('/technicians/me/stats');
    final data = response.data['data'] as Map<String, dynamic>;
    return TechnicianStats.fromJson(data);
  } catch (_) {
    // Return empty stats on error so the UI doesn't crash
    return const TechnicianStats();
  }
});

class PlatformStats {
  final int usersCount;
  final int techniciansCount;
  final int verifiedTechniciansCount;
  final int serviceRequestsCount;
  final int completedRequestsCount;
  final int reviewsCount;
  final int pendingVerificationsCount;
  final int rejectedVerificationsCount;
  final int reportsCount;
  final int pendingReportsCount;

  PlatformStats({
    required this.usersCount,
    required this.techniciansCount,
    required this.verifiedTechniciansCount,
    required this.serviceRequestsCount,
    required this.completedRequestsCount,
    required this.reviewsCount,
    required this.pendingVerificationsCount,
    required this.rejectedVerificationsCount,
    required this.reportsCount,
    required this.pendingReportsCount,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      usersCount: json['usersCount'] ?? 0,
      techniciansCount: json['techniciansCount'] ?? 0,
      verifiedTechniciansCount: json['verifiedTechniciansCount'] ?? 0,
      serviceRequestsCount: json['serviceRequestsCount'] ?? 0,
      completedRequestsCount: json['completedRequestsCount'] ?? 0,
      reviewsCount: json['reviewsCount'] ?? 0,
      pendingVerificationsCount: json['pendingVerificationsCount'] ?? 0,
      rejectedVerificationsCount: json['rejectedVerificationsCount'] ?? 0,
      reportsCount: json['reportsCount'] ?? 0,
      pendingReportsCount: json['pendingReportsCount'] ?? 0,
    );
  }
}

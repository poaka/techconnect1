import '../../auth/domain/app_user.dart';

class Report {
  final String id;
  final String reason;
  final String? details;
  final String status;
  final String? actionTaken;
  final DateTime createdAt;
  final AppUser? client;
  final AppUser? technician;

  Report({
    required this.id,
    required this.reason,
    this.details,
    required this.status,
    this.actionTaken,
    required this.createdAt,
    this.client,
    this.technician,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      reason: json['reason'],
      details: json['details'],
      status: json['status'],
      actionTaken: json['action_taken'],
      createdAt: DateTime.parse(json['created_at']),
      client: json['client'] != null ? AppUser.fromJson(json['client']) : null,
      technician: json['technician'] != null ? AppUser.fromJson(json['technician']) : null,
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import 'service_request.dart';

enum JobOfferStatus {
  pending,
  accepted,
  rejected,
  expired;

  String getLocalizedLabel(BuildContext context) {
    switch (this) {
      case JobOfferStatus.pending:
        return 'En attente'; // Could be localized
      case JobOfferStatus.accepted:
        return 'Acceptée';
      case JobOfferStatus.rejected:
        return 'Refusée';
      case JobOfferStatus.expired:
        return 'Expirée';
    }
  }

  static JobOfferStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'accepted':
        return JobOfferStatus.accepted;
      case 'rejected':
        return JobOfferStatus.rejected;
      case 'expired':
        return JobOfferStatus.expired;
      case 'pending':
      default:
        return JobOfferStatus.pending;
    }
  }
}

class JobOffer {
  final String id;
  final String requestId;
  final String technicianId;
  final JobOfferStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final ServiceRequest? request;

  const JobOffer({
    required this.id,
    required this.requestId,
    required this.technicianId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.request,
  });

  factory JobOffer.fromJson(Map<String, dynamic> json) {
    return JobOffer(
      id: json['id']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? '',
      technicianId: json['technician_id']?.toString() ?? '',
      status: JobOfferStatus.fromString(json['status']?.toString() ?? 'pending'),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'].toString()) : DateTime.now().add(const Duration(minutes: 5)),
      request: json['request'] != null ? ServiceRequest.fromJson(json['request'] as Map<String, dynamic>) : null,
    );
  }
}

import '../../features/technicians/domain/category.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/technicians/domain/technician_profile.dart';

enum RequestStatus {
  pending,
  accepted,
  rejected,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'En attente';
      case RequestStatus.accepted:
        return 'Acceptée';
      case RequestStatus.rejected:
        return 'Refusée';
      case RequestStatus.inProgress:
        return 'En cours';
      case RequestStatus.completed:
        return 'Terminée';
      case RequestStatus.cancelled:
        return 'Annulée';
    }
  }

  static RequestStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'rejected':
        return RequestStatus.rejected;
      case 'in_progress':
        return RequestStatus.inProgress;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
        return RequestStatus.cancelled;
      case 'pending':
      default:
        return RequestStatus.pending;
    }
  }

  String toSnakeCase() {
    switch (this) {
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.accepted:
        return 'accepted';
      case RequestStatus.rejected:
        return 'rejected';
      case RequestStatus.inProgress:
        return 'in_progress';
      case RequestStatus.completed:
        return 'completed';
      case RequestStatus.cancelled:
        return 'cancelled';
    }
  }
}

class ServiceRequest {
  final String id;
  final String clientId;
  final String technicianId;
  final RequestStatus status;
  final String? description;
  final String? address;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  // Relations (can be null if not populated by API)
  final AppUser? client;
  final TechnicianProfile? technician;
  final Category? category;
  final bool hasReview;

  const ServiceRequest({
    required this.id,
    required this.clientId,
    required this.technicianId,
    required this.status,
    this.description,
    this.address,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.client,
    this.technician,
    this.category,
    this.hasReview = false,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      technicianId: json['technician_id']?.toString() ?? '',
      status: RequestStatus.fromString(json['status']?.toString() ?? 'pending'),
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'].toString()) : null,
      client: json['client'] != null ? AppUser.fromJson(json['client'] as Map<String, dynamic>) : null,
      technician: json['technician'] != null ? TechnicianProfile.fromJson(json['technician'] as Map<String, dynamic>) : null,
      // For category, since backend might return a nested obj or just id
      category: json['category'] != null ? Category.fromJson(json['category'] as Map<String, dynamic>) : null,
      hasReview: json['review'] != null && (json['review'] is List ? (json['review'] as List).isNotEmpty : true),
    );
  }
}

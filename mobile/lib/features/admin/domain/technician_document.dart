import '../../technicians/domain/technician_profile.dart';

class TechnicianDocument {
  final String id;
  final String documentType;
  final String fileUrl;
  final String status;
  final String? rejectionReason;
  final DateTime uploadedAt;
  final DateTime? reviewedAt;
  final TechnicianProfile? technician;

  TechnicianDocument({
    required this.id,
    required this.documentType,
    required this.fileUrl,
    required this.status,
    this.rejectionReason,
    required this.uploadedAt,
    this.reviewedAt,
    this.technician,
  });

  factory TechnicianDocument.fromJson(Map<String, dynamic> json) {
    return TechnicianDocument(
      id: json['id'].toString(),
      documentType: json['document_type'] ?? 'unknown',
      fileUrl: json['file_url'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      technician: json['technician'] != null
          ? TechnicianProfile.fromJson(json['technician'])
          : null,
    );
  }
}

class TechnicianDocument {
  final String id;
  final String documentType;
  final String fileUrl;
  final String status;
  final String? rejectionReason;
  final DateTime uploadedAt;

  TechnicianDocument({
    required this.id,
    required this.documentType,
    required this.fileUrl,
    required this.status,
    this.rejectionReason,
    required this.uploadedAt,
  });

  factory TechnicianDocument.fromJson(Map<String, dynamic> json) {
    return TechnicianDocument(
      id: json['id'] as String,
      documentType: json['document_type'] as String? ?? 'unknown',
      fileUrl: json['file_url'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      uploadedAt: json['uploaded_at'] != null 
          ? DateTime.parse(json['uploaded_at'] as String) 
          : DateTime.now(),
    );
  }

  String get documentTypeLabel {
    switch (documentType) {
      case 'id_card': return 'Carte d\'identité';
      case 'certificate': return 'Certificat / Diplôme';
      default: return 'Autre document';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'approved': return 'Approuvé';
      case 'rejected': return 'Rejeté';
      default: return 'En attente';
    }
  }
}

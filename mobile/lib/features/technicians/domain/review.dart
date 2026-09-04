class Review {
  final String id;
  final String requestId;
  final String clientName;
  final double rating;
  final String? comment;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.requestId,
    required this.clientName,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? json['client']?['full_name']?.toString() ?? 'Client FixerPro237',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      comment: json['comment']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

import 'category.dart';
import 'review.dart';

class TechnicianProfile {
  final String id;
  final String userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? bio;
  final String? cityId;
  final String? cityName;
  final String? regionName;
  final bool isVerified;
  final String availabilityStatus; // 'available', 'busy', 'unavailable'
  final int yearsExperience;
  final double priceMin;
  final double priceMax;
  final String? whatsapp;
  final double ratingAvg;
  final int ratingCount;
  final List<Category> categories;
  final List<Review> reviews;
  final String? avatarUrl;

  const TechnicianProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.phone,
    this.bio,
    this.cityId,
    this.cityName,
    this.regionName,
    this.isVerified = false,
    this.availabilityStatus = 'available',
    this.yearsExperience = 0,
    this.priceMin = 0.0,
    this.priceMax = 0.0,
    this.whatsapp,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.categories = const [],
    this.reviews = const [],
    this.avatarUrl,
  });

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    // Handle nested user object or root fields
    final userMap = json['user'] is Map<String, dynamic> ? json['user'] : json;
    final cityMap = json['city'] is Map<String, dynamic> ? json['city'] : null;

    final catList = (json['categories'] as List<dynamic>?)
            ?.map((c) => Category.fromJson(c is Map<String, dynamic> ? (c['category'] ?? c) : {}))
            .toList() ??
        [];
        
    if (json['category'] != null && catList.isEmpty) {
      catList.add(Category.fromJson(json['category'] as Map<String, dynamic>));
    }

    final revList = (json['reviews'] as List<dynamic>?)
            ?.map((r) => Review.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return TechnicianProfile(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? userMap['id']?.toString() ?? '',
      fullName: userMap['full_name']?.toString() ?? json['full_name']?.toString() ?? 'Technicien',
      email: userMap['email']?.toString() ?? json['email']?.toString(),
      phone: userMap['phone']?.toString() ?? json['phone']?.toString(),
      bio: json['bio']?.toString(),
      cityId: json['city_id']?.toString() ?? cityMap?['id']?.toString(),
      cityName: cityMap?['name']?.toString() ?? json['city_name']?.toString(),
      regionName: cityMap?['region']?['name']?.toString() ?? json['region_name']?.toString(),
      isVerified: json['verified'] == true || json['is_verified'] == true || json['is_verified'] == 1,
      availabilityStatus: json['availability']?.toString() ?? json['availability_status']?.toString() ?? 'available',
      yearsExperience: int.tryParse(json['years_experience']?.toString() ?? '0') ?? 0,
      priceMin: double.tryParse(json['price_min']?.toString() ?? '0') ?? 0.0,
      priceMax: double.tryParse(json['price_max']?.toString() ?? '0') ?? 0.0,
      whatsapp: json['whatsapp']?.toString(),
      ratingAvg: double.tryParse(json['rating_avg']?.toString() ?? '0') ?? 0.0,
      ratingCount: int.tryParse(json['rating_count']?.toString() ?? '0') ?? 0,
      categories: catList,
      reviews: revList,
      avatarUrl: userMap['avatar_url']?.toString() ?? json['avatar_url']?.toString(),
    );
  }

  String get availabilityLabel {
    switch (availabilityStatus.toLowerCase()) {
      case 'available':
        return 'Disponible';
      case 'busy':
        return 'Occupé';
      case 'unavailable':
      default:
        return 'Indisponible';
    }
  }
}

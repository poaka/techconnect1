class TechnicianFilter {
  final String? q;
  final String? categoryId;
  final String? regionId;
  final String? cityId;
  final String? availabilityStatus;
  final double? minRating;
  final bool? verifiedOnly;
  final int page;
  final int limit;

  const TechnicianFilter({
    this.q,
    this.categoryId,
    this.regionId,
    this.cityId,
    this.availabilityStatus,
    this.minRating,
    this.verifiedOnly,
    this.page = 1,
    this.limit = 10,
  });

  bool get hasActiveFilters =>
      (q != null && q!.isNotEmpty) ||
      categoryId != null ||
      regionId != null ||
      cityId != null ||
      availabilityStatus != null ||
      (minRating != null && minRating! > 0) ||
      verifiedOnly != null;

  int get activeFiltersCount {
    int count = 0;
    if (q != null && q!.isNotEmpty) count++;
    if (categoryId != null) count++;
    if (regionId != null) count++;
    if (cityId != null) count++;
    if (availabilityStatus != null) count++;
    if (minRating != null && minRating! > 0) count++;
    if (verifiedOnly != null) count++;
    return count;
  }

  TechnicianFilter copyWith({
    String? q,
    String? categoryId,
    String? regionId,
    String? cityId,
    String? availabilityStatus,
    double? minRating,
    bool? verifiedOnly,
    int? page,
    int? limit,
  }) {
    return TechnicianFilter(
      q: q ?? this.q,
      categoryId: categoryId ?? this.categoryId,
      regionId: regionId ?? this.regionId,
      cityId: cityId ?? this.cityId,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      minRating: minRating ?? this.minRating,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (q != null && q!.isNotEmpty) params['q'] = q;
    if (categoryId != null) params['category'] = categoryId;
    if (regionId != null) params['region'] = regionId;
    if (cityId != null) params['city'] = cityId;
    if (availabilityStatus != null) params['availability'] = availabilityStatus;
    if (minRating != null && minRating! > 0) params['minRating'] = minRating;
    if (verifiedOnly != null) params['verifiedOnly'] = verifiedOnly;
    return params;
  }
}

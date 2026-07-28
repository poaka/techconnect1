class City {
  final String id;
  final String name;
  final String? regionId;
  final String? regionName;

  const City({
    required this.id,
    required this.name,
    this.regionId,
    this.regionName,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      regionId: json['region_id']?.toString(),
      regionName: json['region_name']?.toString() ?? json['region']?['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region_id': regionId,
      'region_name': regionName,
    };
  }
}

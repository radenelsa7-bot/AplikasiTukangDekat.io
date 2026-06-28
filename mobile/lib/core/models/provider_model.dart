class ProviderService {
  final int id;
  final String name;
  final int basePrice;
  final String priceUnit;
  final bool isActive;

  ProviderService({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.priceUnit,
    required this.isActive,
  });

  factory ProviderService.fromJson(Map<String, dynamic> json) {
    return ProviderService(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      basePrice: json['base_price'] ?? 0,
      priceUnit: json['price_unit'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}

class ProviderProfile {
  final int id;
  final int? userId;
  final String businessName;
  final String? ownerName;
  final String? description;
  final String? area;
  final String? address;
  final bool isVerified;
  final double avgRating;
  final List<ProviderService> services;

  ProviderProfile({
    required this.id,
    this.userId,
    required this.businessName,
    this.ownerName,
    this.description,
    this.area,
    this.address,
    required this.isVerified,
    required this.avgRating,
    required this.services,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'];

    return ProviderProfile(
      id: json['id'] ?? 0,
      userId: json['user_id'],
      businessName: json['business_name'] ?? '',
      ownerName: user is Map<String, dynamic> ? user['name'] : null,
      description: json['description'],
      area: json['area'],
      address: json['address'],
      isVerified: json['is_verified'] ?? false,
      avgRating: double.tryParse(json['avg_rating'].toString()) ?? 0,
      services:
          (json['services'] as List?)
              ?.map((item) => ProviderService.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ProvidersResponse {
  final List<ProviderProfile> data;

  ProvidersResponse({required this.data});

  factory ProvidersResponse.fromJson(Map<String, dynamic> json) {
    return ProvidersResponse(
      data:
          (json['data'] as List?)
              ?.map((item) => ProviderProfile.fromJson(item))
              .toList() ??
          [],
    );
  }
}

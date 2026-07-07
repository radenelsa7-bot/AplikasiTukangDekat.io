class ProviderService {
  final int id;
  final int? categoryId;
  final String? categoryName;
  final String name;
  final String? description;
  final int basePrice;
  final String priceUnit;
  final bool isActive;

  ProviderService({
    required this.id,
    this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    required this.basePrice,
    required this.priceUnit,
    required this.isActive,
  });

  factory ProviderService.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return ProviderService(
      id: json['id'] ?? 0,
      categoryId: json['category_id'],
      categoryName: category is Map<String, dynamic> ? category['name']?.toString() : null,
      name: json['name'] ?? '',
      description: json['description'],
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
  final String userStatus; // User account status: ACTIVE, SUSPENDED, INACTIVE

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
    this.userStatus = 'ACTIVE',
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userStatus =
        (user is Map<String, dynamic> ? user['status'] : null) ?? 'ACTIVE';

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
      userStatus: userStatus,
    );
  }
}

class ProvidersResponse {
  final List<ProviderProfile> data;

  ProvidersResponse({required this.data});

  factory ProvidersResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List items;
    if (rawData is List) {
      items = rawData;
    } else if (rawData is Map<String, dynamic>) {
      final providers = rawData['providers'];
      if (providers is List) {
        items = providers;
      } else {
        items = [];
      }
    } else {
      items = [];
    }
    return ProvidersResponse(
      data: items
          .map(
            (item) => ProviderProfile.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

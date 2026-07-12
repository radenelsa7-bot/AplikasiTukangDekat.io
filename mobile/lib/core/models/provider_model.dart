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

class ProviderCoverage {
  final int id;
  final int kecamatanId;
  final String kecamatanName;
  final int? kotaId;
  final String? kotaName;
  final bool isActive;

  ProviderCoverage({
    required this.id,
    required this.kecamatanId,
    required this.kecamatanName,
    this.kotaId,
    this.kotaName,
    required this.isActive,
  });

  factory ProviderCoverage.fromJson(Map<String, dynamic> json) {
    final kecamatan = json['kecamatan'];
    final kota = kecamatan is Map<String, dynamic> ? kecamatan['kota'] : null;

    return ProviderCoverage(
      id: json['id'] ?? 0,
      kecamatanId: json['kecamatan_id'] ?? 0,
      kecamatanName: kecamatan is Map<String, dynamic>
          ? kecamatan['name']?.toString() ?? ''
          : '',
      kotaId: kecamatan is Map<String, dynamic>
          ? (kecamatan['kota_id'] is num ? (kecamatan['kota_id'] as num).toInt() : int.tryParse(kecamatan['kota_id']?.toString() ?? ''))
          : null,
      kotaName: kota is Map<String, dynamic> ? kota['name']?.toString() : null,
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
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final double avgRating;
  final List<ProviderService> services;
  final List<ProviderCoverage> coverages;
  final String userStatus; // User account status: ACTIVE, SUSPENDED, INACTIVE
  final String availabilityStatus;

  ProviderProfile({
    required this.id,
    this.userId,
    required this.businessName,
    this.ownerName,
    this.description,
    this.area,
    this.address,
    this.latitude,
    this.longitude,
    required this.isVerified,
    required this.avgRating,
    required this.services,
    this.coverages = const [],
    this.userStatus = 'ACTIVE',
    this.availabilityStatus = 'AVAILABLE',
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
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      isVerified: json['is_verified'] ?? false,
      avgRating: double.tryParse(json['avg_rating'].toString()) ?? 0,
      services:
          (json['services'] as List?)
              ?.map((item) => ProviderService.fromJson(item))
              .toList() ??
          [],
      coverages:
          (json['coverages'] as List?)
              ?.map((item) => ProviderCoverage.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      userStatus: userStatus,
      availabilityStatus: json['availability_status']?.toString() ?? 'AVAILABLE',
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

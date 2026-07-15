/// Model untuk data kota (wilayah_kota)
class CityData {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  CityData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CityData.fromJson(Map<String, dynamic> json) {
    return CityData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'CityData(id: $id, name: $name)';
}

/// Model untuk data kecamatan (wilayah_kecamatan)
class DistrictData {
  final int id;
  final int cityId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CityData? city; // Optional city data

  DistrictData({
    required this.id,
    required this.cityId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.city,
  });

  factory DistrictData.fromJson(Map<String, dynamic> json) {
    return DistrictData(
      id: json['id'] ?? 0,
      cityId: json['kota_id'] ?? json['city_id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      city: json['kota'] != null
          ? CityData.fromJson(json['kota'])
          : json['city'] != null
              ? CityData.fromJson(json['city'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kota_id': cityId,
      'city_id': cityId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (city != null) 'kota': city!.toJson(),
    };
  }

  @override
  String toString() => 'DistrictData(id: $id, cityId: $cityId, name: $name)';
}

/// Response wrapper untuk list cities
class CitiesResponse {
  final bool success;
  final String message;
  final List<CityData> data;

  CitiesResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CitiesResponse.fromJson(Map<String, dynamic> json) {
    List<CityData> cities = [];
    if (json['data'] is List) {
      cities = (json['data'] as List)
          .map((item) => CityData.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return CitiesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: cities,
    );
  }
}

/// Response wrapper untuk list districts
class DistrictsResponse {
  final bool success;
  final String message;
  final List<DistrictData> data;

  DistrictsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DistrictsResponse.fromJson(Map<String, dynamic> json) {
    List<DistrictData> districts = [];
    if (json['data'] is List) {
      districts = (json['data'] as List)
          .map((item) => DistrictData.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return DistrictsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: districts,
    );
  }
}

/// Provider approval status enum
enum ProviderApprovalStatus {
  pending,
  approved,
  rejected,
}

extension ProviderApprovalStatusExt on ProviderApprovalStatus {
  String get value {
    switch (this) {
      case ProviderApprovalStatus.pending:
        return 'pending';
      case ProviderApprovalStatus.approved:
        return 'approved';
      case ProviderApprovalStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case ProviderApprovalStatus.pending:
        return 'Menunggu Persetujuan';
      case ProviderApprovalStatus.approved:
        return 'Disetujui';
      case ProviderApprovalStatus.rejected:
        return 'Ditolak';
    }
  }

  static ProviderApprovalStatus fromString(String value) {
    return ProviderApprovalStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProviderApprovalStatus.pending,
    );
  }
}

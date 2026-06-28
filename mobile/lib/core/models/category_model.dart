class ServiceCategory {
  final int id;
  final String name;
  final String description;
  final bool isActive;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}

class CategoriesResponse {
  final List<ServiceCategory> data;

  CategoriesResponse({required this.data});

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    return CategoriesResponse(
      data:
          (json['data'] as List?)
              ?.map((item) => ServiceCategory.fromJson(item))
              .toList() ??
          [],
    );
  }
}

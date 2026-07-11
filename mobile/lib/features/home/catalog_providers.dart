import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';

import '../../core/models/category_model.dart';
import '../../core/models/provider_model.dart';
import '../../core/models/review_model.dart';

// Categories provider
final categoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getCategories();
  return response.data;
});

class ProviderCatalogQuery {
  final int categoryId;
  final int? kotaId;
  final int? kecamatanId;

  const ProviderCatalogQuery({
    required this.categoryId,
    this.kotaId,
    this.kecamatanId,
  });

  @override
  bool operator ==(Object other) {
    return other is ProviderCatalogQuery &&
        other.categoryId == categoryId &&
        other.kotaId == kotaId &&
        other.kecamatanId == kecamatanId;
  }

  @override
  int get hashCode => Object.hash(categoryId, kotaId, kecamatanId);
}

class ProviderSearchQuery {
  final String query;
  final int? kotaId;
  final int? kecamatanId;

  const ProviderSearchQuery({
    required this.query,
    this.kotaId,
    this.kecamatanId,
  });

  @override
  bool operator ==(Object other) {
    return other is ProviderSearchQuery &&
        other.query == query &&
        other.kotaId == kotaId &&
        other.kecamatanId == kecamatanId;
  }

  @override
  int get hashCode => Object.hash(query, kotaId, kecamatanId);
}

// Providers by category and optional location
final providersByCategoryProvider =
    FutureProvider.family<List<ProviderProfile>, ProviderCatalogQuery>((
      ref,
      query,
    ) async {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getProvidersByCategory(
        query.categoryId,
        kotaId: query.kotaId,
        kecamatanId: query.kecamatanId,
      );
      return response.data;
    });

// Provider detail
final providerDetailProvider = FutureProvider.family<ProviderProfile, int>((
  ref,
  providerId,
) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getProviderDetail(providerId);
});

// Provider reviews
final providerReviewsProvider = FutureProvider.family<ReviewsResponse, int>((
  ref,
  providerId,
) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getProviderReviews(providerId);
});

// Search providers
final searchProvidersProvider =
    FutureProvider.family<List<ProviderProfile>, ProviderSearchQuery>((
      ref,
      query,
    ) async {
      if (query.query.isEmpty) return [];
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.searchProviders(
        query.query,
        kotaId: query.kotaId,
        kecamatanId: query.kecamatanId,
      );
      return response.data;
    });

// Selected category provider
final selectedCategoryProvider = StateProvider<int?>((ref) => null);

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

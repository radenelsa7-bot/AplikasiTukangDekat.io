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

// Providers by category
final providersByCategoryProvider =
    FutureProvider.family<List<ProviderProfile>, int>((ref, categoryId) async {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getProvidersByCategory(categoryId);
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
    FutureProvider.family<List<ProviderProfile>, String>((ref, query) async {
      if (query.isEmpty) return [];
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.searchProviders(query);
      return response.data;
    });

// Selected category provider
final selectedCategoryProvider = StateProvider<int?>((ref) => null);

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

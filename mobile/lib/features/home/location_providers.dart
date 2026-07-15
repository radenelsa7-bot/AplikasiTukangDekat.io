import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/location_models.dart';
import '../../core/services/api_service.dart';

/// Provider untuk fetch semua cities
final citiesProvider = FutureProvider<List<CityData>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  try {
    final response = await apiService.getCities();
    return response.data;
  } catch (e) {
    debugPrint('Error fetching cities: $e');
    rethrow;
  }
});

/// Provider untuk fetch districts berdasarkan city_id
/// Usage: ref.watch(districtsByCityProvider(cityId))
final districtsByCityProvider =
    FutureProvider.family<List<DistrictData>, int>((ref, cityId) async {
  final apiService = ref.read(apiServiceProvider);
  try {
    final response = await apiService.getDistrictsByCity(cityId);
    return response.data;
  } catch (e) {
    debugPrint('Error fetching districts for city $cityId: $e');
    rethrow;
  }
});

/// Provider untuk selected city ID (state management)
final selectedCityProvider = StateProvider<int?>((ref) => null);

/// Provider untuk selected district ID (state management)
final selectedDistrictProvider = StateProvider<int?>((ref) => null);

/// Provider computed untuk mendapatkan city yang dipilih
final selectedCityDataProvider = FutureProvider<CityData?>((ref) {
  final selectedCityId = ref.watch(selectedCityProvider);
  
  if (selectedCityId == null) {
    return Future.value(null);
  }

  return ref.watch(citiesProvider).when(
        data: (cities) {
          try {
            return cities.firstWhere((city) => city.id == selectedCityId);
          } catch (e) {
            return null;
          }
        },
        loading: () => throw Exception('Loading cities'),
        error: (error, st) => throw error,
      );
});

/// Provider computed untuk mendapatkan district yang dipilih
final selectedDistrictDataProvider = FutureProvider<DistrictData?>((ref) {
  final selectedCityId = ref.watch(selectedCityProvider);
  final selectedDistrictId = ref.watch(selectedDistrictProvider);
  
  if (selectedCityId == null || selectedDistrictId == null) {
    return Future.value(null);
  }

  return ref.watch(districtsByCityProvider(selectedCityId)).when(
        data: (districts) {
          try {
            return districts.firstWhere((d) => d.id == selectedDistrictId);
          } catch (e) {
            return null;
          }
        },
        loading: () => throw Exception('Loading districts'),
        error: (error, st) => throw error,
      );
});

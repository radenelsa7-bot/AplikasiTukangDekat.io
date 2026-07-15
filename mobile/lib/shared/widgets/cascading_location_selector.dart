import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/location_models.dart';
import '../../features/home/location_providers.dart';

/// Cascading Dropdown untuk pemilihan City & District
/// Digunakan di profile/edit location screen
class CascadingLocationSelector extends ConsumerWidget {
  final Function(int? cityId, int? districtId) onSelectionChanged;
  final int? initialCityId;
  final int? initialDistrictId;
  final bool isRequired;
  final String cityLabel;
  final String districtLabel;

  const CascadingLocationSelector({
    super.key,
    required this.onSelectionChanged,
    this.initialCityId,
    this.initialDistrictId,
    this.isRequired = false,
    this.cityLabel = 'Pilih Kota',
    this.districtLabel = 'Pilih Kecamatan',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(citiesProvider);
    final selectedCityId = ref.watch(selectedCityProvider);
    final selectedDistrictId = ref.watch(selectedDistrictProvider);

    // Initialize dengan nilai awal jika ada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialCityId != null && selectedCityId == null) {
        ref.read(selectedCityProvider.notifier).state = initialCityId;
      }
      if (initialDistrictId != null && selectedDistrictId == null) {
        ref.read(selectedDistrictProvider.notifier).state = initialDistrictId;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // City Dropdown
        Text(
          cityLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        citiesAsync.when(
          data: (cities) => _CityDropdown(
            cities: cities,
            selectedCityId: selectedCityId,
            onChanged: (cityId) {
              ref.read(selectedCityProvider.notifier).state = cityId;
              // Reset district when city changes
              ref.read(selectedDistrictProvider.notifier).state = null;
              onSelectionChanged(cityId, null);
            },
            isRequired: isRequired,
          ),
          loading: () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.grey300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, st) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.danger),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Gagal memuat daftar kota',
              style: TextStyle(color: AppTheme.danger, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // District Dropdown (enabled only when city is selected)
        Text(
          districtLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (selectedCityId != null)
          _DistrictDropdown(
            cityId: selectedCityId,
            selectedDistrictId: selectedDistrictId,
            onChanged: (districtId) {
              ref.read(selectedDistrictProvider.notifier).state = districtId;
              onSelectionChanged(selectedCityId, districtId);
            },
            isRequired: isRequired,
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.grey300),
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.grey100,
            ),
            child: const Text(
              'Pilih kota terlebih dahulu',
              style: TextStyle(
                color: AppTheme.grey500,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}

/// City Dropdown Component
class _CityDropdown extends ConsumerWidget {
  final List<CityData> cities;
  final int? selectedCityId;
  final Function(int?) onChanged;
  final bool isRequired;

  const _CityDropdown({
    required this.cities,
    required this.selectedCityId,
    required this.onChanged,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.grey300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int?>(
        isExpanded: true,
        value: selectedCityId,
        underline: const SizedBox(),
        hint: const Text('Pilih kota...'),
        items: [
          // Placeholder option
          if (!isRequired)
            DropdownMenuItem<int?>(
              value: null,
              child: const Text('Pilih kota...'),
            ),
          // City options
          ...cities.map((city) {
            return DropdownMenuItem<int?>(
              value: city.id,
              child: Text(city.name),
            );
          }),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// District Dropdown Component
class _DistrictDropdown extends ConsumerWidget {
  final int cityId;
  final int? selectedDistrictId;
  final Function(int?) onChanged;
  final bool isRequired;

  const _DistrictDropdown({
    required this.cityId,
    required this.selectedDistrictId,
    required this.onChanged,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districtsAsync = ref.watch(districtsByCityProvider(cityId));

    return districtsAsync.when(
      data: (districts) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.grey300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<int?>(
          isExpanded: true,
          value: selectedDistrictId,
          underline: const SizedBox(),
          hint: const Text('Pilih kecamatan...'),
          items: [
            // Placeholder option
            if (!isRequired)
              DropdownMenuItem<int?>(
                value: null,
                child: const Text('Pilih kecamatan...'),
              ),
            // District options
            ...districts.map((district) {
              return DropdownMenuItem<int?>(
                value: district.id,
                child: Text(district.name),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.grey300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, st) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.danger),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Gagal memuat daftar kecamatan',
          style: TextStyle(color: AppTheme.danger, fontSize: 12),
        ),
      ),
    );
  }
}

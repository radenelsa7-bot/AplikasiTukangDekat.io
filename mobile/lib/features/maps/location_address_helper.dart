String buildReadableLocationAddress({
  required double lat,
  required double lng,
  Map<String, dynamic>? geocodingData,
  String? displayName,
}) {
  final fallback = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';

  final cleanedDisplay = displayName?.trim();
  if (cleanedDisplay != null &&
      cleanedDisplay.isNotEmpty &&
      !cleanedDisplay.startsWith('Lat:')) {
    return cleanedDisplay;
  }

  if (geocodingData != null) {
    final address = geocodingData['address'];
    if (address is Map) {
      final road = address['road']?.toString().trim();
      final suburb = address['suburb']?.toString().trim();
      final village = address['village']?.toString().trim();
      final town = address['town']?.toString().trim();
      final city = address['city']?.toString().trim();
      final municipality = address['municipality']?.toString().trim();
      final state = address['state']?.toString().trim();
      final country = address['country']?.toString().trim();

      final parts = <String?>[
        road,
        suburb,
        village,
        town,
        city,
        municipality,
        state,
        country,
      ].where((value) => value != null && value.isNotEmpty).cast<String?>().toList();

      final nonNullParts = parts.whereType<String>().toList();

      if (nonNullParts.isNotEmpty) {
        return nonNullParts.join(', ');
      }

      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }
  }

  return fallback;
}

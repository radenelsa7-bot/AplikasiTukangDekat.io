import 'package:flutter/material.dart';

import 'osm_map_preview.dart' as osm;

/// Wrapper kompatibilitas nama lama.
/// Mengganti implementasi internal ke OSM (flutter_map).
class GoogleMapsPreview extends StatelessWidget {
  final double? customerLatitude;
  final double? customerLongitude;
  final double? providerLatitude;
  final double? providerLongitude;

  final String customerLabel;
  final String providerLabel;

  const GoogleMapsPreview({
    super.key,
    this.customerLatitude,
    this.customerLongitude,
    this.providerLatitude,
    this.providerLongitude,
    this.customerLabel = 'Pengguna',
    this.providerLabel = 'Provider',
  });

  @override
  Widget build(BuildContext context) {
    return osm.OsmMapPreview(
      customerLatitude: customerLatitude,
      customerLongitude: customerLongitude,
      providerLatitude: providerLatitude,
      providerLongitude: providerLongitude,
      customerLabel: customerLabel,
      providerLabel: providerLabel,
    );
  }
}


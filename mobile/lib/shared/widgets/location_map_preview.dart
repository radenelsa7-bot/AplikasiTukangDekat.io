import 'package:flutter/material.dart';

import 'google_maps_preview.dart';

class LocationMapPreview extends StatelessWidget {
  final double? customerLatitude;
  final double? customerLongitude;
  final double? providerLatitude;
  final double? providerLongitude;
  final String customerLabel;
  final String providerLabel;

  const LocationMapPreview({
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
    return GoogleMapsPreview(
      customerLatitude: customerLatitude,
      customerLongitude: customerLongitude,
      providerLatitude: providerLatitude,
      providerLongitude: providerLongitude,
      customerLabel: customerLabel,
      providerLabel: providerLabel,
    );
  }
}


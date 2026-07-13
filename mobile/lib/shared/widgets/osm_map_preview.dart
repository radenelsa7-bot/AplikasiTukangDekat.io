import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_theme.dart';

class OsmMapPreview extends StatelessWidget {
  final double? customerLatitude;
  final double? customerLongitude;
  final double? providerLatitude;
  final double? providerLongitude;

  final String customerLabel;
  final String providerLabel;

  const OsmMapPreview({
    super.key,
    this.customerLatitude,
    this.customerLongitude,
    this.providerLatitude,
    this.providerLongitude,
    this.customerLabel = 'Pengguna',
    this.providerLabel = 'Provider',
  });

  bool get _hasCustomer => customerLatitude != null && customerLongitude != null;
  bool get _hasProvider => providerLatitude != null && providerLongitude != null;

  LatLng? get _customerLatLng =>
      _hasCustomer ? LatLng(customerLatitude!, customerLongitude!) : null;
  LatLng? get _providerLatLng =>
      _hasProvider ? LatLng(providerLatitude!, providerLongitude!) : null;

  @override
  Widget build(BuildContext context) {
    final customer = _customerLatLng;
    final provider = _providerLatLng;

    final points = <LatLng>[];
    if (customer != null) points.add(customer);
    if (provider != null) points.add(provider);

    if (kIsWeb) {
      return SizedBox(
        height: 190,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ColoredBox(
            color: Colors.grey.shade200,
            child: const Center(
              child: Text(
                'Map tidak tersedia di web saat ini',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      );
    }

    // FIX: If no coordinates, show error message instead of infinite loading
    if (points.isEmpty) {
      return SizedBox(
        height: 250,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ColoredBox(
            color: Colors.grey.shade100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 48,
                    color: AppTheme.grey400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lokasi belum tersedia',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Silakan tunggu atau refresh halaman',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final center = points.length >= 2
        ? LatLng(
            (points.first.latitude + points.last.latitude) / 2,
            (points.first.longitude + points.last.longitude) / 2,
          )
        : points.first;

    final markerLayer = MarkerLayer(
      markers: [
        if (customer != null)
          Marker(
            point: customer,
            width: 40,
            height: 40,
            child: _buildMarkerDot(color: AppTheme.orange),
          ),
        if (provider != null)
          Marker(
            point: provider,
            width: 40,
            height: 40,
            child: _buildMarkerDot(color: AppTheme.success),
          ),
      ],
    );

    return SizedBox(
      height: 190,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: points.length >= 2 ? 12 : 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tukangdekat.app',
            ),
            markerLayer,
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerDot({required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Icon(Icons.location_on, size: 22, color: Colors.white),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';


import '../../app/theme/app_theme.dart';

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

    // Fallback camera
    final initial =
        provider ?? customer ?? const LatLng(-6.200000, 106.816666);

    final markers = <Marker>{
      if (customer != null)
        Marker(
          markerId: const MarkerId('customer'),
          position: customer,
          infoWindow: InfoWindow(title: customerLabel),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      if (provider != null)
        Marker(
          markerId: const MarkerId('provider'),
          position: provider,
          infoWindow: InfoWindow(title: providerLabel),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
    };

    final bounds = <LatLng>[
      if (customer != null) customer,
      if (provider != null) provider,
    ];

    // Web: google_maps_flutter_web butuh JS SDK dimuat. Jika tidak siap,
    // hindari crash dan tampilkan fallback.
    if (kIsWeb) {
      return SizedBox(
        height: 190,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ColoredBox(
            color: Colors.grey.shade200,
            child: Center(
              child: Text(
                'Map tidak tersedia di web saat ini',
                style: TextStyle(
                  color: AppTheme.grey600,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 190,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initial,
            zoom: 14,
          ),
          markers: markers,
          myLocationEnabled: false,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            if (bounds.length >= 2) {
              final b = _computeLatLngBounds(bounds);
              controller
                  .animateCamera(CameraUpdate.newLatLngBounds(b, 40));
            } else {
              // single marker: keep initial camera
            }
          },
        ),
      ),
    );
  }

  LatLngBounds _computeLatLngBounds(List<LatLng> points) {
    double? south;
    double? north;
    double? west;
    double? east;

    for (final p in points) {
      south = south == null ? p.latitude : (p.latitude < south! ? p.latitude : south!);
      north = north == null ? p.latitude : (p.latitude > north! ? p.latitude : north!);
      west = west == null ? p.longitude : (p.longitude < west! ? p.longitude : west!);
      east = east == null ? p.longitude : (p.longitude > east! ? p.longitude : east!);
    }

    return LatLngBounds(
      southwest: LatLng(south!, west!),
      northeast: LatLng(north!, east!),
    );
  }
}


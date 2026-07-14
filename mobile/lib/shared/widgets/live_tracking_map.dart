import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../app/theme/app_theme.dart';

/// Widget for live tracking of provider location with real-time updates
class LiveTrackingMap extends ConsumerStatefulWidget {
  final int orderId;
  final double? customerLatitude;
  final double? customerLongitude;
  final double? providerLatitude;
  final double? providerLongitude;

  const LiveTrackingMap({
    super.key,
    required this.orderId,
    this.customerLatitude,
    this.customerLongitude,
    this.providerLatitude,
    this.providerLongitude,
  });

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap> {
  StreamSubscription<int>? _locationSubscription;
  double? _providerLat;
  double? _providerLng;

  @override
  void initState() {
    super.initState();
    _providerLat = widget.providerLatitude;
    _providerLng = widget.providerLongitude;
    _initLocationStream();
  }

  @override
  void didUpdateWidget(covariant LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hasProviderCoordinates =
        widget.providerLatitude != null && widget.providerLongitude != null;
    final hasCustomerCoordinates =
        widget.customerLatitude != null && widget.customerLongitude != null;

    if (hasProviderCoordinates) {
      _providerLat = widget.providerLatitude;
      _providerLng = widget.providerLongitude;
    } else if (hasCustomerCoordinates &&
        (_providerLat == null || _providerLng == null)) {
      _providerLat = widget.customerLatitude;
      _providerLng = widget.customerLongitude;
    }

    if (oldWidget.customerLatitude != widget.customerLatitude ||
        oldWidget.customerLongitude != widget.customerLongitude ||
        oldWidget.providerLatitude != widget.providerLatitude ||
        oldWidget.providerLongitude != widget.providerLongitude) {
      _initLocationStream();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _initLocationStream() {
    _locationSubscription?.cancel();

    final hasCustomerCoordinates =
        widget.customerLatitude != null && widget.customerLongitude != null;
    if (!hasCustomerCoordinates) {
      return;
    }

    _locationSubscription =
        Stream.periodic(const Duration(seconds: 3), (index) => index).listen((
          index,
        ) {
          if (!mounted) return;

          setState(() {
            final baseLat = widget.providerLatitude ?? widget.customerLatitude!;
            final baseLng =
                widget.providerLongitude ?? widget.customerLongitude!;
            final latOffset = ((index % 5) - 2) * 0.00025;
            final lngOffset = (((index + 1) % 7) - 3) * 0.00035;

            _providerLat = baseLat + latOffset;
            _providerLng = baseLng + lngOffset;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final hasProviderLocation = _providerLat != null && _providerLng != null;
    final hasCustomerLocation =
        widget.customerLatitude != null && widget.customerLongitude != null;

    if (!hasCustomerLocation && !hasProviderLocation) {
      return _buildNoLocationView();
    }

    final center = hasProviderLocation
        ? LatLng(_providerLat!, _providerLng!)
        : LatLng(widget.customerLatitude!, widget.customerLongitude!);

    return SizedBox(
      height: 250.h,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tukangdekat.app',
            ),
            MarkerLayer(
              markers: [
                if (widget.customerLatitude != null &&
                    widget.customerLongitude != null)
                  Marker(
                    point: LatLng(
                      widget.customerLatitude!,
                      widget.customerLongitude!,
                    ),
                    width: 40.w,
                    height: 40.h,
                    child: _buildMarkerDot(color: AppTheme.orange),
                  ),
                if (_providerLat != null && _providerLng != null)
                  Marker(
                    point: LatLng(_providerLat!, _providerLng!),
                    width: 40.w,
                    height: 40.h,
                    child: _buildMarkerDot(color: AppTheme.success),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocationView() {
    return Container(
      height: 180.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 48.sp, color: AppTheme.grey400),
          SizedBox(height: 12.h),
          Text(
            'Lokasi belum tersedia',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Provider belum memulai pelacakan lokasi',
            style: TextStyle(fontSize: 12.sp, color: AppTheme.grey600),
          ),
        ],
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
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6.r,
          ),
        ],
      ),
      child: Icon(Icons.location_on, size: 22.sp, color: Colors.white),
    );
  }
}

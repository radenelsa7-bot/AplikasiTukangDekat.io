import 'dart:async';
import 'package:flutter/material.dart';
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
  StreamSubscription<double?>? _locationSubscription;
  double? _providerLat;
  double? _providerLng;
  DateTime? _lastUpdate;

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
    if (oldWidget.providerLatitude != widget.providerLatitude ||
        oldWidget.providerLongitude != widget.providerLongitude) {
      _providerLat = widget.providerLatitude;
      _providerLng = widget.providerLongitude;
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _initLocationStream() {
    // Simulate polling for location updates
    // In production, this would use WebSocket or SSE for real-time updates
    _locationSubscription = Stream.periodic(
      const Duration(seconds: 10),
      (_) => _fetchProviderLocation(),
    ).listen((location) {
      // This will be called periodically - in production would update with real location
    });
  }

  double? _fetchProviderLocation() {
    // This would normally fetch from backend API via WebSocket or SSE
    // For now, location updates are passed through didUpdateWidget
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasProviderLocation = _providerLat != null && _providerLng != null;
    final hasCustomerLocation = widget.customerLatitude != null && widget.customerLongitude != null;

    if (!hasCustomerLocation && !hasProviderLocation) {
      return _buildNoLocationView();
    }

    final center = hasProviderLocation
        ? LatLng(_providerLat!, _providerLng!)
        : LatLng(widget.customerLatitude!, widget.customerLongitude!);

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
                if (widget.customerLatitude != null && widget.customerLongitude != null)
                  Marker(
                    point: LatLng(widget.customerLatitude!, widget.customerLongitude!),
                    width: 40,
                    height: 40,
                    child: _buildMarkerDot(color: AppTheme.orange),
                  ),
                if (_providerLat != null && _providerLng != null)
                  Marker(
                    point: LatLng(_providerLat!, _providerLng!),
                    width: 40,
                    height: 40,
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
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
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
            'Provider belum memulai pelacakan lokasi',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.grey600,
            ),
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
            blurRadius: 6,
          ),
        ],
      ),
      child: const Icon(Icons.location_on, size: 22, color: Colors.white),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import '../../app/theme/app_theme.dart';

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
  static const Duration _updateInterval = Duration(seconds: 3);
  static const int _simulationSteps = 24;
  static const double _providerOffsetLat = 0.0012;
  static const double _providerOffsetLng = 0.0012;

  StreamSubscription<int>? _locationSubscription;

  double? _providerLat;
  double? _providerLng;

  double? _startLat;
  double? _startLng;
  double? _targetLat;
  double? _targetLng;

  DateTime? _lastUpdate;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _seedSimulation();
    _initLocationStream();
  }

  @override
  void didUpdateWidget(covariant LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerLatitude != widget.customerLatitude ||
        oldWidget.customerLongitude != widget.customerLongitude ||
        oldWidget.providerLatitude != widget.providerLatitude ||
        oldWidget.providerLongitude != widget.providerLongitude) {
      _locationSubscription?.cancel();
      _seedSimulation();
      _initLocationStream();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _seedSimulation() {
    _step = 0;
    _lastUpdate = null;

    final hasCustomer =
        widget.customerLatitude != null && widget.customerLongitude != null;
    final hasProvider =
        widget.providerLatitude != null && widget.providerLongitude != null;

    _targetLat = hasCustomer
        ? widget.customerLatitude
        : widget.providerLatitude;
    _targetLng = hasCustomer
        ? widget.customerLongitude
        : widget.providerLongitude;

    if (hasProvider) {
      _startLat = widget.providerLatitude;
      _startLng = widget.providerLongitude;
    } else if (hasCustomer) {
      _startLat = widget.customerLatitude! + _providerOffsetLat;
      _startLng = widget.customerLongitude! - _providerOffsetLng;
    } else {
      _startLat = null;
      _startLng = null;
    }

    _providerLat = _startLat;
    _providerLng = _startLng;
  }

  bool get _canSimulate =>
      _startLat != null &&
      _startLng != null &&
      _targetLat != null &&
      _targetLng != null;

  void _initLocationStream() {
    if (!_canSimulate) return;

    _locationSubscription = Stream<int>.periodic(
      _updateInterval,
      (tick) => tick + 1,
    ).take(_simulationSteps).listen(_onSimulatedTick);
  }

  void _onSimulatedTick(int tick) {
    if (!mounted || !_canSimulate) return;

    _step = tick.clamp(0, _simulationSteps);
    final t = _step / _simulationSteps;

    setState(() {
      _providerLat = _startLat! + (_targetLat! - _startLat!) * t;
      _providerLng = _startLng! + (_targetLng! - _startLng!) * t;
      _lastUpdate = DateTime.now();
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

    final showRoute = hasCustomerLocation && hasProviderLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 250.h,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tukangdekat.app',
                    ),
                    if (showRoute)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              LatLng(widget.customerLatitude!, widget.customerLongitude!),
                              LatLng(_providerLat!, _providerLng!),
                            ],
                            color: AppTheme.orange.withValues(alpha: 0.75),
                            strokeWidth: 3.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (hasCustomerLocation)
                          Marker(
                            point: LatLng(
                              widget.customerLatitude!,
                              widget.customerLongitude!,
                            ),
                            width: 40.w,
                            height: 40.w,
                            child: _buildMarkerDot(color: AppTheme.orange),
                          ),
                        if (hasProviderLocation)
                          Marker(
                            point: LatLng(_providerLat!, _providerLng!),
                            width: 40.w,
                            height: 40.w,
                            child: _buildMarkerDot(color: AppTheme.success),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(top: 10.h, left: 10.w, child: _buildLiveBadge()),
              ],
            ),
          ),
        ),
        SizedBox(height: 10.h),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4.r),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: const BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem(AppTheme.orange, 'Customer'),
        SizedBox(width: 16.w),
        _buildLegendItem(AppTheme.success, 'Provider'),
        const Spacer(),
        Text(
          _lastUpdate == null
              ? 'Menunggu lokasi...'
              : 'Diperbarui ${_formatLastUpdate(_lastUpdate!)}',
          style: TextStyle(fontSize: 11.sp, color: AppTheme.grey600),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(label, style: TextStyle(fontSize: 11.sp, color: AppTheme.grey600)),
      ],
    );
  }

  String _formatLastUpdate(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 5) return 'baru saja';
    if (diff.inMinutes < 1) return '${diff.inSeconds} detik lalu';
    return '${diff.inMinutes} menit lalu';
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
          Icon(Icons.location_off, size: 48.r, color: AppTheme.grey400),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6.r),
        ],
      ),
      child: Icon(Icons.location_on, size: 22.r, color: Colors.white),
    );
  }
}
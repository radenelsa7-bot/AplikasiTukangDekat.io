import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

final selectedLocationProvider = StateProvider<LocationResult?>((ref) => null);

class OsmLocationPickerScreen extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const OsmLocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  @override
  ConsumerState<OsmLocationPickerScreen> createState() =>
      _OsmLocationPickerScreenState();
}

class _OsmLocationPickerScreenState extends ConsumerState<OsmLocationPickerScreen> {
  final MapController _mapController = MapController();

  double? _latitude;
  double? _longitude;
  String _address = '';
  late final TextEditingController _addressController;

  bool _isLoadingLocation = false;
  String? _error;

  LatLng? get _selectedLatLng =>
      (_latitude != null && _longitude != null)
          ? LatLng(_latitude!, _longitude!)
          : null;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLat;
    _longitude = widget.initialLng;
    _address = widget.initialAddress ?? '';
    _addressController = TextEditingController(text: _address);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _error = 'Lokasi GPS tidak aktif. Silakan aktifkan GPS.';
          _isLoadingLocation = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _error = 'Izin lokasi ditolak.';
          _isLoadingLocation = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _error = 'Izin lokasi ditolak permanen. Silakan aktifkan dari pengaturan.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final selected = LatLng(position.latitude, position.longitude);

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _address = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        _addressController.text = _address;
        _isLoadingLocation = false;
      });

      await _mapController.move(selected, 15);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal mendapatkan lokasi: $e';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _openGoogleMaps() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambil lokasi terlebih dahulu')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude',
    );

    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka Google Maps.')),
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _confirmLocation() {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambil lokasi terlebih dahulu')),
      );
      return;
    }

    final result = LocationResult(
      latitude: _latitude!,
      longitude: _longitude!,
      address: _address,
    );

    ref.read(selectedLocationProvider.notifier).state = result;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter =
        _selectedLatLng ?? const LatLng(-6.200000, 106.816666);

    final markers = <Marker>[
      if (_selectedLatLng != null)
        Marker(
          point: _selectedLatLng!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.location_on, size: 22, color: Colors.white),
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: _selectedLatLng == null ? 5 : 14,
                onTap: (tapPosition, latLng) {
                  setState(() {
                    _latitude = latLng.latitude;
                    _longitude = latLng.longitude;
                    _address = 'Lat: ${latLng.latitude.toStringAsFixed(6)}, Lng: ${latLng.longitude.toStringAsFixed(6)}';
                    _addressController.text = _address;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tukangdekat.app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          if (_selectedLatLng == null)
            const Padding(
              padding: EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Tekan tombol GPS\natau tap peta untuk atur lokasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.2),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_latitude, $_longitude',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Alamat Lengkap',
                    hintText: 'Tulis alamat lengkap...',
                    prefixIcon: const Icon(Icons.edit_location_alt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                  onChanged: (v) => _address = v,
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.gps_fixed),
                        label: Text(_isLoadingLocation ? 'Mendeteksi...' : 'GPS Saya'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openGoogleMaps,
                        icon: const Icon(Icons.map),
                        label: const Text('Buka Maps'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Konfirmasi Lokasi',
                    onPressed: _confirmLocation,
                    isLoading: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


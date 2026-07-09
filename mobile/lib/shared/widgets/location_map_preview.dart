import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';

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

  bool get _hasCustomer => customerLatitude != null && customerLongitude != null;
  bool get _hasProvider => providerLatitude != null && providerLongitude != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.grey100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.grey200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
          if (_hasCustomer) const Positioned(left: 34, bottom: 42, child: _MapPin(color: AppTheme.orange, icon: Icons.home_rounded)),
          if (_hasProvider) const Positioned(right: 38, top: 38, child: _MapPin(color: AppTheme.success, icon: Icons.engineering_rounded)),
          if (_hasCustomer && _hasProvider)
            Positioned.fill(
              child: CustomPaint(painter: _RoutePainter()),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _LegendDot(color: AppTheme.orange, label: customerLabel),
                _LegendDot(color: AppTheme.success, label: providerLabel),
                TextButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Buka Maps'),
                ),
              ],
            ),
          ),
          if (!_hasCustomer && !_hasProvider)
            const Center(
              child: Text(
                'Lokasi belum tersedia',
                style: TextStyle(color: AppTheme.grey600),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openMaps() async {
    final lat = providerLatitude ?? customerLatitude;
    final lng = providerLongitude ?? customerLongitude;
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _MapPin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 3;
    for (var y = 28.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 24), paint);
    }
    for (var x = 24.0; x < size.width; x += 62) {
      canvas.drawLine(Offset(x, 0), Offset(x - 28, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.navy.withValues(alpha: 0.35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(58, size.height - 58)
      ..quadraticBezierTo(size.width / 2, size.height / 2, size.width - 58, 58);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

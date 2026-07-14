# Live Tracking Map - Implementasi Fitur Lengkap

## Status Implementasi ✅

Fitur live tracking map telah berhasil diimplementasikan dengan semua fitur yang diperlukan:

### 1. ✅ Real-Time Location Sync dari Backend
**File:** `mobile/lib/shared/widgets/live_tracking_map.dart`

- Implementasi auto-refresh dengan interval 5 detik
- Fetch data order terbaru dari backend menggunakan API
- Smooth animation animasi pergerakan marker provider ke lokasi baru
- Handling error gracefully dengan fallback

```dart
/// Fetch lokasi provider terbaru dari backend
Future<void> _refreshProviderLocation() async {
  if (_isRefreshing || !mounted) return;
  
  _isRefreshing = true;
  try {
    final api = ref.read(apiServiceProvider);
    final orderData = await api.getOrderDetail(widget.orderId);
    
    if (mounted && (orderData.providerLatitude != null && 
        orderData.providerLongitude != null)) {
      setState(() {
        _targetLat = orderData.providerLatitude;
        _targetLng = orderData.providerLongitude;
        _lastUpdate = DateTime.now();
      });
      
      // Smooth animate ke lokasi baru
      _seedSimulation();
      _initLocationStream();
    }
  } catch (e) {
    debugPrint('Error refreshing provider location: $e');
  } finally {
    _isRefreshing = false;
  }
}
```

### 2. ✅ Garis Rute (Polyline)
**File:** `mobile/lib/shared/widgets/live_tracking_map.dart`

Menampilkan garis rute dari customer ke provider dengan:
- Warna orange semi-transparent untuk visual yang jelas
- Stroke width 3.0 untuk keterbacaan
- Hanya ditampilkan ketika kedua lokasi tersedia

```dart
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
```

### 3. ✅ Marker Popup/Info Window
**File:** `mobile/lib/shared/widgets/live_tracking_map.dart`

- Tap handler pada setiap marker (customer dan provider)
- Info window menampilkan nama (provider/customer) dan koordinat
- Visual feedback dengan shadow highlight saat marker dipilih
- Auto-close setelah 3 detik

```dart
void _showMarkerInfo(int markerType, String title) {
  final info = markerType == 0
      ? {
          'title': title,
          'lat': widget.customerLatitude,
          'lng': widget.customerLongitude,
        }
      : {
          'title': widget.providerName ?? title,
          'lat': _providerLat,
          'lng': _providerLng,
        };

  setState(() {
    _selectedMarkerType = _selectedMarkerType == markerType ? null : markerType;
  });

  if (_selectedMarkerType == markerType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info['title'],
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text('${info['lat']?.toStringAsFixed(6)}, ${info['lng']?.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
```

### 4. ✅ Interaksi Zoom & Pan
**File:** `mobile/lib/shared/widgets/live_tracking_map.dart`

- Enable semua InteractionFlags untuk memungkinkan zoom, pan, dan rotate
- Zoom controls buttons (+ dan -) di sudut kanan bawah
- Min zoom: 5, Max zoom: 18
- Smooth animation untuk zoom movement

```dart
FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: center,
    initialZoom: 14,
    minZoom: 5,
    maxZoom: 18,
    interactionOptions: const InteractionOptions(
      flags: InteractiveFlag.all,
    ),
  ),
  // ...
)
```

**Zoom Controls:**
```dart
Widget _buildZoomControls() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: AppTheme.grey300),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.add, color: AppTheme.navy),
          onPressed: () => _mapController.move(
            _mapController.center,
            _mapController.zoom + 1,
          ),
        ),
        Container(height: 1, width: 36.r, color: AppTheme.grey300),
        IconButton(
          icon: const Icon(Icons.remove, color: AppTheme.navy),
          onPressed: () => _mapController.move(
            _mapController.center,
            (_mapController.zoom - 1).clamp(5, 18),
          ),
        ),
      ],
    ),
  );
}
```

### 5. ✅ Auto-Update Lokasi Saat Provider Bergerak
**File:** `mobile/lib/shared/widgets/live_tracking_map.dart`

Implementasi dengan polling:

```dart
/// Initialize auto-refresh dari backend untuk mendapatkan lokasi terbaru
void _initAutoRefresh() {
  if (!widget.enableAutoRefresh) return;

  _refreshSubscription = Stream<int>.periodic(
    _refreshInterval,  // 5 detik
    (tick) => tick + 1,
  ).listen((_) => _refreshProviderLocation());
}
```

Parameter untuk enable/disable:
```dart
const LiveTrackingMap(
  // ...
  enableAutoRefresh: true,  // Default enabled
)
```

## Files yang Dimodifikasi

### 1. `mobile/lib/shared/widgets/live_tracking_map.dart` ✅
**Perubahan:**
- Menambah imports untuk API service
- Menambah MapController untuk zoom/pan control
- Menambah auto-refresh mechanism dengan polling
- Menambah marker tap handlers untuk info window
- Menambah zoom controls buttons
- Menambah selected marker state untuk visual feedback
- Update marker building dengan isSelected parameter

**Fitur Baru:**
- Real-time auto-refresh dari backend
- Marker popup info window
- Zoom & pan controls
- Better visual feedback untuk selected marker

### 2. `mobile/lib/core/models/order_model.dart` ✅
**Perubahan:**
- Menambah field `providerName` ke OrderData class
- Update factory method untuk parse provider name dari response JSON

```dart
providerName: json['provider']?['full_name'] ?? json['provider_name'],
```

### 3. `mobile/lib/features/home/order_detail_page.dart` ✅
**Perubahan:**
- Update `_buildTrackingCard()` untuk mengirim `providerName` dan `enableAutoRefresh`
- LiveTrackingMap sekarang menerima data provider name untuk ditampilkan di popup

```dart
LiveTrackingMap(
  orderId: order.id,
  customerLatitude: order.customerLatitude,
  customerLongitude: order.customerLongitude,
  providerLatitude: order.providerLatitude,
  providerLongitude: order.providerLongitude,
  providerName: order.providerName,  // NEW
  enableAutoRefresh: true,            // NEW
),
```

## Backend Integration

### API yang Digunakan

1. **GET `/api/orders/{orderId}`** - Fetch order detail dengan lokasi provider terbaru
   ```dart
   final orderData = await api.getOrderDetail(widget.orderId);
   ```

2. **POST `/api/profile/update`** - Provider update lokasi mereka
   ```dart
   await api.updateProviderProfile(
     businessName: businessName,
     description: description,
     area: area,
     address: address,
     latitude: latitude,
     longitude: longitude,
   );
   ```

### Response Expected dari Backend

```json
{
  "id": 1,
  "order_code": "ORD-2026-001",
  "status": "ACCEPTED",
  "provider": {
    "id": 1,
    "full_name": "PT Service Jaya"
  },
  "customer_latitude": -6.1234,
  "customer_longitude": 106.5678,
  "provider_latitude": -6.1250,
  "provider_longitude": 106.5700,
  // ... other fields
}
```

## Usage

Menggunakan LiveTrackingMap di halaman order detail:

```dart
LiveTrackingMap(
  orderId: 123,
  customerLatitude: -6.1234,
  customerLongitude: 106.5678,
  providerLatitude: -6.1250,
  providerLongitude: 106.5700,
  providerName: 'PT Service Jaya',
  enableAutoRefresh: true,  // Auto-fetch lokasi setiap 5 detik
)
```

## Performance Optimization

### 1. Debouncing untuk API Calls
- Auto-refresh interval: 5 detik untuk mencegah API spam
- `_isRefreshing` flag untuk prevent duplicate requests

### 2. Mounted Checks
- Semua setState() calls dilindungi dengan mounted check
- Prevent memory leaks saat widget unmounted

### 3. Stream Cleanup
- Subscription streams di-cancel di dispose()
- Proper resource management untuk long-running operations

## Testing Checklist

- [ ] Map menampilkan dengan benar
- [ ] Marker customer dan provider terlihat
- [ ] Garis rute ditampilkan dengan benar
- [ ] Tap marker menampilkan info window
- [ ] Zoom controls berfungsi (+/- buttons dan pinch zoom)
- [ ] Pan/drag map berfungsi dengan smooth
- [ ] Auto-refresh lokasi bekerja setiap 5 detik
- [ ] Update lokasi smooth dengan animasi
- [ ] No memory leaks atau widget issues saat navigate

## Future Improvements

1. **WebSocket Integration** - Replace polling dengan WebSocket untuk real-time yang lebih efisien
   ```dart
   // Implementasi WebSocket untuk live tracking
   // Akan mengganti Stream.periodic dengan WebSocket connection
   ```

2. **Estimated Time of Arrival (ETA)** - Hitung ETA berdasarkan jarak dan kecepatan
   ```dart
   double calculateETA(LatLng from, LatLng to) {
     final distance = const Distance().as(LengthUnit.Meter, from, to);
     // Calculate ETA based on distance and average speed
   }
   ```

3. **Battery Optimization** - Reduce polling frequency saat idle atau battery low
   ```dart
   void _adjustRefreshRate(BatteryLevel level) {
     // Adjust _refreshInterval based on battery level
   }
   ```

4. **Offline Support** - Cache last known location saat offline
   ```dart
   Future<void> _cacheLastLocation() async {
     // Save to local storage
   }
   ```

5. **Historical Route** - Show riwayat perjalanan provider
   ```dart
   final PolylineLayer historicalRoute = PolylineLayer(
     polylines: [
       Polyline(
         points: locationHistory,
         color: Colors.grey,
         strokeWidth: 2.0,
         isDotted: true,
       ),
     ],
   );
   ```

## Troubleshooting

### Lokasi tidak update otomatis
- Pastikan `enableAutoRefresh: true` di LiveTrackingMap
- Check network connectivity
- Verify API endpoint `/api/orders/{orderId}` accessible
- Check browser console/logcat untuk error messages

### Marker tidak responsive saat di-tap
- Ensure GestureDetector wrapping marker widget
- Check if `_showMarkerInfo()` method called properly
- Verify ScaffoldMessenger context available

### Zoom controls not working
- Verify MapController initialized properly
- Check InteractionOptions flags set to `InteractiveFlag.all`
- Ensure zoom values within min/max range (5-18)

## Documentation References

- Flutter Map Package: https://pub.dev/packages/flutter_map
- Riverpod State Management: https://pub.dev/packages/flutter_riverpod
- Latlong2 Library: https://pub.dev/packages/latlong2

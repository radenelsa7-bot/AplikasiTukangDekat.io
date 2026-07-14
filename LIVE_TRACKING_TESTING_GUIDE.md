# Testing Guide - Live Tracking Map Implementation

## Pre-Test Requirements

✅ Pastikan semua fitur sudah di-deploy:
- Update `live_tracking_map.dart` dengan versi baru
- Update `order_model.dart` dengan providerName field
- Update `order_detail_page.dart` untuk pass providerName ke widget

✅ Backend API Requirements:
- Order detail endpoint mengembalikan `provider` object dengan `full_name`
- Provider location fields: `provider_latitude`, `provider_longitude`
- Provider update profile endpoint working

✅ Network Requirements:
- Internet connection aktif (untuk OpenStreetMap tiles)
- GPS location services available (untuk LocationPickerScreen)
- Backend API accessible

## Test Cases

### 1. Display Map & Markers
**Scenario:** Membuka halaman order detail dengan lokasi tersedia
**Steps:**
1. Navigate ke order detail page
2. Scroll ke "Tracking Lokasi" section
3. Verify peta ditampilkan dengan benar

**Expected Results:**
- ✅ Peta OpenStreetMap terload
- ✅ Customer marker (orange) terlihat di lokasi customer
- ✅ Provider marker (green) terlihat di lokasi provider
- ✅ "LIVE" badge ditampilkan di sudut kiri atas
- ✅ Legend menampilkan "Customer" dan "Provider"
- ✅ Update timestamp terlihat (e.g., "Diperbarui baru saja")

### 2. Route Line
**Scenario:** Verifikasi garis rute ditampilkan
**Steps:**
1. Di order dengan customer dan provider location
2. Lihat peta tracking

**Expected Results:**
- ✅ Garis rute (polyline) berwarna orange ditampilkan
- ✅ Garis menghubungkan customer ke provider
- ✅ Garis semi-transparent (tidak opaque)

### 3. Marker Info Popup
**Scenario:** Tap marker untuk melihat info
**Steps:**
1. Tap customer marker (orange dot)
2. Lihat popup yang muncul
3. Tap provider marker (green dot)
4. Lihat popup yang muncul

**Expected Results untuk Customer Marker:**
- ✅ SnackBar muncul di bawah peta
- ✅ Judul: "Customer"
- ✅ Tampil koordinat customer (lat, lng dengan 6 decimal)
- ✅ SnackBar hilang setelah 3 detik
- ✅ Marker glow effect visible (shadow membesar)

**Expected Results untuk Provider Marker:**
- ✅ SnackBar muncul di bawah peta
- ✅ Judul: Provider name dari order (e.g., "PT Service Jaya")
- ✅ Tampil koordinat provider (lat, lng dengan 6 decimal)
- ✅ SnackBar hilang setelah 3 detik
- ✅ Marker glow effect visible

### 4. Zoom Controls
**Scenario:** Test zoom in/out functionality
**Steps:**
1. Lihat peta tracking
2. Tap tombol "+" (zoom in button) di sudut kanan bawah
3. Lihat peta zoom in
4. Tap tombol "-" (zoom out button)
5. Lihat peta zoom out
6. Pinch zoom on map juga harus berfungsi

**Expected Results:**
- ✅ Zoom in button zoom level naik (max 18)
- ✅ Zoom out button zoom level turun (min 5)
- ✅ Zoom buttons responsif dan immediate
- ✅ Pinch gesture on map juga berfungsi
- ✅ Zoom level constraints respected (5-18)

### 5. Pan & Drag
**Scenario:** Test pan/drag map functionality
**Steps:**
1. Lihat peta tracking
2. Drag/pan peta ke arah atas, bawah, kiri, kanan
3. Verify peta bisa dipindahkan

**Expected Results:**
- ✅ Peta bisa di-drag dengan smooth
- ✅ Map center berubah sesuai drag
- ✅ Pan acceleration berfungsi
- ✅ Tidak ada jitter atau lag

### 6. Auto-Refresh (Real-time Update)
**Scenario:** Verifikasi lokasi provider auto-update dari backend
**Steps:**
1. Buka order detail page
2. Lihat provider marker position
3. Update provider location dari provider app (atau manual via API)
4. Wait 5 detik
5. Lihat provider marker bergerak ke lokasi baru

**Expected Results:**
- ✅ Provider marker bergerak smooth ke lokasi baru
- ✅ Update timestamp berubah (e.g., "Diperbarui 2 detik lalu")
- ✅ Route line update ke lokasi provider baru
- ✅ Auto-update terjadi setiap 5 detik
- ✅ Movement smooth dengan animation

### 7. No Location Available
**Scenario:** Order tanpa lokasi provider
**Steps:**
1. Buka order yang belum diterima provider (provider_latitude/longitude NULL)
2. Scroll ke "Tracking Lokasi" section

**Expected Results:**
- ✅ Placeholder view ditampilkan (bukan peta)
- ✅ Icon location_off ditampilkan
- ✅ Text: "Lokasi belum tersedia"
- ✅ Subtitle: "Provider belum memulai pelacakan lokasi"

### 8. Memory & Performance
**Scenario:** Navigate in/out dari tracking page
**Steps:**
1. Buka order detail page
2. Scroll to tracking section (streams start)
3. Navigate away (back/close)
4. Check memory leak
5. Re-open order detail page
6. Verify no duplicate streams

**Expected Results:**
- ✅ No memory leaks saat navigate away
- ✅ Streams di-cancel properly
- ✅ Re-opening page tidak create duplicate subscriptions
- ✅ App performance tetap smooth

## Manual Testing Script

### Test 1: Basic Display
```bash
1. Open app
2. Login sebagai customer
3. Tap order dengan status "ACCEPTED" atau lebih lanjut
4. Scroll ke "Tracking Lokasi"
5. Verify: Map + markers + legend visible
```

### Test 2: Update Provider Location
```bash
# Via provider app atau backend:
1. Provider login
2. Go to "Layanan Saya" -> "Lokasi Provider"
3. Tap "Perbarui Lokasi"
4. Select new location via map picker
5. Wait ~5 detik
6. Go back ke customer app
7. Refresh order detail (pull to refresh atau reopen)
8. Verify: Provider marker moved to new location
```

### Test 3: Stress Test
```bash
1. Open order detail with tracking
2. Repeatedly open/close the detail page (10x)
3. Monitor device memory (should not continuously increase)
4. Monitor CPU usage (should be low when idle)
5. Tap markers multiple times
6. Zoom in/out rapidly
7. Pan rapidly
8. Verify: No crashes, smooth performance
```

## API Response Verification

### Check Order Response Format

```bash
curl -H "Authorization: Bearer {token}" \
  http://localhost:8000/api/orders/{orderId}
```

**Expected Response:**
```json
{
  "data": {
    "id": 1,
    "order_code": "ORD-2026-001",
    "status": "ON_PROGRESS",
    "address": "Jl. Example No. 123",
    "customer_latitude": -6.1234567,
    "customer_longitude": 106.5678901,
    "provider_latitude": -6.1250123,
    "provider_longitude": 106.5700456,
    "provider": {
      "id": 1,
      "name": "John Doe",
      "full_name": "PT Service Jaya"
    },
    "payments": [...],
    "attachments": [...],
    "statusLogs": [...],
    "finalPriceApproval": {...}
  },
  "message": "Order retrieved"
}
```

**Verification Checklist:**
- ✅ provider.full_name present
- ✅ customer_latitude/longitude present
- ✅ provider_latitude/longitude present
- ✅ All fields are numeric for coordinates

## Browser DevTools Inspection

### Network Tab
- Monitor API calls ke `/api/orders/{orderId}`
- Verify auto-refresh requests setiap 5 detik
- Check response time < 1 detik
- Verify no 5xx errors

### Console Tab
- Check for JavaScript errors
- Verify no warnings tentang memory leaks
- Check for null/undefined reference errors

### Performance Tab
- Record performance timeline
- Verify smooth 60 FPS when panning
- Check CPU/Memory usage
- Identify bottlenecks jika ada

## Dart DevTools Inspection

### Memory Profiler
```bash
1. Connect Flutter app ke DevTools
2. Open Memory profiler
3. Take heap snapshot sebelum open tracking page
4. Open tracking page
5. Take heap snapshot setelah 10 detik
6. Verify memory tidak naik secara signifikan
7. Navigate away
8. Take heap snapshot lagi
9. Verify memory kembali ke baseline
```

### Timeline Tab
- Monitor frame rendering
- Verify jambatan render time < 16ms
- Check untuk jank atau frame drops

## Regression Testing

Setelah perubahan ini, verify:

- ✅ Order list page still works
- ✅ Other order details sections not affected
- ✅ Order creation still works
- ✅ Provider location update still works
- ✅ No navigation bugs introduced
- ✅ App startup time not increased
- ✅ Other features performance not degraded

## Known Limitations & Workarounds

### Limitation 1: OpenStreetMap Tile Loading Slow
**Issue:** OSM tiles loading lambat di area tertentu
**Workaround:** Use offline maps atau alternate tile provider
**Code:**
```dart
// Alternate tile providers
const String osmTile = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String cartoDB = 'https://{s}.basemaps.cartocdn.com/positron/{z}/{x}/{y}{r}.png';
const String esri = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
```

### Limitation 2: Real-time Update Delay
**Issue:** Auto-refresh hanya polling setiap 5 detik
**Workaround:** Implement WebSocket untuk true real-time
**Future Improvement:**
```dart
// TODO: Replace Stream.periodic dengan WebSocket
// ws://backend/api/orders/{orderId}/track
```

### Limitation 3: No Historical Route
**Issue:** Tidak menampilkan riwayat perjalanan
**Workaround:** Simpan semua lokasi historis di local DB
**Future Improvement:**
```dart
// TODO: Tambah historical route polyline
// Fetch dari backend: GET /api/orders/{orderId}/location-history
```

## Bug Report Template

Jika menemukan bug:

```markdown
## Title
[Brief description]

## Steps to Reproduce
1. Step 1
2. Step 2
3. ...

## Expected Result
[What should happen]

## Actual Result
[What actually happens]

## Device Info
- Device: [e.g., iPhone 12, Samsung S21]
- OS: [e.g., iOS 14.5, Android 11]
- App Version: [e.g., 1.0.0]
- Backend Version: [e.g., 1.0.0]

## Logs
[Paste relevant logs/errors]

## Screenshots/Videos
[Attach if possible]
```

## Success Criteria

✅ **All tests passed** = Feature ready for production

Minimum criteria:
- ✅ All display tests passed
- ✅ All interaction tests passed (markers, zoom, pan)
- ✅ Auto-refresh works correctly
- ✅ No memory leaks
- ✅ No crashes
- ✅ Performance acceptable (60 FPS)
- ✅ All API responses correct format
- ✅ No regressions on other features

---
**Last Updated:** 2026-07-15
**Status:** Ready for Testing
**Tested By:** [Your Name]

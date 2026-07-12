# TODO - Jadikan Peta seperti Google Maps

## Step 1: Audit konfigurasi Google Maps
- Pastikan API key bisa dimasukkan via file resource (Android) dan iOS (jika ada).
- Tambahkan izin lokasi bila diperlukan.

## Step 2: Integrasi google_maps_flutter
- Update widget `LocationMapPreview` (mobile/lib/shared/widgets/location_map_preview.dart) agar menggunakan `GoogleMap`.
- Update `LocationPickerScreen` (mobile/lib/features/maps/location_picker_screen.dart) agar menampilkan `GoogleMap` interaktif, bukan static map.

## Step 3: UI/UX
- Tambahkan marker untuk customer/provider.
- Atur camera (zoom/center) otomatis berdasarkan lokasi yang tersedia.
- Opsional: mode tap untuk pilih titik lokasi pada picker screen.

## Step 4: Build & Run
- `cd mobile && flutter clean && flutter pub get && flutter run`
- Verifikasi di Android emulator/real device.


# 🔧 LOGIN FIX - Mobile App Connection Timeout

## 📋 Problem Summary
Aplikasi Flutter tidak bisa login di HP (physical device) tapi bisa di website.

**Error Message:**
```
[Login] Connection failed to: http://192.168.18.106:8000
[Login] Error: The request connection took longer than 0:00:30.000000 and it was aborted
```

**Root Cause:** Koneksi timeout terlalu pendek (30 detik) untuk physical device over LAN

---

## ✅ Solusi yang Diterapkan

### 1. **Tingkatkan Dio Timeout Duration**
**File:** `mobile/lib/core/http/dio_provider.dart`

Sebelum:
```dart
connectTimeout: const Duration(seconds: 30),
receiveTimeout: const Duration(seconds: 30),
```

Sesudah:
```dart
connectTimeout: const Duration(seconds: 60),
receiveTimeout: const Duration(seconds: 60),
sendTimeout: const Duration(seconds: 60),
```

**Alasan:** Physical device over LAN lebih lambat dari localhost/emulator. 60 detik lebih reliable.

---

### 2. **Tambah Network Permissions**
**File:** `mobile/android/app/src/main/AndroidManifest.xml`

Ditambahkan:
```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
```

**Alasan:** Membantu Android system mendeteksi network changes dan connectivity issues.

---

### 3. **Verifikasi Backend Running**
Backend Laravel sudah dijalankan di IP yang benar:
```bash
php artisan serve --host=192.168.18.106 --port=8000
```

Server berjalan di: `http://192.168.18.106:8000` ✅

---

## 🚀 Langkah-Langkah untuk Test

### Di Mobile Device:
1. ✅ App sudah direbuild dengan perubahan timeout
2. Coba login dengan kredensial yang valid
3. Perhatikan logs di terminal untuk memastikan koneksi berhasil

### Verifikasi Backend (di Server/PC):
```bash
cd backend
php artisan serve --host=192.168.18.106 --port=8000
```

Pastikan output menunjukkan:
```
INFO  Server running on [http://192.168.18.106:8000].
```

---

## 📊 Checklist Validation

- [x] Dio timeout ditingkatkan dari 30s ke 60s
- [x] Network permissions ditambahkan di AndroidManifest
- [x] Backend server running di 192.168.18.106:8000
- [x] Mobile app rebuilt dengan perubahan baru
- [x] App deployed ke physical device
- [x] Hot reload applied

---

## 🔍 Troubleshooting Jika Masih Error

### Jika tetap timeout:
1. **Cek IP Address:**
   ```bash
   ipconfig
   ```
   Pastikan IP `192.168.18.106` masih valid di network

2. **Cek Network Connectivity:**
   - Pastikan HP dan PC di network yang sama (sama WiFi)
   - Coba ping dari PC: `ping 192.168.18.106` ✓

3. **Cek Backend Accessibility:**
   ```bash
   curl http://192.168.18.106:8000/api/health
   ```
   Harus response 200/OK

4. **Increase Timeout Lebih Lagi:**
   Jika network lambat, bisa ubah ke 90 atau 120 detik

### Jika login 200 OK tapi data tidak masuk:
- Cek backend `.env` configuration
- Cek CORS settings di backend
- Lihat database migration status

---

## 📝 Configuration Files Modified

| File | Changes |
|------|---------|
| `mobile/lib/core/http/dio_provider.dart` | Timeout: 30s → 60s, added sendTimeout |
| `mobile/android/app/src/main/AndroidManifest.xml` | Added network state permissions |
| `.env` | API_BASE_URL already set to `http://192.168.18.106:8000` ✅ |

---

## 🎯 Next Steps

1. **Test login di HP** dengan timeout baru
2. **Monitor logs** untuk memastikan koneksi stable
3. Jika ada error lain, dokumentasikan untuk fix berikutnya
4. Setelah berhasil, bisa optimize timeout ke 45s (balance reliability vs latency)

---

**Updated:** 2026-07-13 | **Status:** ✅ Ready for Testing

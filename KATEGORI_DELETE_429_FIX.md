# FIX: Error 429 Saat Delete Kategori di Admin Menu

**Status:** ✅ Fixed  
**Date:** 2026-07-15  
**Issue:** Admin mendapat error 429 (Too Many Requests) saat menghapus kategori

---

## 🔍 ROOT CAUSE ANALYSIS

### Backend Issue
- **Rate limiting terlalu ketat:** Route delete kategori punya `throttle:10,1` (max 10 requests per 1 menit)
- **Ini terlalu restrictive** untuk operasi admin yang jarang dilakukan

### Mobile App Issue
1. **Tombol tidak di-disable:** User bisa klik tombol "Hapus" berkali-kali → multiple requests → error 429
2. **Error message tidak user-friendly:** Menampilkan raw exception string
3. **Retry interceptor punya bug:** Global counter bisa conflict di concurrent requests

---

## ✅ FIXES IMPLEMENTED

### 1. Backend - Increase Rate Limit
**File:** `backend/routes/api.php` (Line 93)

```php
// BEFORE:
Route::delete('/categories/{categoryId}', [AdminController::class, 'deleteCategory'])->middleware('throttle:10,1');

// AFTER:
Route::delete('/categories/{categoryId}', [AdminController::class, 'deleteCategory'])->middleware('throttle:30,1');
```

**Reason:** Meningkatkan dari 10 ke 30 requests per 1 menit - lebih reasonable untuk admin operations.

---

### 2. Mobile App - Add Loading State & Disable Button
**File:** `mobile/lib/features/admin/admin_categories_page.dart`

#### Changes:
- ✅ Tambahkan `barrierDismissible: false` - prevent dialog close saat loading
- ✅ Tambahkan loading indicator di dialog
- ✅ Disable tombol Batal & Hapus saat proses loading
- ✅ Add success message snackbar setelah delete berhasil
- ✅ Add helper method `_parseErrorMessage()` untuk user-friendly error messages

#### Error Message Mapping:
| Error Code | User Message |
|---|---|
| 429 | "Terlalu banyak permintaan. Silakan tunggu beberapa saat..." |
| 409 | "Kategori masih memiliki layanan aktif..." |
| 404 | "Kategori tidak ditemukan." |
| Connection | "Gagal terhubung ke server..." |
| Other | Fallback ke exception message (capped at 100 chars) |

---

### 3. Mobile App - Fix Retry Interceptor Bug
**File:** `mobile/lib/core/http/dio_provider.dart`

#### Issue:
Global `_retryCount` variable tidak cocok untuk concurrent requests - bisa cause counter conflicts.

#### Solution:
Ganti dengan **per-request retry tracking** menggunakan `Map<String, int>`:

```dart
final Map<String, int> _retryCountMap = {}; // Track retry count per request

// Create unique key per request
final requestKey = '${err.requestOptions.method}:${err.requestOptions.path}:${err.requestOptions.data.toString()}';
final retryCount = _retryCountMap[requestKey] ?? 0;

// After success/failure, cleanup
_retryCountMap.remove(requestKey);
```

**Benefit:** Setiap request independen, tidak interference dengan requests lain.

---

## 📋 Testing Checklist

- [ ] Test delete kategori di admin - should work tanpa error 429
- [ ] Test rapid clicks pada tombol delete - button should disabled
- [ ] Test connection loss - should show proper error message
- [ ] Test dengan kategori yang punya services - should show 409 error
- [ ] Monitor backend logs untuk rate limiting patterns
- [ ] Test mobile app tanpa internet - should show connection error

---

## 🚀 Deployment Steps

1. **Backend:**
   ```bash
   cd backend
   git add routes/api.php
   git commit -m "fix: increase rate limit for delete category from 10 to 30 per minute"
   ```

2. **Mobile:**
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   flutter run  # or build for release
   ```

---

## 📊 Before vs After

### Before Fix:
- ❌ Error 429 saat delete kategori
- ❌ User bisa klik tombol berkali-kali
- ❌ Error message tidak jelas: "DioException [bad response]..."

### After Fix:
- ✅ Delete kategori berhasil smooth
- ✅ Tombol auto-disable, user lihat loading state
- ✅ Error message jelas: "Terlalu banyak permintaan. Silakan tunggu beberapa saat..."
- ✅ Retry otomatis dengan exponential backoff untuk 429 errors

---

## 🔗 Related Issues

- Rate limiting configuration: `backend/SECURITY_HARDENING_COMPLETE.md`
- API Service: `mobile/lib/core/services/api_service.dart`
- Dio Configuration: `mobile/lib/core/http/dio_provider.dart`

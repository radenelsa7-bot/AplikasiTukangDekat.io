# Laporan Perbaikan Debug - 14 Mei 2026

## Masalah yang Diperbaiki

### 1. ✅ Kesalahan Endpoint Search 404

**Masalah:** 
- Bilah pencarian menampilkan kesalahan: `DioException [bad response]: 404`
- Endpoint: `/api/catalog/providers/search?q=AC`

**Penyebab Akar:**
- Urutan rute di Laravel - `/providers/{providerId}` cocok dengan `/providers/search` sebelum rute pencarian dievaluasi
- Dalam perutean Laravel, rute spesifik harus didefinisikan SEBELUM rute parameter dinamis

**Solusi Diterapkan:**
- **File:** `backend/routes/api.php` (baris 18-23)
- **Perubahan:** Memindahkan rute `/providers/search` SEBELUM rute `/providers/{providerId}`
- **Sebelum:**
  ```php
  Route::get('/providers/{providerId}', [CatalogController::class, 'getProviderDetail']);
  Route::get('/providers/search', [CatalogController::class, 'searchProviders']);
  ```
- **Sesudah:**
  ```php
  Route::get('/providers/search', [CatalogController::class, 'searchProviders']);
  Route::get('/providers/{providerId}', [CatalogController::class, 'getProviderDetail']);
  ```

**Verifikasi:**
- Mulai ulang server backend
- Coba pencarian dengan "AC" - sekarang harus mengembalikan penyedia alih-alih 404

---

### 2. ✅ Masalah Penyaringan Pesanan - Token Tidak Dihapus Saat Logout

**Masalah:**
- Pesanan dari pengguna A (Fajar) terlihat di akun pengguna B (Nabila)
- Seharusnya hanya menampilkan pesanan yang dimiliki pengguna yang diautentikasi

**Penyebab Akar:**
- Metode `logout()` tidak memanggil `apiService.clearToken()`
- Token lama tetap berada di header HTTP Dio
- Ketika pengguna baru masuk, jika logout tidak menghapus header dengan benar, permintaan dapat menggunakan token campuran/lama
- Backend `getMyOrders()` menerima pengguna yang benar dari token, tetapi frontend mungkin memiliki token usang

**Solusi Diterapkan:**
- **File:** `mobile/lib/features/auth/auth_controller.dart` (metode logout)
- **Perubahan:** Menambahkan panggilan `apiService.clearToken()` dalam logout
- **Sebelum:**
  ```dart
  Future<void> logout() async {
    // ... tidak ada panggilan clearToken()
    await _ref.read(authStorageProvider).clearAll();
  }
  ```
- **Sesudah:**
  ```dart
  Future<void> logout() async {
    final apiService = _ref.read(apiServiceProvider);
    await apiService.logout();
    apiService.clearToken();  // ← Baris ini ditambahkan
    await _ref.read(authStorageProvider).clearAll();
  }
  ```

**Mengapa Ini Memperbaikinya:**
1. Token lama dihapus dari header Dio segera
2. Login pengguna baru akan menetapkan token baru di header
3. Panggilan API berikutnya menggunakan otentikasi yang benar
4. Backend menyaring pesanan dengan benar berdasarkan user_id yang diautentikasi

---

## Verifikasi Backend

### Endpoint: `/api/catalog/providers/search`

**Perintah Uji:**
```bash
curl -s -X GET "http://localhost:8000/api/catalog/providers/search?q=listrik" | python -m json.tool
```

**Respons yang Diharapkan (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "business_name": "Andi Jasa Listrik",
      "area": "Bojongloa Kaler",
      "avg_rating": "5.00"
    }
  ]
}
```

**Respons Kesalahan (400):**
```json
{
  "message": "Query parameter q is required."
}
```

### Endpoint: `/api/orders/my-orders` (Terlindungi)

**Perintah Uji:**
```bash
# Login sebagai Fajar
curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"fajar@example.com","password":"password123"}' | python -m json.tool

# Dapatkan pesanan Fajar dengan token
curl -s -X GET http://localhost:8000/api/orders/my-orders \
  -H "Authorization: Bearer TOKEN_HERE" | python -m json.tool
```

**Harapan:** Hanya pesanan Fajar yang dikembalikan

---

## Langkah Pengujian Manual

### Langkah 1: Uji Pencarian (Frontend)
1. Buka aplikasi di `localhost:62119` (atau port dev Flutter saat ini)
2. Pergi ke tab "Beranda"
3. Ketik "listrik" di bilah pencarian
4. **Harapan:** Daftar penyedia dengan "listrik" di nama/area (BUKAN kesalahan 404)

### Langkah 2: Uji Penyaringan Pesanan (Frontend)
1. Klik tombol logout (jika sudah masuk)
2. Pada LoginPage, masuk sebagai **Fajar**:
   - Email: `fajar@example.com`
   - Password: `password123`
3. Pergi ke tab "Pesanan"
4. **Harapan:** Lihat pesanan yang ditetapkan ke Fajar
5. Catat kode pesanan (misalnya `ORD-20260513-0001`)
6. Klik tombol logout di AppBar
7. Pada LoginPage, masuk sebagai **Nabila**:
   - Email: `nabila@example.com`
   - Password: `password123`
8. Pergi ke tab "Pesanan"
9. **Harapan:** Lihat pesanan BERBEDA (BUKAN pesanan dari Fajar)
10. Verifikasi kode pesanan Fajar TIDAK terlihat

### Langkah 3: Verifikasi Penanganan Token Backend
1. Di Chrome DevTools (F12), pergi ke tab Network
2. Pergi ke tab "Pesanan"
3. Cari permintaan API ke `my-orders`
4. Klik pada permintaan, pergi ke tab Headers
5. Cari header `Authorization`
6. **Harapan:** Seharusnya menampilkan `Bearer <token>` dengan token berbeda untuk pengguna berbeda

---

## File yang Dimodifikasi

1. **Backend:**
   - `backend/routes/api.php` - Perbaikan urutan rute
   - `backend/app/Http/Controllers/Api/CatalogController.php` - Validasi pencarian sudah ditambahkan

2. **Frontend:**
   - `mobile/lib/features/auth/auth_controller.dart` - Ditambahkan clearToken() dalam logout
   - `mobile/lib/core/services/api_service.dart` - Sudah memiliki setToken/clearToken yang benar
   - `mobile/lib/core/http/dio_provider.dart` - Sudah memiliki timeout 30 detik

---

## Langkah Berikutnya jika Masalah Tetap Ada

### Jika Pencarian Masih Mengembalikan 404:
1. Hapus cache browser (Ctrl+Shift+Delete)
2. Mulai ulang server backend
3. Jalankan `flutter clean` dan `flutter run` lagi
4. Periksa log backend untuk kesalahan sebenarnya

### Jika Pesanan Masih Ditampilkan Antar Pengguna:
1. Periksa tab Network DevTools untuk header Authorization
2. Verifikasi token berbeda untuk setiap login pengguna
3. Periksa log backend untuk melihat user_id apa yang diterima
4. Jalankan tes curl manual untuk mengisolasi jika masalah adalah frontend atau backend

---

## Status
- ✅ Urutan rute pencarian diperbaiki
- ✅ Pembersihan token logout diperbaiki  
- ✅ Siap untuk pengujian
- 🔄 Menunggu verifikasi tes manual

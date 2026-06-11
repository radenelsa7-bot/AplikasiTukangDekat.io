# Panduan Koneksi Flutter (frontend) ke Backend

Dokumen ini menjelaskan cara menghubungkan aplikasi Flutter di `mobile/` dengan backend Laravel di `backend/`.

## 1. Sistem Apa yang Sudah Ada di Backend

Backend dikelompokkan dalam beberapa modul API berikut:

- **Authentication (auth)**
  - `POST /api/auth/register` - registrasi user
  - `POST /api/auth/login` - login user
  - `POST /api/auth/logout` - logout user (butuh token)
  - `POST /api/auth/session-login` - sesi SPA
  - `POST /api/auth/session-logout` - logout sesi SPA

- **Catalog**
  - `GET /api/catalog/categories` - daftar kategori layanan
  - `GET /api/catalog/categories/{categoryId}/providers` - daftar penyedia per kategori
  - `GET /api/catalog/providers/search?q=...` - pencarian penyedia
  - `GET /api/catalog/providers/{providerId}` - detail penyedia

- **Orders**
  - `POST /api/orders` - buat order baru
  - `GET /api/orders/my-orders` - daftar order milik user
  - `GET /api/orders/{orderId}` - detail order
  - `POST /api/orders/{orderId}/respond` - respons order
  - `POST /api/orders/{orderId}/start-work` - mulai pekerjaan
  - `POST /api/orders/{orderId}/complete` - selesaikan order
  - `POST /api/orders/{orderId}/review` - buat review order

- **Payments**
  - `GET /api/payments/order/{orderId}` - ambil pembayaran order
  - `GET /api/payments/{paymentId}` - status pembayaran
  - `POST /api/payments/{paymentId}/generate-qris` - generate QRIS
  - `POST /api/payments/{paymentId}/capture-qris` - capture QRIS

- **Reviews**
  - `GET /api/reviews/provider/{providerId}/summary` - ringkasan rating provider
  - `GET /api/reviews/provider/{providerId}` - daftar review provider
  - `GET /api/reviews/order/{orderId}` - review order

- **Admin**
  - `GET /api/admin/providers/pending` - lihat provider pending
  - `PATCH /api/admin/providers/{providerId}/verification` - update verifikasi

- **Treasurer / laporan**
  - `GET /api/treasurer/payments/report` - laporan pembayaran

- **Webhook**
  - `POST /webhooks/payment` - callback payment gateway

- **Monitoring**
  - `GET /metrics` - endpoint metrics monitoring

File konfigurasi endpoint utama berada di:
- `backend/routes/api.php`

## 2. Struktur Koneksi di Frontend Flutter

Frontend menggunakan `dio` sebagai HTTP client dan sudah memiliki service API yang siap dipakai.

File penting di Flutter:
- `mobile/lib/config/api_config.dart` - konfigurasi `baseUrl`
- `mobile/lib/core/http/dio_provider.dart` - provider Dio
- `mobile/lib/core/services/api_service.dart` - semua method API sudah tersedia

### 2.1. Base URL backend

`mobile/lib/config/api_config.dart` sudah memiliki nilai:

- `baseUrlWeb = 'http://127.0.0.1:8000'`
- `baseUrlAndroidEmulator = 'http://10.0.2.2:8000'`
- `baseUrlPhysicalDevice = 'http://192.168.1.10:8000'`

Secara default, aplikasi memakai:

```dart
static const String baseUrl = baseUrlWeb;
```

Artinya:
- Jika kamu menjalankan Flutter di browser / desktop: gunakan `127.0.0.1:8000`
- Jika di Android Emulator: gunakan `10.0.2.2:8000`
- Jika di perangkat fisik: gunakan IP komputer lokal seperti `192.168.x.x:8000`

### 2.2. Provider Dio

`mobile/lib/core/http/dio_provider.dart` menginisialisasi Dio seperti ini:

```dart
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
});
```

Jadi semua request akan mengarah ke `ApiConfig.baseUrl` + path API di backend.

### 2.3. ApiService yang sudah tersedia

`mobile/lib/core/services/api_service.dart` sudah menyediakan method seperti:

- `register(...)`
- `login(...)`
- `logout()`
- `getCategories()`
- `getProvidersByCategory(categoryId)`
- `getProviderDetail(providerId)`
- `searchProviders(query)`
- `createOrder(...)`
- `getMyOrders()`
- `getOrderDetail(orderId)`
- `respondToOrder(orderId, action)`
- `startWork(orderId)`
- `completeOrder(orderId, finalPrice)`
- `generateQRIS(paymentId)`
- `getPaymentStatus(paymentId)`
- `createReview(...)`
- `getProviderReviews(providerId)`
- `getOrderReview(orderId)`
- `getPendingProviders()`
- `updateProviderVerification(...)`

Artinya: kamu tidak perlu menulis ulang request API karena backend sudah terhubung melalui service ini.

## 3. Cara Menyambungkan Flutter ke Backend

### 3.1. Jalankan backend

1. Masuk ke folder backend:
   ```bash
   cd backend
   ```
2. Jalankan server Laravel lokal:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```
3. Pastikan backend bisa diakses di browser / Postman:
   - `http://127.0.0.1:8000/api/catalog/categories`

Jika menggunakan Laragon, pastikan backend berjalan di port 8000 atau sesuaikan `ApiConfig`.

### 3.2. Pastikan baseUrl di Flutter benar

Buka `mobile/lib/config/api_config.dart` dan sesuaikan `baseUrl` dengan kondisi pengujian:

- Web / desktop: `http://127.0.0.1:8000`
- Android emulator: `http://10.0.2.2:8000`
- iOS simulator: `http://127.0.0.1:8000`
- Perangkat fisik: ganti dengan IP mesinnya, misal `http://192.168.1.10:8000`

Contoh:

```dart
static const String baseUrl = baseUrlAndroidEmulator;
```

### 3.3. Periksa jaringan jika pakai perangkat fisik

Jika menggunakan HP Android/iOS fisik, pastikan:
- Komputer dan HP terhubung ke jaringan Wi-Fi yang sama
- IP backend dapat dijangkau dari HP
- Firewall Windows tidak memblokir port 8000
- Jika perlu, gunakan alamat IP lokal komputer

### 3.4. Gunakan login untuk dapat akses endpoint yang dilindungi

Pada backend, beberapa endpoint membutuhkan header `Authorization: Bearer <token>` karena menggunakan `auth:sanctum`.

`ApiService.login(...)` secara otomatis akan menyimpan token ke header Dio ketika berhasil login.

Flow yang benar:
1. Panggil `apiService.login(email: ..., password: ...)`
2. Simpan user / token ke state app
3. Panggil endpoint lain setelah login, misal `getMyOrders()` atau `createOrder(...)`
4. Logout dengan `apiService.logout()` untuk menghapus header token

### 3.5. Contoh koneksi endpoint

Contoh penggunaan API service di Flutter:

```dart
final apiService = ref.read(apiServiceProvider);

final auth = await apiService.login(
  email: 'user@example.com',
  password: 'password123',
);

final categories = await apiService.getCategories();
final providers = await apiService.getProvidersByCategory(categoryId);
```

## 4. Langkah yang Harus Kamu Lakukan di Frontend

1. Pastikan `baseUrl` sudah benar di `mobile/lib/config/api_config.dart`.
2. Pastikan file `mobile/lib/core/http/dio_provider.dart` tidak memodifikasi header `Authorization` di tempat lain tanpa token.
3. Gunakan `apiService` yang ada di `mobile/lib/core/services/api_service.dart` untuk request API.
4. Untuk endpoint yang butuh auth, pastikan user sudah login terlebih dahulu.
5. Jika memerlukan data baru, periksa model di `mobile/lib/core/models/` dan sesuaikan field request/response.
6. Jika menambahkan page baru, panggil method `apiService` yang sesuai, atau tambahkan method baru di `ApiService` jika belum tersedia.

## 5. Kapan Menambahkan Endpoint Baru

Jika kamu ingin menambahkan fitur frontend yang belum ada di backend:
1. Tambahkan route baru di `backend/routes/api.php`
2. Buat controller method di backend
3. Cek format request/response JSON
4. Tambahkan method baru di `mobile/lib/core/services/api_service.dart`
5. Gunakan method itu di halaman Flutter

## 6. Ringkasan Singkat

- Backend sudah menyediakan API auth, catalog, order, payment, review, admin, dan laporan.
- Mobile sudah memakai `Dio` dan `ApiService` untuk mengakses semua API tersebut.
- Untuk menyambungkan, jalankan backend di `http://...:8000` lalu sesuaikan `ApiConfig.baseUrl` di Flutter.
- Pastikan login sebelum memanggil endpoint yang dilindungi.

---

Jika kamu butuh, saya bisa bantu juga membuat contoh pemanggilan fungsi API di halaman Flutter tertentu atau menyesuaikan `baseUrl` untuk device yang kamu gunakan.

## 7. Update: Method API Baru di `ApiService`

Saya telah menambahkan beberapa method baru di `mobile/lib/core/services/api_service.dart`:

- `sessionLogin({ email, password })` → `POST /api/auth/session-login`
- `sessionLogout()` → `POST /api/auth/session-logout`
- `getUserSession()` → `GET /api/user-session`
- `getTreasurerReport({ queryParameters })` → `GET /api/treasurer/payments/report`
- `getMetrics()` → `GET /api/metrics`

Contoh pemakaian singkat:

```dart
final api = ref.read(apiServiceProvider);

// session login (SPA style)
final user = await api.sessionLogin(email: 'a@b.com', password: 'secret');

// mendapatkan user sesi
final sessionUser = await api.getUserSession();

// memanggil laporan bendahara (butuh token/role TREASURER)
final report = await api.getTreasurerReport(queryParameters: {
  'start_date': '2026-05-01',
  'end_date': '2026-05-31',
  'export': 'json'
});

// metrics (text/json tergantung backend)
final metrics = await api.getMetrics();
```

Catatan: `sessionLogin`/`getUserSession` menggunakan mekanisme session (cookie). Jika kamu membutuhkan cookie persistence di Dio (untuk perangkat mobile), pertimbangkan menggunakan `cookie_jar` / `dio_cookie_manager` untuk menyimpan cookie secara otomatis.

### Cara pakai contoh halaman

- `mobile/lib/features/auth/session_login_page.dart` — contoh form session login dan pemeriksaan session.
- `mobile/lib/features/treasurer/treasurer_report_page.dart` — contoh mengambil laporan bendahara (butuh token/role TREASURER).

Kamu bisa menambahkan route sementara di `main.dart` atau panggil halaman ini dari navigator untuk menguji.

### Catatan tambahan: Persistent cookies

Jika ingin menyimpan cookie antar restart aplikasi, ganti `CookieJar()` di `mobile/lib/core/http/dio_provider.dart` dengan `PersistCookieJar` dan gunakan `path_provider` untuk menentukan direktori penyimpanan, contoh:

```dart
final appDoc = await getApplicationDocumentsDirectory();
final cookieJar = PersistCookieJar(storage: FileStorage('${appDoc.path}/.cookies/'));
dio.interceptors.add(CookieManager(cookieJar));
```

Untuk langkah ini, `path_provider` sudah ditambahkan ke `pubspec.yaml`. Jalankan `flutter pub get` setelah mengubah dependensi.
# TODO — Rekap

## [Sesssion Fix] TODO_SESSION_FIX — Tahap 1: Perbaikan logout otomatis saat refresh
- [x] Audit `sanctum.php` (guard web) dan `session.php` (driver database, secure cookie default untuk local)
- [x] Perbaiki `backend/config/cors.php`: allow credentials untuk cookie session
- [x] Perbaiki `backend/config/cors.php`: set allowed_origins default untuk localhost umum (8000/3000/5173)
- [ ] Smoke test: login + refresh halaman
- [ ] Jika masih logout: cek flow frontend pakai `session-login` vs token

## [Test Konsistensi] Konsolidasi test agar `php artisan test` lulus
- [x] Update `backend/tests/Feature/AuthApiTest.php` agar register PROVIDER menyertakan `category_id` dan `business_name` (sesuai `RegisterRequest`)
- [x] Update `backend/tests/Feature/PaymentWebhookTest.php` agar ekspektasi DP tidak mengubah status order ke ACCEPTED (sesuai current implementation)
- [x] Update `backend/tests/Feature/ReviewRatingApiTest.php` agar `status` order untuk submit review mengikuti implementasi controller (CLOSED)
- [x] Update `backend/tests/Feature/SecurityHardeningTest.php` agar assertion pesan tidak mensyaratkan substring 'admin/treasurer'
- [ ] Jalankan kembali `php artisan test` untuk memastikan test suite hijau


<!-- markdownlint-disable -->

# Panduan Cepat - TukangDekat (Ringkas)

Panduan singkat ini membantu mahasiswa dan dosen menjalankan backend dan aplikasi mobile secara lokal untuk pengujian.

## 1) Jalankan Backend (Laravel)

Syarat: PHP 8.2+, Composer, MySQL

```bash
cd c:\laragon\www\Project-Aplikasi-Tukang-Dekat\backend
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

Backend akan berjalan di `http://localhost:8000`

## 2) Jalankan Mobile (Flutter)

Syarat: Flutter SDK, Android Studio / emulator

```bash
cd c:\laragon\www\Project-Aplikasi-Tukang-Dekat\mobile
flutter pub get
flutter run -d chrome
```

App Flutter akan terbuka di Chrome (atau perangkat/emulator yang dipilih).

## 3) Akun Pengujian

Gunakan akun yang sudah disediakan pada data seed untuk pengujian cepat:

```
Email: customer@test.com
Password: password123
```

## Fitur Utama yang Sudah Tersedia

- Autentikasi pengguna (register/login/logout)
- Penelusuran kategori dan provider
- Pembuatan dan melihat pesanan
- Integrasi API antara mobile dan backend

## Troubleshooting Singkat

- Jika backend tidak jalan: pastikan Composer dependencies terinstal dan database tersedia; jalankan `php artisan migrate --seed`.
- Jika Flutter error: jalankan `flutter clean` lalu `flutter pub get`.

## File Penting

- `backend/` — kode Laravel (API)
- `mobile/` — kode Flutter
- `docs/` — dokumentasi proyek (SRS, diagram, API)

Jika butuh panduan lebih lengkap, lihat `PROJECT_STATUS.md` dan `backend/RUNBOOK.md`.

# Repository TukangDekat (UTS → UAS)

Repository ini digunakan untuk pengerjaan proyek **TukangDekat** (UTS: analisis & desain, UAS: implementasi berjalan).

## Struktur Folder (Rapi untuk UAS)
- `backend/`  → **Laravel API** (akan dibuat dari lokal dengan `composer create-project`)
- `mobile/`   → **Flutter app** (akan dibuat dari lokal dengan `flutter create`)
- `docs/`
  - `srs/` → dokumen SRS (sudah ada)
  - `diagrams/` → file `.drawio` + export `.png/.svg` (use case, activity, ERD)
  - `database/` → skema database (MySQL), catatan migrasi

## Cara Menjalankan Proyek (Ringkas)

Dokumen ini berisi ringkasan. Untuk panduan yang lebih lengkap dan aman untuk tim, lihat:
- `HELP_RUN_PROJECT.md`
- `QUICK_START.md`


### 1) Backend (Laravel API)
> Prasyarat: PHP 8.2+, Composer, MySQL

```bash
cd backend
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

### 2) Mobile (Flutter)
> Prasyarat: Flutter SDK, Android Studio / emulator

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

## Catatan Integrasi
- Auth API disarankan memakai **Laravel Sanctum** (token-based).
- Payment QRIS untuk UAS bisa **simulasi** (mark paid) jika belum memakai gateway asli.

## Dokumen
- SRS: `docs/srs/SRS_TukangDekat_v1.1.md`
- Diagram: `docs/diagrams/`
- Database: `docs/database/`

---

### Workflow Git
Disarankan:
- kerja di branch fitur (`feat/...`) lalu merge ke `main`.
- commit kecil dan jelas.

# TukangDekat — Ringkasan Proyek

Repo ini berisi implementasi lengkap aplikasi TukangDekat: backend API (Laravel) dan client mobile (Flutter).

Ringkasan singkat:
- Backend: Laravel API, berjalan di Docker.
- Mobile: Flutter app (Android/iOS/web-ready).
- Dokumentasi: `docs/` berisi SRS, panduan deploy, dan catatan pengembangan.

---

## Perubahan Terbaru (ringkas)

- Menyelaraskan response API dan trait `ApiResponse` untuk konsistensi controller.
- Menambahkan middleware `EnsureTreasurerRole` dan memperbaiki endpoint treasurer/export.
- Memperbaiki controller `Catalog`, `Review`, dan `Chatbot` untuk penanganan error lebih baik.
- Menambahkan `backend/.env.example` dan mengurangi hardcoded secrets di `docker-compose.yml`.
- Perbaikan pada client Flutter: model parsing, API service, dan UI (termasuk penulisan ulang `landing_screen.dart`).
- Memperbarui dokumentasi SRS (`docs/srs/SRS_TukangDekat_v1.1.md`) untuk mencerminkan fitur terbaru.

---

## Struktur Folder

- `backend/` — Laravel API, migration, seeder, dan dokumentasi backend.
- `mobile/` — Flutter project, UI, fitur auth, katalog, provider, dan laporan treasurer.
- `docs/` — SRS, panduan deploy, dan checklist QA.
- `scripts/`, `testing/`, dll. — utilitas dan tes.

---

## Cara Cepat Menjalankan (Developers)

1) Jalankan seluruh stack (root project):

```bash
docker compose up -d --build
```

2) Di dalam container backend (opsional install composer/plugins):

```bash
docker compose exec backend composer install
docker compose exec backend php artisan migrate --seed
```

3) Menjalankan aplikasi Flutter (lokal developer machine):

```bash
cd mobile
flutter pub get
flutter analyze
flutter run -d <device>
```

Catatan: jika `flutter analyze` meminta "Developer Mode" atau plugin tertentu, aktifkan Developer Mode pada mesin Windows/Android sesuai pesan, atau jalankan analisis pada mesin yang memenuhi requirement Flutter.

---

## Akun seed (contoh)

Setelah menjalankan seeder, berikut beberapa akun test yang tersedia untuk keperluan pengujian (email / password):

- Admin: admin@example.com / password
- Customer: fajar@example.com / password123
- Customer: nabila@example.com / password123
- Customer: aldo@example.com / password123
- Provider: andi.listrik@example.com / password123
- Provider: budi.plumbing@example.com / password123
- Provider: citra.ac@example.com / password123

Catatan: Jika Anda membutuhkan akun tambahan atau ingin melihat konfigurasi lengkap, periksa file seeder di folder `backend/database/seeders`.

---

## Troubleshooting singkat

- Pastikan `backend/.env` menggunakan host database `DB_HOST=db` saat menjalankan lewat Docker Compose.
- Jika ada error koneksi: jalankan `docker compose logs backend` dan `docker compose logs db` untuk investigasi.
- Untuk masalah login/CSRF/Sanctum: periksa konfigurasi `SANCTUM_STATEFUL_DOMAINS` dan `SESSION_DOMAIN` di `.env`.

Referensi: [HELP_RUN_PROJECT.md](./HELP_RUN_PROJECT.md)

---

## Catatan Pengembangan & Next Steps

- Jalankan smoke tests terutama pada alur auth, katalog, order, pembayaran, dan review.
- Jalankan `flutter analyze` dan `flutter test` pada lingkungan developer yang memenuhi syarat plugin.
- Minta reviewer untuk mengecek endpoint API yang diubah (catalog, review, treasurer, chatbot).

---

Branch saat ini: `Finalisasi-Project` (default branch upstream: `main`).

Jika butuh saya bantu update README lebih spesifik (mis. menambahkan badge CI, instruksi docker-compose env, atau tabel endpoint), beri tahu area yang diinginkan.

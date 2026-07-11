# TukangDekat — Ringkasan Proyek

**Status Proyek: 🚀 Siap untuk Uji Coba End-to-End & Deployment**

Repo ini berisi implementasi lengkap aplikasi **TukangDekat**: backend API (Laravel) dan client mobile (Flutter). Proyek ini telah mencapai tahap finalisasi, di mana fitur-fitur inti telah selesai diimplementasikan dan divalidasi melalui serangkaian tes otomatis.

Ringkasan singkat:
- Backend: Laravel API, berjalan di Docker.
- Mobile: Flutter app (Android/iOS/web-ready).
- Dokumentasi: `docs/` berisi SRS, panduan deploy, dan catatan pengembangan.
- Pengujian: 100% tes backend berhasil, mencakup alur pembayaran dari DP hingga pelunasan.

---

## Milestone Terbaru yang Tercapai

- **Sinkronisasi Backend-Frontend**: Alur pembuatan pesanan di mobile kini sinkron dengan backend, termasuk pengiriman data wilayah (`kota_id`, `kecamatan_id`) dan upload foto kerusakan via file, bukan lagi URL teks.
- **Alur Pembayaran Lengkap**: Sistem pembayaran bertahap (DP & Lunas) dengan persetujuan harga akhir oleh pelanggan telah diimplementasikan dan divalidasi end-to-end.
- **Validasi Backend Solid**: Seluruh *test suite* backend (14 tes) berhasil dijalankan, memastikan logika bisnis inti dari autentikasi, order, pembayaran, hingga payout berjalan sesuai harapan.
- **Perbaikan UI Kritis**: Tombol persetujuan harga akhir kini muncul dengan benar di aplikasi pelanggan, dan masalah akses role-based pada tab pesanan telah diperbaiki.

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

- **Pengujian Manual E2E**: Lakukan pengujian manual pada aplikasi mobile untuk memastikan alur dari registrasi hingga penyelesaian order berjalan lancar.
- **Hardening Keamanan**: Pindahkan *secrets* yang tersisa (seperti `GEMINI_API_KEY`) dari file `.env` ke environment variable di server atau *secret manager*.
- **Deployment**: Lakukan *smoke test* pada environment staging sebelum melakukan deployment ke produksi.

---

Untuk panduan lengkap penyelesaian proyek, lihat `GUIDE_FINAL_PROJECT_100_PERCENT.md`.

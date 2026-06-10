# Repository TukangDekat (UTS → UAS)

Repository ini digunakan untuk pengerjaan proyek **TukangDekat** (UTS: analisis & desain, UAS: implementasi berjalan penuh menggunakan arsitektur modern).

---

## 📁 Struktur Folder Proyek

Aplikasi ini menggunakan struktur *Monorepo* untuk menyatukan seluruh komponen sistem:

- `backend/` 🚀 → **Laravel 12 API** (Berjalan di dalam isolasi lingkungan Docker).
- `mobile/` 📱 → **Flutter App** (Aplikasi mobile multiplatform).
- `docs/` 📄 → Dokumen analisis sistem, termasuk SRS, dokumen perancangan, dan workflow.
- `scripts/` ⚡ → Kumpulan script otomatisasi pembantu development (seperti python converter).
- `testing/` 🧪 → Berkas pengujian unit test dan integrasi fitur.

---

## 🛠️ Cara Cepat Menjalankan Proyek (Quick Start)

Manajemen server backend dan database sekarang sepenuhnya menggunakan **Docker Compose**. Anda tidak perlu menginstal PHP, Composer, atau MySQL secara manual di sistem operasi host Anda.

> **Dokumen Panduan Lengkap:** Untuk langkah troubleshooting mendetail, integrasi endpoint API, dan konfigurasi environment antar-device, wajib membaca berkas utama: [HELP_RUN_PROJECT.md](./HELP_RUN_PROJECT.md).

### 1) Backend & Database (Docker)
Pastikan **Docker Desktop** Anda sudah aktif, lalu jalankan perintah berikut di root folder proyek:

```bash
# 1. Bangun dan nyalakan kontainer server di background
docker compose up -d --build

# 2. Unduh paket dependency Composer ke dalam kontainer
docker compose exec backend composer install

# 3. Jalankan migrasi database beserta data benih (seeder) awal
docker compose exec backend php artisan migrate --seed
```

## 🔧 Troubleshooting Login

Jika aplikasi Flutter/web menampilkan kesalahan login atau error koneksi database seperti:

- `SQLSTATE[HY000] [2002] Connection refused (Connection: mysql, Host: 127.0.0.1, Port: 3306, Database: db_tukangdekat)`
- `Login failed`

Maka kemungkinan besar backend tidak terkoneksi dengan container MySQL yang benar. Untuk kasus ini, perbaikan meliputi:

1. Mengubah `backend/.env` agar `DB_HOST=db` dan `DB_PASSWORD=rahasia`.
2. Mengubah service `backend` di `docker-compose.yml` agar menjalankan HTTP server:
   - `php artisan serve --host=0.0.0.0 --port=8000`
3. Membersihkan cache konfigurasi Laravel di dalam container:
   - `docker compose exec backend php artisan config:clear`
   - `docker compose exec backend php artisan optimize:clear`

Dokumentasi lengkap perbaikan tersedia di: [LOGIN_ERROR_FIX.md](./LOGIN_ERROR_FIX.md)

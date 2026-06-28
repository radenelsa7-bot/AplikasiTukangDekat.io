# Perbaikan Masalah Login TukangDekat

Dokumen ini menjelaskan langkah-langkah perbaikan masalah login ketika aplikasi Flutter/web tidak dapat mengakses backend Laravel lewat Docker.

## Permasalahan yang Ditemui

1. Aplikasi login menampilkan: `Login failed`.
2. Browser/Flutter menunjukkan error:
   - `SQLSTATE[HY000] [2002] Connection refused (Connection: mysql, Host: 127.0.0.1, Port: 3306, Database: db_tukangdekat)`
3. Backend berjalan tapi tidak memberikan respon API karena konfigurasi Docker/laravel tidak benar.

## Penyebab Utama

1. Backend container menjalankan `php-fpm` tanpa HTTP server, sehingga `localhost:8000` tidak melayani permintaan API.
2. File backend `.env` masih menggunakan `DB_HOST=127.0.0.1` dan password kosong, sementara MySQL berjalan di container service `db`.
3. Laravel menggunakan konfigurasi database yang salah di dalam container, sehingga koneksi MySQL gagal.

## Perbaikan yang Dilakukan

### 1. Ubah `docker-compose.yml`

Di service `backend`, ubah port dan command agar Laravel berjalan sebagai HTTP server.

```yaml
backend:
  build:
    context: ./backend
    dockerfile: Dockerfile
  image: laravel-backend
  container_name: laravel_app
  ports:
    - "8000:8000"
  command: php artisan serve --host=0.0.0.0 --port=8000
  restart: unless-stopped
  tty: true
  environment:
    - APP_NAME=db_schema_tukangdekat
    # ...
```

### 2. Perbaiki konfigurasi database di `backend/.env`

Ganti pengaturan database supaya menggunakan service host `db` dan password sesuai dengan `docker-compose.yml`.

```env
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=db_tukangdekat
DB_USERNAME=root
DB_PASSWORD=rahasia
```

### 3. Hapus cache konfigurasi Laravel

Setelah memperbarui `.env`, jalankan di dalam backend container:

```bash
docker compose exec backend php artisan config:clear
docker compose exec backend php artisan optimize:clear
```

### 4. Restart Docker Compose

Setelah perubahan selesai, restart layanan Docker:

```bash
docker compose up -d --build
```

## Verifikasi

1. Pastikan container backend sudah berjalan dengan port `8000`:
   - `docker compose ps`
2. Pastikan backend dapat diakses dari browser/Flutter:
   - buka `http://127.0.0.1:8000`
3. Pastikan MySQL dapat dihubungi dari backend container:
   - gunakan skrip PHP sederhana atau perintah `php artisan migrate --seed`

## Kredensial Login Default

Gunakan akun customer seed berikut:

- Email: `fajar@example.com`
- Password: `password123`

## Catatan Tambahan

- Jika backend masih tidak merespon, periksa log container:
  - `docker compose logs --tail 50 backend`
- Jika ada error konfigurasi cache, lakukan ulang `php artisan config:clear` dan `php artisan optimize:clear`.

Dokumen ini dapat digunakan sebagai panduan perbaikan login pada kasus serupa di proyek `TukangDekat`.

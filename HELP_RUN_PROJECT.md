# HELP_RUN_PROJECT.md — Tata Cara Aman Menjalankan Proyek (Tim/Reviewer)

Dokumen ini dibuat agar **siapa pun** (anggota tim/dosen/reviewer) bisa menjalankan repository tanpa salah langkah dan tanpa risiko “repository tidak jalan”.

> Fokus: instalasi ulang dari nol setelah clone, konfigurasi environment, serta langkah verifikasi cepat.

---

## 0) Checklist sebelum mulai

1. Pastikan port yang dipakai **tidak bentrok** (Laravel: `8000`, Flutter web: random).
2. Pastikan database MySQL hidup dan user-nya punya akses.
3. Jangan commit file rahasia: `.env`.

---

## 1) Menjalankan Backend (Laravel API)

### Prasyarat
- PHP 8.1+ (disarankan 8.2)
- Composer
- MySQL

### Langkah

1. Masuk ke folder backend

```bash
cd backend
```

2. Buat environment dari template

```bash
cp .env.example .env
```

3. Edit `.env`

Minimal yang wajib biasanya:

- Database:
  - `DB_CONNECTION` (mysql)
  - `DB_HOST`
  - `DB_PORT` (jika ada)
  - `DB_DATABASE`
  - `DB_USERNAME`
  - `DB_PASSWORD`

- App:
  - `APP_ENV=local`
  - `APP_DEBUG=true` (untuk development)
  - `APP_URL=http://127.0.0.1:8000`

- Auth (Sanctum):
  - Pastikan `SESSION_DRIVER` sesuai kebutuhan. Untuk mobile/token biasanya tidak serumit web session.

- Payment provider (disarankan pakai simulasi saat local):
  - `SERVICES_PAYMENTS_DRIVER` / konfigurasi driver pembayaran sesuai file config project (di beberapa project namanya bisa berbeda)
  - Umumnya cukup pakai `simulation` untuk menghindari error secret gateway.

4. Install dependency

```bash
composer install
```

5. Generate key + migrate

```bash
php artisan key:generate
php artisan migrate
```

6. (Opsional) seed test user

Jika project Anda memiliki seeder test user, jalankan:

```bash
php artisan db:seed --seed
```

> Jika tidak ada seeder default, pakai script yang ada di repository (mis. `seed_test_user.php`).

7. Jalankan server

```bash
php artisan serve --host=127.0.0.1 --port=8000
```

### Verifikasi cepat backend

Buka browser / atau gunakan curl:

```bash
curl -s http://127.0.0.1:8000/api/catalog/categories | python -m json.tool
```

Pastikan respons JSON valid dan tidak error 500.

---

## 2) Menjalankan Mobile (Flutter)

### Prasyarat
- Flutter SDK
- Android Studio + emulator **atau** gunakan web chrome

### Langkah

1. Masuk ke folder mobile

```bash
cd mobile
```

2. Ambil dependency

```bash
flutter pub get
```

3. Jalankan (web chrome)

```bash
flutter run -d chrome
```

### Verifikasi cepat mobile

1. Login menggunakan akun test/seed yang tersedia.
2. Cek tab Home (Beranda) — harus bisa memanggil katalog.
3. Cek tab Pesanan — harus bisa membuat order (DP + lifecycle).

---

## 3) Konfigurasi yang sering bikin error (hindari!)

### A) Lupa set `.env`
- Gejala: backend 500, DB error, class/config null.
- Solusi: pastikan `.env` dibuat dari `.env.example` dan DB sudah benar.

### B) Tidak ada queue worker saat fitur async
- Gejala: pembayaran/notification tidak muncul atau status terlambat.
- Solusi:
  - Jalankan worker minimal:

```bash
php artisan queue:work --tries=3
```

### C) Konflik URL API di Flutter
- Gejala: Flutter “gagal terhubung ke backend”.
- Solusi: pastikan base URL di konfigurasi Flutter mengarah ke `http://127.0.0.1:8000`.

---

## 4) Tata cara saat tim push / merge

Agar branch lain aman saat checkout:

1. Commit harus menyertakan perubahan code, bukan file rahasia.
2. Pastikan perubahan `.env` **tidak** masuk repo.
3. Jika menambah migrasi:
   - Jelaskan di PR bahwa migrasi wajib dijalankan (`php artisan migrate`).
4. Jika menambah variabel environment:
   - Tambahkan pada dokumentasi/README (contoh: section “Environment variables”).

---

## 5) Ringkasan perintah “paling aman” (Run from scratch)

**Backend**

```bash
cd backend
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

**Mobile**

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

---

## 6) Penutup

Dokumen ini bertujuan membuat proyek **reproducible** untuk tim. Jika ditemukan langkah yang ternyata berbeda di mesin tertentu, update dokumen ini agar versi berikutnya makin stabil.


<!-- markdownlint-disable -->

# QUICK_START.md — Cara Jalankan Proyek (TukangDekat)

Dokumen ringkas ini menjelaskan langkah paling aman untuk menjalankan **backend Laravel** dan **mobile Flutter** setelah `clone`.

> Target: repo bisa dijalankan oleh tim/reviewer tanpa perlu tahu detail internal.

---

## 0) Persiapan

- Pastikan MySQL berjalan
- Pastikan PHP & Composer sudah terpasang
- Pastikan Flutter SDK sudah terpasang
- Pastikan `.env` dibuat dari `.env.example` (jangan commit `.env`)

---

## 1) Backend (Laravel API)

### Jalankan dari scratch

```bash
cd backend
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

### Verifikasi cepat backend

```bash
curl -s http://127.0.0.1:8000/api/catalog/categories | python -m json.tool
```

---

## 2) Mobile (Flutter)

### Jalankan

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

### Akun pengujian

Gunakan akun test/seed yang disediakan pada dokumentasi project (lihat `docs`/file seed jika ada).

---

## 3) Dokumentasi lengkap

- `HELP_RUN_PROJECT.md` — tata cara aman & checklist saat tim menjalankan/merging
- `backend/RUNBOOK.md` — runbook operasional/produksi
- `backend/DEPLOYMENT.md` — panduan deploy + cron + queue


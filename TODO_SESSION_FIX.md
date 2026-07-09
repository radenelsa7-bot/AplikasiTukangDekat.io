# TODO_SESSION_FIX — Tahap 1: Perbaikan logout otomatis saat refresh

## Latar belakang
Pada backend Laravel ini, Sanctum auth untuk web menggunakan guard `web` (cookie/session). Namun konfigurasi CORS saat ini:
- `supports_credentials = false`
- `allowed_origins` default `*`

Kombinasi ini sering membuat browser tidak mengirim cookie saat request refresh lintas-origin, sehingga user ter-reset/logout.

## Step yang akan dilakukan (bergantung konfirmasi origin frontend)
1. Ubah `backend/config/cors.php`:
   - `supports_credentials` -> `true`
   - `allowed_origins` tidak lagi `*` saat credentials dipakai. Gunakan env `CORS_ALLOWED_ORIGINS` bila ada, fallback ke `http://localhost:8000` + `http://localhost:3000` + `http://localhost:5173`.
2. Pastikan frontend request memanggil `sanctum/csrf-cookie` sebelum request ber-cookie (jika menggunakan sanctum SPA auth).
3. Smoke test:
   - Login session (route `POST /auth/session-login`)
   - Refresh halaman
   - Cek endpoint yang butuh auth (`auth:sanctum` atau `auth`) masih menganggap user aktif.

## Catatan
Saya belum bisa memastikan origin frontend Anda (karena user mengatakan tidak tahu). Jadi konfigurasi akan dibuat toleran: allow beberapa origin umum localhost (8000, 3000, 5173) agar cookie kredensial bisa terkirim.

